--[[
    HitStunKnockback.lua
    Full reaction system: light stun, medium stun, heavy stun,
    launcher, wall knockback, ground bounce.
--]]

local HitStunKnockback = {}

local STUN_DURATIONS = {
    light   = 0.20,
    medium  = 0.40,
    heavy   = 0.70,
    launcher= 0.55,
}

-- How far off the ground a launcher sends the target
local LAUNCHER_UPFORCE = 45

-- Wall-bounce detection range
local WALL_RAYCAST_DIST = 3

--[[
    Apply(victim: Model, config)
    config = {
        Damage          : number
        StunType        : "light"|"medium"|"heavy"|"launcher"
        KnockbackForce  : number
        KnockbackDir    : Vector3 (unit horizontal direction)
        IsGroundBounce  : boolean|nil
    }
--]]
function HitStunKnockback.Apply(victim, config)
    local humanoid = victim:FindFirstChildOfClass("Humanoid")
    local rootPart = victim:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    -- Deal damage
    humanoid:TakeDamage(config.Damage)

    -- Stun: briefly disable controls via WalkSpeed
    local stunDur = STUN_DURATIONS[config.StunType] or 0.2
    local prevSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = 0
    task.delay(stunDur, function()
        if humanoid.Parent then
            humanoid.WalkSpeed = prevSpeed
        end
    end)

    -- Knockback velocity
    local kbDir   = config.KnockbackDir or Vector3.new(0, 0, -1)
    local kbForce = config.KnockbackForce or 0

    if kbForce > 0 then
        local velocity = kbDir.Unit * kbForce

        if config.StunType == "launcher" then
            velocity = Vector3.new(velocity.X * 0.6, LAUNCHER_UPFORCE, velocity.Z * 0.6)
        end

        rootPart.AssemblyLinearVelocity = velocity

        -- Wall-bounce check
        task.delay(0.08, function()
            if not rootPart.Parent then return end
            HitStunKnockback._checkWallBounce(rootPart, kbDir)
        end)

        -- Ground bounce if flagged
        if config.IsGroundBounce then
            task.delay(0.25, function()
                if rootPart.Parent then
                    rootPart.AssemblyLinearVelocity = Vector3.new(
                        rootPart.AssemblyLinearVelocity.X * 0.5,
                        math.abs(rootPart.AssemblyLinearVelocity.Y) * 0.4,
                        rootPart.AssemblyLinearVelocity.Z * 0.5
                    )
                end
            end)
        end
    end

    -- Fire stun event for VFX/HUD (stub)
    -- StunEvent:FireAllClients(victim, config.StunType)
end

function HitStunKnockback._checkWallBounce(rootPart, incomingDir)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {rootPart.Parent}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(
        rootPart.Position,
        incomingDir.Unit * WALL_RAYCAST_DIST,
        rayParams
    )

    if result then
        -- Reflect horizontal velocity
        local vel = rootPart.AssemblyLinearVelocity
        local normal = result.Normal
        local reflected = vel - 2 * vel:Dot(normal) * normal
        rootPart.AssemblyLinearVelocity = Vector3.new(
            reflected.X * 0.6, vel.Y, reflected.Z * 0.6
        )
    end
end

return HitStunKnockback
