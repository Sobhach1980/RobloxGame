--[[
    Skeleton_ArrowstormBarrage.lua
    Ultimate Ability 2 (E): Arrowstorm Barrage
    Character: Skeleton | Form: Perfect Aim

    Description:
      The perfect-aim-enhanced Arrow Storm. Skeleton fires 16 bone arrows
      in a relentless barrage over 2 seconds — all aimed at the locked
      target position. Each arrow deals more damage than the base Arrow Storm
      and leaves a bone shard impact zone on the ground for 2 s.
      Causes rhythmic impact camera response per arrow.

    Values:
      Cooldown (within ult) : 10.0 s
      Arrow count           : 16
      Fire interval         : 0.12 s
      Per-arrow damage      : 22
      StunType              : light per hit
      KB Force              : 12 per hit
      Ground shard zone     : 2 stud radius, 2 s, 6 dmg on entry
      VFX                   : rapid icy blue arrows, bone shard impact craters,
                              rhythmic camera shake per hit, arrow streak trails
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Skeleton_ArrowstormBarrage = {}

local COOLDOWN     = 10.0
local NUM_ARROWS   = 16
local FIRE_INT     = 0.12
local DAMAGE       = 22
local KB_FORCE     = 12
local ZONE_RADIUS  = 2
local ZONE_DUR     = 2.0
local ZONE_DMG     = 6

function Skeleton_ArrowstormBarrage.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("ArrowstormBarrage") then return end
    if not cooldowns:Start("ArrowstormBarrage", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- AnimHelper.Play(character, "rbxassetid://SKELETON_ARROWSTORM_BARRAGE")
    -- VFXRemote:FireAllClients("SkeletonArrowstormBarrageStart", character)

    -- Target lock: find nearest enemy
    local target, targetRoot = Skeleton_ArrowstormBarrage._findTarget(character, rootPart, 50)
    local aimPoint = targetRoot and targetRoot.Position or (rootPart.Position + rootPart.CFrame.LookVector * 35)

    for i = 1, NUM_ARROWS do
        task.delay((i - 1) * FIRE_INT, function()
            if not rootPart.Parent then return end

            -- Update aim point toward moving target
            local currentAim = (targetRoot and targetRoot.Parent) and targetRoot.Position or aimPoint
            local origin     = rootPart.Position + Vector3.new(0, 1, 0)
            local arrowDir   = (currentAim - origin).Unit

            -- VFXRemote:FireAllClients("SkeletonArrowstormBarrageArrow", origin, arrowDir, i)
            -- CameraShakeRemote:FireAllClients("rhythmic", currentAim, 8)

            HitboxSystem.SpawnProjectile({
                Origin       = origin,
                Direction    = arrowDir,
                Speed        = 70,
                MaxRange     = 55,
                HitboxRadius = 1.8,
                Attacker     = character,
                Gravity      = 0,
                OnHit        = function(victim, hitPos)
                    HitStun.Apply(victim, {
                        Damage         = DAMAGE,
                        StunType       = "light",
                        KnockbackForce = KB_FORCE,
                        KnockbackDir   = arrowDir,
                    })
                    if hitPos then
                        Skeleton_ArrowstormBarrage._spawnShard(character, hitPos)
                    end
                    -- VFXRemote:FireAllClients("SkeletonArrowstormBarrageHit", hitPos or currentAim)
                end,
                OnExpire = function()
                    Skeleton_ArrowstormBarrage._spawnShard(character, currentAim)
                end,
            })
        end)
    end
end

function Skeleton_ArrowstormBarrage._spawnShard(character, position)
    HitboxSystem.SpawnLingeringZone({
        Position     = position,
        Size         = Vector3.new(ZONE_RADIUS*2, 3, ZONE_RADIUS*2),
        Duration     = ZONE_DUR,
        TickInterval = ZONE_DUR + 1,
        Attacker     = character,
        OnTick       = function(victim)
            HitStun.Apply(victim, { Damage=ZONE_DMG, StunType="light", KnockbackForce=0, KnockbackDir=Vector3.new(0,1,0) })
        end,
    })
end

function Skeleton_ArrowstormBarrage._findTarget(character, rootPart, range)
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

return Skeleton_ArrowstormBarrage
