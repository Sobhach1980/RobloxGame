--[[
    GameClient.lua  —  Client entry point
    Runs in StarterPlayerScripts.

    Responsibilities:
      1. Wait for GameRemotes folder created by GameServer
      2. Initialise VFXHandler with the VFX remote
      3. Initialise CinematicHandler with cinematic + camera remotes
      4. Initialise HUDController
      5. Send character selection input to server
      6. Forward local player input (keyboard/gamepad) to server via InputRemote
--]]

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFXHandler           = require(script.Parent.VFXHandler)
local CinematicHandler     = require(script.Parent.CinematicHandler)
local HUDController        = require(game.ReplicatedStorage.Shared.HUD.HUDController)
local SoundManager         = require(game.ReplicatedStorage.Shared.Sound.SoundManager)
local CharacterSelectUI    = require(script.Parent.CharacterSelectUI)
local MatchUI              = require(script.Parent.MatchUI)
local ResultsUI            = require(script.Parent.ResultsUI)

local localPlayer = Players.LocalPlayer

-- ── Wait for server to create remotes ─────────────────────────────────────

local remotesFolder  = ReplicatedStorage:WaitForChild("GameRemotes", 30)
if not remotesFolder then
    error("GameClient: GameRemotes folder not found — ensure GameServer is running.")
end

local function getRemote(name)
    return remotesFolder:WaitForChild(name, 10)
end

local Remotes = {
    VFXRemote       = getRemote("VFXRemote"),
    UltCinematic    = getRemote("UltCinematic"),
    UltRevert       = getRemote("UltRevert"),
    CameraShake     = getRemote("CameraShake"),
    HitStop         = getRemote("HitStop"),
    SlowMo          = getRemote("SlowMo"),
    HUDRemote       = getRemote("HUDRemote"),
    InputRemote     = getRemote("InputRemote"),
    SelectCharacter = getRemote("SelectCharacter"),
    MatchUIRemote   = getRemote("MatchUIRemote"),
    SoundRemote     = getRemote("SoundRemote"),
}

-- ── Initialise client systems ──────────────────────────────────────────────

VFXHandler.Init(Remotes.VFXRemote)

CinematicHandler.Init(
    Remotes.UltCinematic,
    Remotes.UltRevert,
    Remotes.CameraShake,
    Remotes.HitStop,
    Remotes.SlowMo
)

local hud = HUDController.new(localPlayer)

SoundManager.Init(Remotes.SoundRemote)
CharacterSelectUI.Init(Remotes.SelectCharacter)

-- HUD events from server
Remotes.HUDRemote.OnClientEvent:Connect(function(event, ...)
    if event == "CharacterSet" then
        -- hud:SetCharacter(...) -- future: swap ability icons for the character
    elseif event == "UpdateHealth" then
        hud:UpdateHealth(...)
    elseif event == "UpdateUltGauge" then
        hud:UpdateUltGauge(...)
    elseif event == "StartCooldown" then
        hud:StartCooldown(...)
    elseif event == "UltActivated" then
        hud:OnUltActivated(...)
    elseif event == "UltTick" then
        hud:OnUltTick(...)
    elseif event == "UltReverted" then
        hud:OnUltReverted(...)
    end
end)

-- Match UI events from MatchServer
Remotes.MatchUIRemote.OnClientEvent:Connect(function(event, ...)
    if event == "ShowCharSelect" then
        MatchUI.Hide()
        ResultsUI.Hide()
        CharacterSelectUI.Show()

    elseif event == "RoundBanner" then
        CharacterSelectUI.Hide()
        MatchUI.Show()
        MatchUI.ShowRoundBanner(...)

    elseif event == "Countdown" then
        MatchUI.ShowCountdown(...)

    elseif event == "Fight" then
        MatchUI.ShowFight()

    elseif event == "SetTimer" then
        MatchUI.SetTimer(...)

    elseif event == "TimerExpired" then
        MatchUI.ShowTimerExpired()

    elseif event == "UpdateStocks" then
        MatchUI.UpdateStocks(...)

    elseif event == "KO" then
        MatchUI.ShowKO(...)

    elseif event == "RoundWin" then
        MatchUI.ShowRoundWin(...)

    elseif event == "RoundDraw" then
        MatchUI.ShowRoundDraw()

    elseif event == "MatchEnd" then
        MatchUI.Hide()
        ResultsUI.Show(...)

    elseif event == "RematchTick" then
        local secondsLeft = select(1, ...)
        ResultsUI.UpdateRematch(secondsLeft)
    end
end)

-- ── Input forwarding ───────────────────────────────────────────────────────

-- Key bindings
local KEY_BINDINGS = {
    [Enum.KeyCode.Q]          = { "Ability", "Q" },
    [Enum.KeyCode.E]          = { "Ability", "E" },
    [Enum.KeyCode.R]          = { "Ability", "R" },
    [Enum.KeyCode.F]          = { "Ability", "F" },
    [Enum.KeyCode.G]          = { "Ultimate" },
    [Enum.KeyCode.LeftShift]  = { "Evasive" },    -- direction forwarded separately
    [Enum.KeyCode.F]          = { "Ability", "F" },
}

-- Dash: double-tap WASD — tracked with timestamps
local lastKeyTap = {}
local DOUBLE_TAP_WINDOW = 0.3   -- seconds

local WASD_DIRS = {
    [Enum.KeyCode.W] = Vector3.new(0, 0, -1),
    [Enum.KeyCode.S] = Vector3.new(0, 0,  1),
    [Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
    [Enum.KeyCode.D] = Vector3.new( 1, 0, 0),
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- WASD double-tap → Dash
    if WASD_DIRS[input.KeyCode] then
        local now = tick()
        local key = input.KeyCode
        if lastKeyTap[key] and (now - lastKeyTap[key]) < DOUBLE_TAP_WINDOW then
            -- Convert local direction to world direction via camera CFrame
            local cam = workspace.CurrentCamera
            local flat = cam.CFrame.LookVector * Vector3.new(1, 0, 1)
            local forward = flat.Unit
            local right   = cam.CFrame.RightVector * Vector3.new(1, 0, 1)
            right = right.Unit

            local localDir = WASD_DIRS[key]
            local worldDir = (forward * -localDir.Z + right * localDir.X)

            Remotes.InputRemote:FireServer("Dash", worldDir)
            lastKeyTap[key] = nil  -- consume
        else
            lastKeyTap[key] = now
        end
        return
    end

    local binding = KEY_BINDINGS[input.KeyCode]
    if binding then
        Remotes.InputRemote:FireServer(table.unpack(binding))
    end
end)

-- M1: mouse click
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Remotes.InputRemote:FireServer("M1")
    end
end)

-- Block: right mouse button
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Remotes.InputRemote:FireServer("BlockDown")
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Remotes.InputRemote:FireServer("BlockUp")
    end
end)
