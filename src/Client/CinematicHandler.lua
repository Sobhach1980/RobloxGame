--[[
    CinematicHandler.lua  —  Steps 12 & 14 (Client)
    Receives UltCinematic and UltRevert events from the server and
    runs the per-character cutscene sequence locally.

    For the activating player:  full camera + screen text + sound
    For spectators:             orbit camera around the activating character
--]]

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local SoundService  = game:GetService("SoundService")

local CinematicCamera = require(game.ReplicatedStorage.Shared.Cinematic.CinematicCamera)

local localPlayer = Players.LocalPlayer
local camera      = CinematicCamera.new()

-- Screen overlay frame (created once, reused)
local screenGui   = Instance.new("ScreenGui")
screenGui.Name    = "CinematicOverlay"
screenGui.ResetOnSpawn = false
screenGui.Parent  = localPlayer.PlayerGui

-- Dark letterbox bars
local topBar = Instance.new("Frame", screenGui)
topBar.BackgroundColor3 = Color3.fromRGB(0,0,0)
topBar.Size   = UDim2.new(1, 0, 0.08, 0)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BorderSizePixel = 0
topBar.Visible = false

local botBar = Instance.new("Frame", screenGui)
botBar.BackgroundColor3 = Color3.fromRGB(0,0,0)
botBar.Size   = UDim2.new(1, 0, 0.08, 0)
botBar.Position = UDim2.new(0, 0, 0.92, 0)
botBar.BorderSizePixel = 0
botBar.Visible = false

-- Character name banner
local nameBanner = Instance.new("TextLabel", screenGui)
nameBanner.BackgroundTransparency = 1
nameBanner.Size     = UDim2.new(1, 0, 0.1, 0)
nameBanner.Position = UDim2.new(0, 0, 0.45, 0)
nameBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBanner.TextScaled = true
nameBanner.Font     = Enum.Font.GothamBold
nameBanner.Text     = ""
nameBanner.TextTransparency = 1
nameBanner.Visible  = false

local CinematicHandler = {}

-- ─── Internal helpers ─────────────────────────────────────────────────────

local function showLetterbox(duration)
    topBar.Visible = true
    botBar.Visible = true
    local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(topBar, info, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(botBar, info, { BackgroundTransparency = 0 }):Play()

    task.delay(duration - 0.3, function()
        local outInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(topBar, outInfo, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(botBar, outInfo, { BackgroundTransparency = 1 }):Play()
        task.delay(0.35, function()
            topBar.Visible = false
            botBar.Visible = false
        end)
    end)
end

local function showNameBanner(text, color, duration)
    nameBanner.Text        = text
    nameBanner.TextColor3  = color
    nameBanner.TextTransparency = 1
    nameBanner.Visible     = true

    local inInfo  = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local outInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    TweenService:Create(nameBanner, inInfo, { TextTransparency = 0 }):Play()

    task.delay(duration - 0.5, function()
        TweenService:Create(nameBanner, outInfo, { TextTransparency = 1 }):Play()
        task.delay(0.45, function()
            nameBanner.Visible = false
        end)
    end)
end

local function playSound(soundId, parent)
    if not soundId or soundId == "" then return end
    local sound = Instance.new("Sound")
    sound.SoundId    = soundId
    sound.RollOffMaxDistance = 150
    sound.Volume     = 1.0
    sound.Parent     = parent or SoundService
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 10)
end

-- ─── Main ult cinematic sequence ──────────────────────────────────────────

function CinematicHandler.OnUltCinematic(data)
    local characterId  = data.CharacterId
    local charPos      = data.CharacterPos
    local camType      = data.CameraType
    local camConfig    = data.CameraConfig or {}
    local screenText   = data.ScreenText   or ""
    local textColor    = data.TextColor    or Color3.fromRGB(255,255,255)
    local soundId      = data.SoundId      or ""
    local duration     = camConfig.duration or 2.5

    -- Letterbox
    showLetterbox(duration)

    -- Name banner (slight delay so camera settles first)
    task.delay(0.4, function()
        showNameBanner(screenText, textColor, duration - 0.4)
    end)

    -- Sound
    local char = CinematicHandler._findCharacter(characterId)
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    playSound(soundId, rootPart)

    -- Camera: build config with runtime subject
    camConfig.subject   = rootPart
    camConfig.centerPos = charPos

    -- Dolly: set start/end CFrame around character
    if camType == "dolly" and rootPart then
        local behind = rootPart.CFrame * CFrame.new(0, 4, 16)
        local target = rootPart.CFrame * CFrame.new(0, 2, 6)
        camConfig.startCF = behind
        camConfig.endCF   = target
    end

    camera:Play(camType, camConfig)

    -- Restore camera after duration
    task.delay(duration, function()
        camera:Play("restore", { duration = 0.4 })
    end)

    -- FOV pulse at peak of animation
    task.delay(duration * 0.6, function()
        camera:PulseFOV(80, 0.3)
    end)
end

function CinematicHandler.OnUltRevert(data)
    -- Nothing visual needed here — VFXHandler handles aura removal
    -- Camera is already restored by the timer set in OnUltCinematic
end

-- ─── Hit-stop (brief time-scale freeze feel via camera shake) ─────────────
function CinematicHandler.OnHitStop(duration, shakeAmount)
    camera:Play("shake", { amount = shakeAmount or 1.5 })
end

-- ─── Slow-motion flash (Bonebreaker) ─────────────────────────────────────
function CinematicHandler.OnSlowMo(duration)
    camera:PulseFOV(80, duration or 0.08)
    camera:Play("shake", { amount = 2.5 })
end

-- ─── Camera shake (exposed for abilities) ────────────────────────────────
function CinematicHandler.Shake(amount)
    camera:Play("shake", { amount = amount })
end

-- ─── Helper: find character model by character ID ─────────────────────────
function CinematicHandler._findCharacter(characterId)
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char and char:GetAttribute("CharacterId") == characterId then
            return char
        end
    end
    return nil
end

-- ─── Bind to RemoteEvents ────────────────────────────────────────────────

function CinematicHandler.Init(ultCinematicRemote, ultRevertRemote, cameraShakeRemote,
                                hitStopRemote, slowMoRemote)
    ultCinematicRemote.OnClientEvent:Connect(function(data)
        CinematicHandler.OnUltCinematic(data)
    end)

    if ultRevertRemote then
        ultRevertRemote.OnClientEvent:Connect(function(data)
            CinematicHandler.OnUltRevert(data)
        end)
    end

    if cameraShakeRemote then
        cameraShakeRemote.OnClientEvent:Connect(function(strength, position, radius)
            local amounts = { light = 0.8, medium = 1.5, strong = 2.5,
                              cinematic = 4.0, rhythmic = 0.5 }
            local amount = (type(strength) == "number") and strength
                        or (amounts[strength] or 1.0)

            -- Distance falloff
            local char = localPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and position and radius then
                local dist = (root.Position - position).Magnitude
                if dist > radius then return end
                amount = amount * (1 - dist / radius)
            end

            camera:Play("shake", { amount = amount })
        end)
    end

    if hitStopRemote then
        hitStopRemote.OnClientEvent:Connect(function(duration)
            CinematicHandler.OnHitStop(duration)
        end)
    end

    if slowMoRemote then
        slowMoRemote.OnClientEvent:Connect(function(duration)
            CinematicHandler.OnSlowMo(duration)
        end)
    end
end

return CinematicHandler
