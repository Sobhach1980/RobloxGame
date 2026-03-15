--[[
    Skeleton_BonebreakerShot.lua
    Ultimate Ability 3 (R): Bonebreaker Shot
    Character: Skeleton | Form: Perfect Aim

    Description:
      The cinematic ult finisher. Skeleton draws back a massive bone-
      spear arrow over a 1.5 s charge, then fires a single devastating
      precision shot that travels at extreme speed, pierces through any
      obstacle, and deals massive damage. On hit it shatters into bone
      shards in a cone behind the target. Triggers slow-motion on the hit
      frame for dramatic effect and causes heavy screen shake.

    Values:
      Cooldown (within ult) : 18.0 s
      Charge time           : 1.5 s  (held; releases on input up or auto)
      Projectile speed      : 200 (near-instant)
      Range                 : 80 studs (full arena width)
      Damage                : 85
      StunType              : heavy  |  finisher potential
      KB Force              : 100 (extreme)
      Pierces terrain       : true
      Shard cone            : 8 shards, 40 degree behind-target cone, 20 dmg each
      Hit-stop (slow-mo)    : 0.08 s (time scale event)
      Move lock during charge: full
      VFX                   : bow charges icy blue energy, screen vignette,
                              massive bone spear flies, bone shard explosion behind
      Camera                : cinematic slow-mo on hit, heavy shake
      Ragdoll               : triggered on hit
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Skeleton_BonebreakerShot = {}

local COOLDOWN     = 18.0
local CHARGE_TIME  = 1.5
local PROJ_SPEED   = 200
local PROJ_RANGE   = 80
local DAMAGE       = 85
local KB_FORCE     = 100
local SHARD_COUNT  = 8
local SHARD_CONE   = 40   -- degrees
local SHARD_DAMAGE = 20

function Skeleton_BonebreakerShot.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("BonebreakerShot") then return end
    if not cooldowns:Start("BonebreakerShot", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Lock movement during charge
    movementSystem:LockMovement(CHARGE_TIME + 0.3)

    -- AnimHelper.Play(character, "rbxassetid://SKELETON_BONEBREAKERSHOT_CHARGE")
    -- VFXRemote:FireAllClients("SkeletonBonebreakerCharge", character, CHARGE_TIME)
    -- SFXRemote:FireAllClients("SkeletonBonebreakerChargeAudio", rootPart.Position)

    -- Screen vignette for sniper tension
    -- VignetteRemote:FireClient(player, true, CHARGE_TIME)

    task.delay(CHARGE_TIME, function()
        if not rootPart.Parent then return end

        local fireDir = rootPart.CFrame.LookVector
        local origin  = rootPart.Position + Vector3.new(0, 1, 0)

        -- AnimHelper.Play(character, "rbxassetid://SKELETON_BONEBREAKERSHOT_FIRE")
        -- VFXRemote:FireAllClients("SkeletonBonebreakerFire", origin, fireDir)
        -- SFXRemote:FireAllClients("SkeletonBonebreakerFireAudio", origin)

        HitboxSystem.SpawnProjectile({
            Origin       = origin,
            Direction    = fireDir,
            Speed        = PROJ_SPEED,
            MaxRange     = PROJ_RANGE,
            HitboxRadius = 2.5,
            Attacker     = character,
            Gravity      = 0,           -- Perfect Aim: no drop
            OnHit        = function(victim, hitPos)
                -- Hit-stop slow-mo event
                -- SlowMoRemote:FireAllClients(0.08)

                -- Camera: heavy shake
                -- CameraShakeRemote:FireAllClients("cinematic", hitPos or victim.HumanoidRootPart.Position, 45)

                -- VFX: impact burst + slow-mo flash
                -- VFXRemote:FireAllClients("SkeletonBonebreakerHit", hitPos or victim.HumanoidRootPart.Position)

                HitStun.Apply(victim, {
                    Damage         = DAMAGE,
                    StunType       = "heavy",
                    KnockbackForce = KB_FORCE,
                    KnockbackDir   = fireDir,
                    IsGroundBounce = true,
                })

                -- Ragdoll
                -- RagdollRemote:FireServer(victim)

                -- Spawn bone shard cone behind target
                Skeleton_BonebreakerShot._shardCone(character, hitPos or victim.HumanoidRootPart.Position, fireDir)
            end,
            OnExpire = function()
                -- VFXRemote:FireAllClients("SkeletonBonebreakerMiss", origin + fireDir * PROJ_RANGE)
            end,
        })
    end)
end

function Skeleton_BonebreakerShot._shardCone(character, hitPos, mainDir)
    local halfCone = SHARD_CONE / 2
    local step     = SHARD_CONE / (SHARD_COUNT - 1)

    -- VFXRemote:FireAllClients("SkeletonBonebreakerShardCone", hitPos, mainDir, SHARD_CONE)

    for i = 1, SHARD_COUNT do
        local angle    = -halfCone + (i - 1) * step
        local rotated  = CFrame.Angles(0, math.rad(angle), 0) * mainDir
        local shardDir = Vector3.new(rotated.X, mainDir.Y * 0.3, rotated.Z).Unit

        HitboxSystem.SpawnProjectile({
            Origin       = hitPos,
            Direction    = shardDir,
            Speed        = 50,
            MaxRange     = 15,
            HitboxRadius = 1.5,
            Attacker     = character,
            Gravity      = 12,
            OnHit        = function(victim, hp)
                HitStun.Apply(victim, {
                    Damage         = SHARD_DAMAGE,
                    StunType       = "medium",
                    KnockbackForce = 30,
                    KnockbackDir   = shardDir,
                })
                -- VFXRemote:FireAllClients("SkeletonBonebreakerShardHit", hp or victim.HumanoidRootPart.Position)
            end,
        })
    end
end

return Skeleton_BonebreakerShot
