--[[
    RoundManager.lua
    Tracks per-player stocks (lives) and round wins.
    Determines when a round ends and when the overall match is over.

    Config keys (all optional — defaults shown):
      MaxStocks    : 3    (lives per player per round)
      MaxRounds    : 3    (best-of-N; first to ceil(N/2) round wins takes the match)
      TimeLimitSec : 180  (0 = no timer)

    Events fired on the bus:
      RoundStart(roundNumber)
      RoundEnd(winnerPlayerOrNil)   nil = draw
      MatchEnd(winnerPlayerOrNil)
      StockLost(player, stocksRemaining)
--]]

local RoundManager = {}

local DEFAULT_CONFIG = {
    MaxStocks    = 3,
    MaxRounds    = 3,
    TimeLimitSec = 180,
}

local cfg         = {}
local playerData  = {}   -- [Player] = { stocks=N, roundWins=N }
local roundNumber = 0
local eventBus    = nil

-- ── Init ───────────────────────────────────────────────────────────────────

function RoundManager.Init(bus, config)
    eventBus    = bus
    cfg         = setmetatable(config or {}, { __index = DEFAULT_CONFIG })
    playerData  = {}
    roundNumber = 0
end

-- ── Player registration ────────────────────────────────────────────────────

function RoundManager.RegisterPlayer(player)
    if not playerData[player] then
        playerData[player] = { stocks = cfg.MaxStocks, roundWins = 0 }
    end
end

function RoundManager.UnregisterPlayer(player)
    playerData[player] = nil
end

-- ── Accessors ──────────────────────────────────────────────────────────────

function RoundManager.GetStocks(player)
    return playerData[player] and playerData[player].stocks or 0
end

function RoundManager.GetRoundWins(player)
    return playerData[player] and playerData[player].roundWins or 0
end

function RoundManager.GetRoundNumber()
    return roundNumber
end

function RoundManager.GetConfig()
    return cfg
end

-- ── Death callback ─────────────────────────────────────────────────────────

-- Called by DeathHandler each time a player is eliminated this round.
function RoundManager.OnPlayerDied(player)
    local data = playerData[player]
    if not data then return end

    data.stocks = math.max(0, data.stocks - 1)

    if eventBus then
        eventBus.Fire("StockLost", player, data.stocks)
    end

    if data.stocks <= 0 then
        RoundManager._CheckRoundEnd()
    end
end

-- ── Internal ───────────────────────────────────────────────────────────────

function RoundManager._CheckRoundEnd()
    local alive = {}
    for p, data in pairs(playerData) do
        if data.stocks > 0 then
            table.insert(alive, p)
        end
    end

    local winsNeeded = math.ceil(cfg.MaxRounds / 2)

    if #alive == 1 then
        local winner = alive[1]
        playerData[winner].roundWins = playerData[winner].roundWins + 1
        roundNumber = roundNumber + 1

        if eventBus then
            eventBus.Fire("RoundEnd", winner)
        end

        if playerData[winner].roundWins >= winsNeeded then
            if eventBus then
                eventBus.Fire("MatchEnd", winner)
            end
        end

    elseif #alive == 0 then
        -- Double KO
        roundNumber = roundNumber + 1
        if eventBus then
            eventBus.Fire("RoundEnd", nil)
            eventBus.Fire("MatchEnd", nil)
        end
    end
    -- If #alive > 1, round is still going (shouldn't normally reach here mid-round)
end

-- ── Round management ───────────────────────────────────────────────────────

-- Reset stocks for a fresh round. Round wins are preserved.
function RoundManager.StartNewRound()
    for _, data in pairs(playerData) do
        data.stocks = cfg.MaxStocks
    end
    if eventBus then
        eventBus.Fire("RoundStart", roundNumber + 1)
    end
end

-- Returns the overall match winner (Player) if decided, else nil.
function RoundManager.GetMatchWinner()
    local winsNeeded = math.ceil(cfg.MaxRounds / 2)
    for p, data in pairs(playerData) do
        if data.roundWins >= winsNeeded then
            return p
        end
    end
    return nil
end

-- Full reset for a rematch — clears both stocks and round wins.
function RoundManager.Reset()
    for _, data in pairs(playerData) do
        data.stocks    = cfg.MaxStocks
        data.roundWins = 0
    end
    roundNumber = 0
end

return RoundManager
