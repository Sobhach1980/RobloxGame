--[[
    Skeleton_BoneBarrage.lua
    Ability: Bone Barrage (Q)
    Character: Skeleton

    Description:
      Skeleton fires a spread of 4 bone shards in a horizontal fan.
      Each shard deals moderate damage. Shards that miss embed in surfaces
      and become 3-second lingering hazards that deal 5 damage to enemies
      who walk over them.

    Values:
      Cooldown        : 7.0 s
      Shard count     : 4
      Spread angle    : 30 degrees total
      Damage/shard    : 18
      StunType        : light
      KB Force        : 15
      Projectile speed: 65
      Range           : 35 studs
      Hazard duration : 3.0 s
      Hazard damage   : 5 (on overlap entry)
      VFX             : bone shard fan fire, icy blue trail per shard,
                        embedded shard model on miss
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Skeleton_BoneBarrage = {}

local COOLDOWN      = 7.0
local NUM_SHARDS    = 4
local SPREAD_DEG    = 30
local DAMAGE        = 18
local KB_FORCE      = 15
local PROJ_SPEED    = 65
local PROJ_RANGE    = 35
local HAZARD_DUR    = 3.0
local HAZARD_DMG    = 5

function Skeleton_BoneBarrage.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("BoneBarrage") then return end
    if not cooldowns:Start("BoneBarrage", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- AnimHelper.Play(character, "rbxassetid://SKELETON_BONEBARRAGE_FIRE")

    local baseDir    = rootPart.CFrame.LookVector
    local halfSpread = SPREAD_DEG / 2
    local step       = (NUM_SHARDS > 1) and (SPREAD_DEG / (NUM_SHARDS - 1)) or 0
    local origin     = rootPart.Position + Vector3.new(0, 1, 0)

    -- VFXRemote:FireAllClients("SkeletonBoneBarrageStart", origin, baseDir)

    for i = 1, NUM_SHARDS do
        local angle   = -halfSpread + (i - 1) * step
        local rotated = CFrame.Angles(0, math.rad(angle), 0) * baseDir
        local shardDir = Vector3.new(rotated.X, baseDir.Y, rotated.Z).Unit

        -- VFXRemote:FireAllClients("SkeletonBoneShard", origin, shardDir, i)

        HitboxSystem.SpawnProjectile({
            Origin       = origin,
            Direction    = shardDir,
            Speed        = PROJ_SPEED,
            MaxRange     = PROJ_RANGE,
            HitboxRadius = 1.5,
            Attacker     = character,
            Gravity      = 8,
            OnHit        = function(victim, hitPos)
                HitStun.Apply(victim, {
                    Damage         = DAMAGE,
                    StunType       = "light",
                    KnockbackForce = KB_FORCE,
                    KnockbackDir   = shardDir,
                })
                -- VFXRemote:FireAllClients("SkeletonBoneShardHit", hitPos)
            end,
            OnExpire = function()
                -- Shard embeds in surface: create hazard zone
                local finalPos = origin + shardDir * PROJ_RANGE
                Skeleton_BoneBarrage._spawnHazard(character, finalPos, shardDir)
            end,
        })
    end
end

function Skeleton_BoneBarrage._spawnHazard(character, position, direction)
    -- VFXRemote:FireAllClients("SkeletonBoneShardEmbedded", position, direction)

    -- Instant damage on first overlap, then zone expires
    HitboxSystem.SpawnLingeringZone({
        Position     = position,
        Size         = Vector3.new(3, 3, 3),
        Duration     = HAZARD_DUR,
        TickInterval = HAZARD_DUR + 1,   -- one-shot on overlap (entry)
        Attacker     = character,
        OnTick       = function(victim)
            HitStun.Apply(victim, { Damage=HAZARD_DMG, StunType="light", KnockbackForce=0, KnockbackDir=Vector3.new(0,1,0) })
        end,
    })
end

return Skeleton_BoneBarrage
