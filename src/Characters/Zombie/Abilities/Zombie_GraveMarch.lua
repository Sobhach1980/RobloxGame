--[[
    Zombie_GraveMarch.lua
    Ultimate Ability 2 (E): Grave March
    Character: Zombie | Form: Relentless Hunger

    Description:
      Zombie enters an unstoppable charge, trampling through enemies.
      While marching he is immune to knockback and deals continuous damage
      to any enemy he passes through. The march ends with a ground-pound
      finisher that launches all nearby enemies and triggers the ragdoll system.

    Values:
      Cooldown (within ult) : 11.0 s
      March duration        : 2.5 s
      March speed           : +45 (massive sprint)
      Knockback immunity    : true during march
      Per-hit damage        : 20  |  StunType: light (continuous)
      Hit interval          : 0.35 s per target
      Final slam damage     : 55  |  StunType: heavy  |  KB: 75
      Slam AoE radius       : 10 studs
      Move lock             : 2.7 s
      VFX                   : decayed smoke trail behind Zombie, red eyes,
                              enemies scatter on contact, final slam shockwave
      Camera                : heavy shake on slam
      Ragdoll               : on slam AoE victims
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Zombie_GraveMarch = {}

local COOLDOWN     = 11.0
local MARCH_DUR    = 2.5
local MARCH_SPEED  = 45
local MARCH_DAMAGE = 20
local HIT_INTERVAL = 0.35
local SLAM_DAMAGE  = 55
local SLAM_KB      = 75
local SLAM_RADIUS  = 10
local MOVE_LOCK    = 2.7

function Zombie_GraveMarch.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("GraveMarch") then return end
    if not cooldowns:Start("GraveMarch", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    movementSystem:LockMovement(MOVE_LOCK)

    -- AnimHelper.Play(character, "rbxassetid://ZOMBIE_GRAVEMARCH_CHARGE")

    -- Apply march speed
    local prevSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = prevSpeed + MARCH_SPEED

    -- Knockback immunity attribute
    character:SetAttribute("GraveMarchImmune", true)

    -- VFX: decay smoke trail, red eye glow
    -- VFXRemote:FireAllClients("ZombieGraveMarch", character, true)

    local elapsed    = 0
    local hitTimers  = {}   -- per-victim hit interval trackers
    local chargeDir  = rootPart.CFrame.LookVector

    local marchConn
    marchConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed >= MARCH_DUR then
            marchConn:Disconnect()
            Zombie_GraveMarch._endMarch(character, humanoid, rootPart, prevSpeed, chargeDir)
            return
        end

        -- Apply velocity each frame to maintain charge direction
        rootPart.AssemblyLinearVelocity = Vector3.new(
            chargeDir.X * MARCH_SPEED,
            rootPart.AssemblyLinearVelocity.Y,
            chargeDir.Z * MARCH_SPEED
        )

        -- Continuous hitbox during march
        local hitboxPos = rootPart.CFrame:PointToWorldSpace(Vector3.new(0, 0, -2))
        HitboxSystem.SpawnMeleeHitbox({
            Position = hitboxPos,
            Size     = Vector3.new(5, 5, 5),
            Duration = dt,
            Attacker = character,
            OnHit    = function(victim)
                local id = tostring(victim)
                hitTimers[id] = hitTimers[id] or 0
                -- Per-victim interval check
                if (elapsed - hitTimers[id]) >= HIT_INTERVAL then
                    hitTimers[id] = elapsed
                    HitStun.Apply(victim, {
                        Damage         = MARCH_DAMAGE,
                        StunType       = "light",
                        KnockbackForce = 20,
                        KnockbackDir   = chargeDir,
                    })
                end
            end,
        })
    end)
end

function Zombie_GraveMarch._endMarch(character, humanoid, rootPart, prevSpeed, chargeDir)
    humanoid.WalkSpeed = prevSpeed
    character:SetAttribute("GraveMarchImmune", false)

    -- VFX: final slam
    -- AnimHelper.Play(character, "rbxassetid://ZOMBIE_GRAVEMARCH_SLAM")
    -- VFXRemote:FireAllClients("ZombieGraveMarch", character, false)
    -- CameraShakeRemote:FireAllClients("strong", rootPart.Position, 28)

    local slamPos = rootPart.Position
    rootPart.AssemblyLinearVelocity = Vector3.new(0, -60, 0)

    task.delay(0.15, function()
        if not rootPart.Parent then return end
        HitboxSystem.SpawnAoE({
            Position = rootPart.Position,
            Radius   = SLAM_RADIUS,
            Attacker = character,
            OnHit    = function(victim)
                local vRoot    = victim:FindFirstChild("HumanoidRootPart")
                local blastDir = vRoot and (vRoot.Position - slamPos).Unit or Vector3.new(0,1,0)
                HitStun.Apply(victim, {
                    Damage         = SLAM_DAMAGE,
                    StunType       = "heavy",
                    KnockbackForce = SLAM_KB,
                    KnockbackDir   = (blastDir + Vector3.new(0,0.8,0)).Unit,
                    IsGroundBounce = true,
                })
                -- RagdollRemote:FireServer(victim)
            end,
        })
    end)
end

return Zombie_GraveMarch
