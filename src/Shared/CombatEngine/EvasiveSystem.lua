--[[
    EvasiveSystem.lua
    Universal evasive maneuver (escape move) with high cooldown.
    Character styling handled via per-character profiles:
      Steve    – combat roll / burst step
      Alex     – nimble evasive shift
      Zombie   – lunging stumble escape
      Enderman – blink-like vanish
      Skeleton – smoke/back-hop disengage
--]]

local EvasiveSystem = {}
EvasiveSystem.__index = EvasiveSystem

local EVASIVE_PROFILES = {
    Steve = {
        Cooldown      = 6.0,
        InvincFrames  = 0.30,   -- seconds of i-frames during evasion
        SpeedBoost    = 55,
        Duration      = 0.25,
        AnimId        = "rbxassetid://STEVE_EVASIVE",
        VFX           = "SteveCombatRoll",
        Description   = "Combat Roll — sturdy burst step forward or away",
    },
    Alex = {
        Cooldown      = 5.0,
        InvincFrames  = 0.28,
        SpeedBoost    = 65,
        Duration      = 0.20,
        AnimId        = "rbxassetid://ALEX_EVASIVE",
        VFX           = "AlexNimbleShift",
        Description   = "Nimble Shift — agile side or backward evasive slide",
    },
    Zombie = {
        Cooldown      = 7.5,
        InvincFrames  = 0.22,
        SpeedBoost    = 45,
        Duration      = 0.30,
        AnimId        = "rbxassetid://ZOMBIE_EVASIVE",
        VFX           = "ZombieLungeStumble",
        Description   = "Stumble Escape — heavy lunging burst away from pressure",
    },
    Enderman = {
        Cooldown      = 5.5,
        InvincFrames  = 0.35,
        SpeedBoost    = 70,
        Duration      = 0.15,
        AnimId        = "rbxassetid://ENDERMAN_EVASIVE",
        VFX           = "EndermanBlinkVanish",
        Description   = "Blink Vanish — near-instant teleport reposition",
    },
    Skeleton = {
        Cooldown      = 6.5,
        InvincFrames  = 0.32,
        SpeedBoost    = 58,
        Duration      = 0.22,
        AnimId        = "rbxassetid://SKELETON_EVASIVE",
        VFX           = "SkeletonSmokeDisengage",
        Description   = "Smoke Hop — backward leap to re-establish range",
    },
}

function EvasiveSystem.new(character, characterName, movementSystem)
    local self          = setmetatable({}, EvasiveSystem)
    self.Character      = character
    self.Name           = characterName
    self.Profile        = EVASIVE_PROFILES[characterName]
    self.MovementSystem = movementSystem
    self.OnCooldown     = false
    self.IsInvincible   = false
    return self
end

--[[
    Activate(direction)
    direction: Vector3 – desired escape direction; defaults to
    away from current movement or backward if neutral.
--]]
function EvasiveSystem:Activate(direction)
    if self.OnCooldown then return false end
    local profile  = self.Profile
    local rootPart = self.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    self.OnCooldown   = true
    self.IsInvincible = true

    -- Resolve direction
    local escapeDir = direction
    if not escapeDir or escapeDir.Magnitude < 0.1 then
        -- Default: dodge backward relative to facing
        escapeDir = -rootPart.CFrame.LookVector
    end
    escapeDir = escapeDir.Unit

    -- Apply burst velocity
    rootPart.AssemblyLinearVelocity = Vector3.new(
        escapeDir.X * profile.SpeedBoost,
        rootPart.AssemblyLinearVelocity.Y,
        escapeDir.Z * profile.SpeedBoost
    )

    -- Lock normal movement during evasion
    self.MovementSystem:LockMovement(profile.Duration + 0.05)

    -- Play animation
    self:_playAnimation(profile.AnimId)

    -- Fire VFX
    self:_fireVFX(profile.VFX, rootPart.Position)

    -- End i-frames
    task.delay(profile.InvincFrames, function()
        self.IsInvincible = false
    end)

    -- Cooldown
    task.delay(profile.Cooldown, function()
        self.OnCooldown = false
    end)

    return true
end

-- Query from damage pipeline: should this hit be ignored?
function EvasiveSystem:IsCurrentlyInvincible()
    return self.IsInvincible
end

function EvasiveSystem:GetCooldownRemaining()
    -- In production tie to a timestamp; stub here
    return self.OnCooldown and self.Profile.Cooldown or 0
end

function EvasiveSystem:_playAnimation(animId)
    local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local track = animator:LoadAnimation(anim)
    track:Play()
    anim:Destroy()
end

function EvasiveSystem:_fireVFX(vfxName, position)
    -- VFXRemote:FireAllClients(vfxName, position)
end

return EvasiveSystem
