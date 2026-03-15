--[[
    SoundManager.lua
    Client-side sound player. Receives play requests via a RemoteEvent
    fired from MatchServer, or called directly from client code.

    Server fires:
      SoundRemote:FireClient(player, key)             -- 2-D / UI sound
      SoundRemote:FireClient(player, key, position)   -- positional 3-D sound
      SoundRemote:FireAllClients(key [, position])

    Client usage (direct):
      SoundManager.Init(soundRemote)
      SoundManager.Play("Combat_M1Hit", hitPosition)
      SoundManager.Play("UI_Fight")

    Sounds with ID == 0 are skipped (placeholder not yet uploaded).
--]]

local Debris    = game:GetService("Debris")

local SoundManager = {}

local SoundIds    = require(game.ReplicatedStorage.Shared.Sound.SoundIds)
local soundFolder = nil

-- ── Internal ───────────────────────────────────────────────────────────────

local function getSoundFolder()
    if soundFolder and soundFolder.Parent then return soundFolder end
    soundFolder = workspace:FindFirstChild("_Sounds")
    if not soundFolder then
        soundFolder        = Instance.new("Folder")
        soundFolder.Name   = "_Sounds"
        soundFolder.Parent = workspace
    end
    return soundFolder
end

local function playSound(key, position)
    local id = SoundIds[key]
    if not id or id == 0 then return end   -- placeholder; skip silently

    local assetUrl = "rbxassetid://" .. tostring(id)

    if position then
        -- 3-D positional: attach Sound to an invisible anchored Part
        local part             = Instance.new("Part")
        part.Anchored          = true
        part.CanCollide        = false
        part.Transparency      = 1
        part.Size              = Vector3.new(1, 1, 1)
        part.Position          = position
        part.Parent            = getSoundFolder()

        local snd                   = Instance.new("Sound")
        snd.SoundId                 = assetUrl
        snd.RollOffMode             = Enum.RollOffMode.InverseTapered
        snd.RollOffMaxDistance      = 80
        snd.Parent                  = part
        snd:Play()

        Debris:AddItem(part, snd.TimeLength + 0.5)
    else
        -- 2-D / UI sound: parented directly to folder (no spatial falloff)
        local snd        = Instance.new("Sound")
        snd.SoundId      = assetUrl
        snd.Parent       = getSoundFolder()
        snd:Play()

        Debris:AddItem(snd, snd.TimeLength + 0.5)
    end
end

-- ── Public ─────────────────────────────────────────────────────────────────

-- Call once from GameClient after the remotes folder is ready.
function SoundManager.Init(remote)
    remote.OnClientEvent:Connect(function(key, position)
        playSound(key, position)
    end)
end

-- Play a sound directly from client code (no remote needed).
function SoundManager.Play(key, position)
    playSound(key, position)
end

return SoundManager
