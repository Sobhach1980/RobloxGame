--[[
    Skeleton_Aimbot.lua
    Ability: Aimbot (F)
    Character: Skeleton

    Description:
      Skeleton enters a brief lock-on aiming pose (0.6 s channel). During
      the channel a reticle locks onto the nearest enemy. On channel
      completion, Skeleton fires a single homing bone arrow that tracks
      the target for up to 3 seconds. The arrow deals high damage and
      cannot be deflected. Plays lock-on tone during channel.

    Values:
      Cooldown        : 11.0 s
      Channel time    : 0.6 s  (can be interrupted by i-frame evasive only)
      Lock range      : 40 studs
      Homing speed    : 50
      Tracking time   : 3.0 s  (arrow chases for up to 3 s)
      Damage          : 40
      StunType        : heavy
      KB Force        : 50
      Hitbox radius   : 2.5
      VFX             : lock-on reticle tightens, icy blue tracking streak,
                        arrow leaves bone shard trail, lock-on SFX tone
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Skeleton_Aimbot = {}

local COOLDOWN     = 11.0
local CHANNEL_TIME = 0.60
local LOCK_RANGE   = 40
local HOMING_SPEED = 50
local TRACK_TIME   = 3.0
local DAMAGE       = 40
local KB_FORCE     = 50

function Skeleton_Aimbot.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("Aimbot") then return end
    if not cooldowns:Start("Aimbot", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Slow movement during channel
    movementSystem:LockMovement(CHANNEL_TIME)

    -- AnimHelper.Play(character, "rbxassetid://SKELETON_AIMBOT_CHANNEL")
    -- SFXRemote:FireAllClients("SkeletonAimbotTone", rootPart.Position)
    -- VFXRemote:FireAllClients("SkeletonAimbotChannel", character)

    -- Find lock-on target
    local target, targetRoot = Skeleton_Aimbot._findTarget(character, rootPart, LOCK_RANGE)

    -- VFX: reticle locks on (or sweeps if no target)
    -- VFXRemote:FireAllClients("SkeletonAimbotLock", targetRoot and targetRoot.Position or rootPart.Position)

    task.delay(CHANNEL_TIME, function()
        if not rootPart.Parent then return end

        -- AnimHelper.Play(character, "rbxassetid://SKELETON_AIMBOT_FIRE")

        local origin   = rootPart.Position + Vector3.new(0, 1, 0)
        local initDir  = targetRoot and (targetRoot.Position - origin).Unit or rootPart.CFrame.LookVector

        -- VFX: homing arrow spawns
        -- VFXRemote:FireAllClients("SkeletonAimbotArrow", origin, initDir)

        -- Homing projectile: each tick steer toward target
        local elapsed = 0
        local pos     = origin
        local vel     = initDir * HOMING_SPEED
        local hit     = false
        local conn

        conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
            if hit then conn:Disconnect() return end
            elapsed = elapsed + dt
            if elapsed >= TRACK_TIME then
                hit = true
                conn:Disconnect()
                return
            end

            -- Steer toward target
            if targetRoot and targetRoot.Parent then
                local toTarget = (targetRoot.Position - pos).Unit
                vel = (vel + toTarget * HOMING_SPEED * 5 * dt).Unit * HOMING_SPEED
            end

            pos = pos + vel * dt

            -- Overlap check
            local overlapParams = OverlapParams.new()
            overlapParams.FilterDescendantsInstances = {character}
            overlapParams.FilterType = Enum.RaycastFilterType.Exclude
            local parts = workspace:GetPartBoundsInRadius(pos, 2.5, overlapParams)
            for _, part in ipairs(parts) do
                local model = part:FindFirstAncestorOfClass("Model")
                if model and model ~= character then
                    local hum  = model:FindFirstChildOfClass("Humanoid")
                    local root = model:FindFirstChild("HumanoidRootPart")
                    if hum and root and hum.Health > 0 then
                        hit = true
                        conn:Disconnect()
                        HitStun.Apply(model, {
                            Damage         = DAMAGE,
                            StunType       = "heavy",
                            KnockbackForce = KB_FORCE,
                            KnockbackDir   = vel.Unit,
                        })
                        -- VFXRemote:FireAllClients("SkeletonAimbotHit", root.Position)
                        return
                    end
                end
            end
        end)
    end)
end

function Skeleton_Aimbot._findTarget(character, rootPart, range)
    local best, bestRoot, bestDist = nil, nil, range + 1
    for _, model in ipairs(workspace:GetChildren()) do
        if model ~= character and model:IsA("Model") then
            local hum  = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                local d = (root.Position - rootPart.Position).Magnitude
                if d < bestDist then bestDist = d; best = model; bestRoot = root end
            end
        end
    end
    return best, bestRoot
end

return Skeleton_Aimbot
