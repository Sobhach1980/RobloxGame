--[[
    MatchServer.lua
    Top-level match orchestrator. Required by GameServer once at startup.

    Wires together every match-system module:
      MatchEventBus  → shared event pipeline
      MatchStateMachine → game-flow states
      RoundManager   → stocks, round wins, match winner
      DeathHandler   → Humanoid.Died + blast-zone kills
      RespawnManager → delayed reload + teleport
      MatchTimer     → per-round countdown
      ArenaManager   → spawn points + blast-zone check loop

    Fires the following RemoteEvents to clients:
      MatchUIRemote  — MatchUI / ResultsUI / CharacterSelectUI events
      SoundRemote    — SFX triggers

    Match configuration lives in MATCH_CONFIG below.

    Public API (called by GameServer):
      MatchServer.Init(remotes)
      MatchServer.AddPlayer(player)
      MatchServer.RemovePlayer(player)
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchEventBus     = require(ReplicatedStorage.Shared.MatchSystem.MatchEventBus)
local MatchStateMachine = require(ReplicatedStorage.Shared.MatchSystem.MatchStateMachine)
local RoundManager      = require(ReplicatedStorage.Shared.MatchSystem.RoundManager)
local DeathHandler      = require(ReplicatedStorage.Shared.MatchSystem.DeathHandler)
local RespawnManager    = require(ReplicatedStorage.Shared.MatchSystem.RespawnManager)
local MatchTimer        = require(ReplicatedStorage.Shared.MatchSystem.MatchTimer)
local ArenaManager      = require(ReplicatedStorage.Shared.Arena.ArenaManager)

local MatchServer = {}

-- ── Match configuration ────────────────────────────────────────────────────

local MATCH_CONFIG = {
    MaxStocks    = 3,
    MaxRounds    = 3,
    TimeLimitSec = 180,
    CountdownSec = 3,
    CharSelectSec = 15,  -- auto-start if players haven't confirmed
    RematchSec   = 10,
    MinPlayers   = 2,
}

-- ── State ──────────────────────────────────────────────────────────────────

local Remotes       = nil
local matchPlayers  = {}    -- ordered list of Players currently in the match

-- ── Remote helpers ─────────────────────────────────────────────────────────

local function fireMatchUI(player, event, ...)
    if Remotes then
        Remotes.MatchUIRemote:FireClient(player, event, ...)
    end
end

local function fireAllMatchUI(event, ...)
    for _, p in ipairs(matchPlayers) do
        fireMatchUI(p, event, ...)
    end
end

local function fireSound(player, key, position)
    if Remotes then
        Remotes.SoundRemote:FireClient(player, key, position)
    end
end

local function fireAllSound(key, position)
    for _, p in ipairs(matchPlayers) do
        fireSound(p, key, position)
    end
end

-- ── Stock snapshot (for UpdateStocks event) ────────────────────────────────

local function buildStockTable()
    local t = {}
    for _, p in ipairs(matchPlayers) do
        t[p.Name] = RoundManager.GetStocks(p)
    end
    return t
end

-- ── Round / match flow ─────────────────────────────────────────────────────

local function runCountdown(seconds, onDone)
    for i = seconds, 1, -1 do
        fireAllMatchUI("Countdown", i)
        fireAllSound("UI_Countdown")
        task.wait(1)
    end
    onDone()
end

local function startRound()
    local roundNum = RoundManager.GetRoundNumber() + 1
    RoundManager.StartNewRound()
    ArenaManager.RotateSpawns()

    -- Round banner + bell
    fireAllMatchUI("RoundBanner", roundNum)
    fireAllSound("Arena_RoundBell")
    task.wait(2)

    -- 3-2-1 countdown
    MatchStateMachine.Transition("Countdown")
    runCountdown(MATCH_CONFIG.CountdownSec, function()
        if not MatchStateMachine.Transition("Fighting") then return end

        fireAllMatchUI("Fight")
        fireAllSound("UI_Fight")

        -- Broadcast initial stock state
        fireAllMatchUI("UpdateStocks", buildStockTable(), MATCH_CONFIG.MaxStocks)

        -- Start round timer
        MatchTimer.Start(MATCH_CONFIG.TimeLimitSec)

        -- Begin watching deaths
        for _, p in ipairs(matchPlayers) do
            DeathHandler.WatchPlayer(p)
        end
    end)
end

local function endMatch(winner)
    MatchStateMachine.Transition("MatchEnd")
    MatchTimer.Stop()

    for _, p in ipairs(matchPlayers) do
        DeathHandler.UnwatchPlayer(p)
    end

    -- Send results to each client from their own perspective
    for _, p in ipairs(matchPlayers) do
        local isWin  = (winner == p)
        local isDraw = (winner == nil)
        local myWins = RoundManager.GetRoundWins(p)

        local opp, oppWins = nil, 0
        for _, op in ipairs(matchPlayers) do
            if op ~= p then opp = op; break end
        end
        if opp then oppWins = RoundManager.GetRoundWins(opp) end

        local oppName = opp and opp.Name or "Opponent"

        fireMatchUI(p, "MatchEnd", isWin, isDraw, oppName, myWins, oppWins, MATCH_CONFIG.RematchSec)

        if isWin then
            fireSound(p, "UI_Victory")
        elseif isDraw then
            fireSound(p, "UI_Draw")
        else
            fireSound(p, "UI_Defeat")
        end
    end

    -- Rematch countdown then restart
    local rematchRemaining = MATCH_CONFIG.RematchSec
    task.spawn(function()
        while rematchRemaining > 0 do
            task.wait(1)
            rematchRemaining = rematchRemaining - 1
            fireAllMatchUI("RematchTick", rematchRemaining)
        end

        RoundManager.Reset()
        MatchStateMachine.Transition("Rematch")
        task.wait(0.5)
        MatchStateMachine.Transition("CharSelect")
        fireAllMatchUI("ShowCharSelect")
    end)
end

-- ── Event bus wiring ───────────────────────────────────────────────────────

local function wireEventBus()
    -- RoundEnd: pause → new round or match over
    MatchEventBus.On("RoundEnd", function(winner)
        if not MatchStateMachine.Transition("RoundEnd") then return end
        MatchTimer.Stop()

        if winner then
            fireAllMatchUI("RoundWin", winner.Name)
            fireAllSound("UI_RoundEnd")
        else
            fireAllMatchUI("RoundDraw")
            fireAllSound("UI_Draw")
        end

        task.wait(2.5)

        local matchWinner = RoundManager.GetMatchWinner()
        if matchWinner ~= nil or winner == nil then
            -- Either a clear match winner, or a draw that ended the rounds
            endMatch(matchWinner)
        else
            startRound()
        end
    end)

    -- Stock lost: refresh HUD for all clients
    MatchEventBus.On("StockLost", function(player, _remaining)
        fireAllMatchUI("UpdateStocks", buildStockTable(), MATCH_CONFIG.MaxStocks)
    end)

    -- Player died: KO announcement
    MatchEventBus.On("PlayerDied", function(player, _char)
        fireAllMatchUI("KO", player.Name)
        fireAllSound("UI_RoundEnd")
    end)

    -- Timer expired: stock-based tiebreak
    MatchEventBus.On("TimerExpired", function()
        fireAllMatchUI("TimerExpired")

        local best, winners = -1, {}
        for _, p in ipairs(matchPlayers) do
            local s = RoundManager.GetStocks(p)
            if s > best then
                best    = s
                winners = { p }
            elseif s == best then
                table.insert(winners, p)
            end
        end

        local roundWinner = (#winners == 1) and winners[1] or nil
        MatchEventBus.Fire("RoundEnd", roundWinner)
    end)

    -- Timer tick: forward remaining seconds to clients
    MatchEventBus.On("TimerTick", function(remaining)
        fireAllMatchUI("SetTimer", remaining)
    end)

    -- Player respawned: re-watch for death if round still active
    MatchEventBus.On("PlayerRespawned", function(player)
        if MatchStateMachine.Is("Fighting") then
            DeathHandler.WatchPlayer(player)
            -- Refresh stock display
            fireAllMatchUI("UpdateStocks", buildStockTable(), MATCH_CONFIG.MaxStocks)
        end
    end)
end

-- ── Match start logic ──────────────────────────────────────────────────────

local function tryStartMatch()
    if #Players:GetPlayers() < MATCH_CONFIG.MinPlayers then return end
    if not (MatchStateMachine.Is("Lobby") or MatchStateMachine.Is("CharSelect")) then return end

    -- Register all current players
    for _, p in ipairs(Players:GetPlayers()) do
        MatchServer.AddPlayer(p)
    end

    -- Show character select
    MatchStateMachine.Transition("CharSelect")
    fireAllMatchUI("ShowCharSelect")

    -- Auto-start after CharSelectSec if players haven't all confirmed
    task.delay(MATCH_CONFIG.CharSelectSec, function()
        if MatchStateMachine.Is("CharSelect") then
            startRound()
        end
    end)
end

-- ── Public API ─────────────────────────────────────────────────────────────

function MatchServer.Init(remotes)
    Remotes = remotes

    MatchStateMachine.Init(MatchEventBus)
    RoundManager.Init(MatchEventBus, MATCH_CONFIG)
    MatchTimer.Init(MatchEventBus)
    ArenaManager.Init(DeathHandler)
    ArenaManager.StartBlastZoneCheck()
    RespawnManager.Init(MatchStateMachine, RoundManager, ArenaManager, MatchEventBus)
    DeathHandler.Init(RoundManager, RespawnManager, nil, MatchEventBus)

    wireEventBus()

    -- Auto-start when enough players join
    Players.PlayerAdded:Connect(function(_player)
        task.wait(1)   -- brief delay so CharacterAdded fires first
        tryStartMatch()
    end)

    -- Handle players already in the server when this runs (Studio Play mode)
    task.defer(tryStartMatch)
end

function MatchServer.AddPlayer(player)
    for _, p in ipairs(matchPlayers) do
        if p == player then return end   -- already registered
    end
    table.insert(matchPlayers, player)
    RoundManager.RegisterPlayer(player)
    ArenaManager.RegisterPlayer(player)
end

function MatchServer.RemovePlayer(player)
    DeathHandler.UnwatchPlayer(player)
    RoundManager.UnregisterPlayer(player)
    ArenaManager.UnregisterPlayer(player)
    for i, p in ipairs(matchPlayers) do
        if p == player then
            table.remove(matchPlayers, i)
            break
        end
    end
end

return MatchServer
