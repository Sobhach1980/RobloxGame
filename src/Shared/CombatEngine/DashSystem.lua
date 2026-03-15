--[[
    DashSystem.lua
    4-way directional dash framework shared by all characters.
    Each character uses separate animation assets and tuning
    so dashes feel distinct despite sharing this backend.
--]]

local DashSystem = {}
DashSystem.__index = DashSystem

local DASH_PROFILES = {
    Steve = {
        -- Sturdy combat dash; powerful burst forward
        Speed       = 80,
        Duration    = 0.18,
        Cooldown    = 0.9,
        AnimIds = {
            Forward  = "rbxassetid://STEVE_DASH_FWD",
            Backward = "rbxassetid://STEVE_DASH_BWD",
            Left     = "rbxassetid://STEVE_DASH_LEFT",
            Right    = "rbxassetid://STEVE_DASH_RIGHT",
        },
        VFX = "SteveSmokeBurst",
    },
    Alex = {
        -- Agile; quick burst with slight air hang
        Speed       = 90,
        Duration    = 0.15,
        Cooldown    = 0.75,
        AnimIds = {
            Forward  = "rbxassetid://ALEX_DASH_FWD",
            Backward = "rbxassetid://ALEX_DASH_BWD",
            Left     = "rbxassetid://ALEX_DASH_LEFT",
            Right    = "rbxassetid://ALEX_DASH_RIGHT",
        },
        VFX = "AlexAgileBurst",
    },
    Zombie = {
        -- Heavy burst; short range but high momentum
        Speed       = 70,
        Duration    = 0.22,
        Cooldown    = 1.2,
        AnimIds = {
            Forward  = "rbxassetid://ZOMBIE_DASH_FWD",
            Backward = "rbxassetid://ZOMBIE_DASH_BWD",
            Left     = "rbxassetid://ZOMBIE_DASH_LEFT",
            Right    = "rbxassetid://ZOMBIE_DASH_RIGHT",
        },
        VFX = "ZombieHeavyLunge",
    },
    Enderman = {
        -- Slight teleport-style distortion; repositions precisely
        Speed       = 85,
        Duration    = 0.12,
        Cooldown    = 0.85,
        AnimIds = {
            Forward  = "rbxassetid://ENDERMAN_DASH_FWD",
            Backward = "rbxassetid://ENDERMAN_DASH_BWD",
            Left     = "rbxassetid://ENDERMAN_DASH_LEFT",
            Right    = "rbxassetid://ENDERMAN_DASH_RIGHT",
        },
        VFX = "EndermanVoidBlink",
    },
    Skeleton = {
        -- Evasive backstep focus; optimised for creating range
        Speed       = 75,
        Duration    = 0.16,
        Cooldown    = 0.95,
        AnimIds = {
            Forward  = "rbxassetid://SKELETON_DASH_FWD",
            Backward = "rbxassetid://SKELETON_DASH_BWD",
            Left     = "rbxassetid://SKELETON_DASH_LEFT",
            Right    = "rbxassetid://SKELETON_DASH_RIGHT",
        },
        VFX = "SkeletonSmokeHop",
    },
}

function DashSystem.new(character, characterName, movementSystem)
    local self = setmetatable({}, DashSystem)
    self.Character      = character
    self.Name           = characterName
    self.Profile        = DASH_PROFILES[characterName]
    self.MovementSystem = movementSystem
    self.OnCooldown     = false
    self.IsDashing      = false
    return self
end

-- direction: "Forward" | "Backward" | "Left" | "Right"
function DashSystem:Dash(direction)
    if self.OnCooldown or self.IsDashing then return false end
    local profile  = self.Profile
    local rootPart = self.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    self.IsDashing = true
    self.OnCooldown = true

    -- Determine velocity direction relative to character facing
    local cf  = rootPart.CFrame
    local dir = {
        Forward  =  cf.LookVector,
        Backward = -cf.LookVector,
        Left     = -cf.RightVector,
        Right    =  cf.RightVector,
    }
    local dashVec = dir[direction] or cf.LookVector

    -- Lock movement during dash
    self.MovementSystem:LockMovement(profile.Duration + 0.05)

    -- Apply impulse
    rootPart.AssemblyLinearVelocity = Vector3.new(
        dashVec.X * profile.Speed,
        rootPart.AssemblyLinearVelocity.Y,
        dashVec.Z * profile.Speed
    )

    -- Play character-specific animation
    local animId = profile.AnimIds[direction]
    self:_playAnimation(animId)

    -- Fire VFX event (client-side VFX handler listens for this)
    self:_fireVFX(profile.VFX, direction, rootPart.Position)

    -- End dash state
    task.delay(profile.Duration, function()
        self.IsDashing = false
    end)

    -- Cooldown
    task.delay(profile.Cooldown, function()
        self.OnCooldown = false
    end)

    return true
end

function DashSystem:_playAnimation(animId)
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

function DashSystem:_fireVFX(vfxName, direction, position)
    -- In production this fires a RemoteEvent to the client VFX handler.
    -- Stub preserved for integration.
    -- VFXRemote:FireAllClients(vfxName, direction, position)
end

return DashSystem
