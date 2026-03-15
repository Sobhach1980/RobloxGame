--[[
    UltActivatorSequence.lua  —  Step 12
    Per-character ult activation cinematic sequences.
    Called by character controllers when the ult button is pressed
    and the gauge is full.

    Each sequence:
      1. Validates meter (done in controller before calling here)
      2. Locks player input for the duration
      3. Fires client-side cinematic (camera + VFX) via RemoteEvent
      4. Applies form visuals (aura/model changes)
      5. Swaps moveset icons on HUD (via RemoteEvent)
      6. Starts the ult timer
      7. Calls onComplete so the controller enables ult abilities

    Architecture:
      Server calls UltActivatorSequence.Activate(player, character, id, controllers)
      → fires UltCinematicRemote to all clients
      Client CinematicHandler picks it up and runs the visual sequence
      Server waits for LOCK_DURATION then calls onComplete
--]]

-- Shared module — runs on server. Imports RemoteEvents set up by GameServer.
local UltActivatorSequence = {}

-- Per-character cinematic configurations
local SEQUENCES = {
    Steve = {
        LockDuration   = 2.5,      -- seconds input is blocked
        CameraType     = "orbit",
        CameraConfig   = { radius = 10, height = 3, speed = 0.4, duration = 2.5 },
        AuraColor      = Color3.fromRGB(200, 200, 255),   -- cool blue-white
        AuraParticle   = "SteveUltAura",
        EyeGlow        = Color3.fromRGB(255, 255, 255),
        ScreenText     = "LAST BLOCK STANDING",
        TextColor      = Color3.fromRGB(200, 220, 255),
        SoundId        = "rbxassetid://STEVE_ULT_ACTIVATE_SFX",
        AnimKey        = "UltActivate",
    },
    Alex = {
        LockDuration   = 3.0,
        CameraType     = "orbit",
        CameraConfig   = { radius = 14, height = 5, speed = 0.5, duration = 3.0 },
        AuraColor      = Color3.fromRGB(140, 60, 220),    -- purple dragon energy
        AuraParticle   = "AlexUltAura",
        EyeGlow        = Color3.fromRGB(180, 80, 255),
        ScreenText     = "DRAGON'S AWAKENING",
        TextColor      = Color3.fromRGB(180, 100, 255),
        SoundId        = "rbxassetid://ALEX_ULT_ACTIVATE_SFX",
        AnimKey        = "UltActivate",
        ExtraEffect    = "DragonSilhouette",   -- client spawns dragon shadow overlay
    },
    Zombie = {
        LockDuration   = 2.0,
        CameraType     = "pan",
        CameraConfig   = { radius = 10, height = 2, startAngle = -0.3, endAngle = 0.3, duration = 2.0 },
        AuraColor      = Color3.fromRGB(50, 200, 50),     -- infection green
        AuraParticle   = "ZombieUltAura",
        EyeGlow        = Color3.fromRGB(0, 255, 80),
        ScreenText     = "RELENTLESS HUNGER",
        TextColor      = Color3.fromRGB(80, 255, 80),
        SoundId        = "rbxassetid://ZOMBIE_ULT_ACTIVATE_SFX",
        AnimKey        = "UltActivate",
    },
    Enderman = {
        LockDuration   = 2.5,
        CameraType     = "orbit",
        CameraConfig   = { radius = 12, height = 6, speed = -0.5, duration = 2.5 },  -- reverse orbit
        AuraColor      = Color3.fromRGB(80, 0, 160),      -- deep void purple
        AuraParticle   = "EndermanUltAura",
        EyeGlow        = Color3.fromRGB(160, 0, 255),
        ScreenText     = "VOID DOMINION",
        TextColor      = Color3.fromRGB(120, 0, 220),
        SoundId        = "rbxassetid://ENDERMAN_ULT_ACTIVATE_SFX",
        AnimKey        = "UltActivate",
        ExtraEffect    = "VoidStaticOverlay",
    },
    Skeleton = {
        LockDuration   = 2.0,
        CameraType     = "dolly",
        CameraConfig   = { duration = 2.0, easingStyle = "Quad" },  -- startCF/endCF set at runtime
        AuraColor      = Color3.fromRGB(140, 220, 255),   -- icy blue
        AuraParticle   = "SkeletonUltAura",
        EyeGlow        = Color3.fromRGB(100, 200, 255),
        ScreenText     = "PERFECT AIM",
        TextColor      = Color3.fromRGB(120, 200, 255),
        SoundId        = "rbxassetid://SKELETON_ULT_ACTIVATE_SFX",
        AnimKey        = "UltActivate",
    },
}

--[[
    Activate(params)
    params = {
        character     : Model
        characterId   : string   ("Steve"|"Alex"|...)
        animManager   : AnimationManager instance
        remotes       : table of RemoteEvent instances from GameServer
        movementSystem: MovementSystem instance
        onComplete    : function  -- called after lock window ends
    }
--]]
function UltActivatorSequence.Activate(params)
    local characterId   = params.characterId
    local seq           = SEQUENCES[characterId]
    if not seq then
        warn("UltActivatorSequence: Unknown character " .. tostring(characterId))
        if params.onComplete then params.onComplete() end
        return
    end

    local character     = params.character
    local animManager   = params.animManager
    local remotes       = params.remotes
    local movSys        = params.movementSystem

    -- 1. Lock input
    if movSys then movSys:LockMovement(seq.LockDuration) end

    -- 2. Play character activation animation
    if animManager then
        animManager:Play(seq.AnimKey, { priority = "action4" })
    end

    -- 3. Fire cinematic event to ALL clients
    --    Clients run camera sequence + apply VFX + show screen text
    if remotes and remotes.UltCinematic then
        remotes.UltCinematic:FireAllClients({
            CharacterId  = characterId,
            CharacterPos = character:FindFirstChild("HumanoidRootPart") and
                           character.HumanoidRootPart.Position or Vector3.new(0,0,0),
            CameraType   = seq.CameraType,
            CameraConfig = seq.CameraConfig,
            AuraColor    = seq.AuraColor,
            AuraParticle = seq.AuraParticle,
            EyeGlow      = seq.EyeGlow,
            ScreenText   = seq.ScreenText,
            TextColor    = seq.TextColor,
            SoundId      = seq.SoundId,
            ExtraEffect  = seq.ExtraEffect,
        })
    end

    -- 4. Apply server-side form attribute so damage pipeline knows form is active
    character:SetAttribute("UltFormActive", true)
    character:SetAttribute("UltFormId", characterId)

    -- 5. After lock window, trigger moveset swap + ult timer
    task.delay(seq.LockDuration, function()
        if params.onComplete then
            params.onComplete()
        end
    end)
end

-- Called by controller on ult expiry to signal clients to remove form visuals
function UltActivatorSequence.Revert(params)
    local remotes     = params.remotes
    local character   = params.character
    local characterId = params.characterId

    character:SetAttribute("UltFormActive", false)
    character:SetAttribute("UltFormId", "")

    if remotes and remotes.UltRevert then
        remotes.UltRevert:FireAllClients({
            CharacterId = characterId,
            Character   = character,
        })
    end
end

return UltActivatorSequence
