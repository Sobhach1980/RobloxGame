--[[
    Skeleton_ArrowStorm.lua
    Ability: Arrow Storm (E)
    Character: Skeleton

    Description:
      Skeleton fires a volley of arrows in a rapid burst — 8 arrows
      raining down from above in a targeted AoE zone. Any enemy standing
      in the zone takes per-arrow hits. Excellent at denying areas
      and punishing stationary targets.

    Values:
      Cooldown        : 10.0 s
      Arrow count     : 8
      Fire interval   : 0.12 s
      Target zone radius: 8 studs (aimed at crosshair hit point)
      Damage/arrow    : 14
      StunType        : light (each)
      KB force        : 10 (minor each)
      Arrow descent speed: 50
      VFX             : icy blue arrows rain down, storm trail,
                        zone indicator ring on ground, rhythmic impact sparks
      Camera          : rhythmic impact response per arrow (minor shake)
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Skeleton_ArrowStorm = {}

local COOLDOWN    = 10.0
local NUM_ARROWS  = 8
local FIRE_INT    = 0.12
local ZONE_RADIUS = 8
local DAMAGE      = 14
local KB_FORCE    = 10

function Skeleton_ArrowStorm.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("ArrowStorm") then return end
    if not cooldowns:Start("ArrowStorm", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- AnimHelper.Play(character, "rbxassetid://SKELETON_ARROWSTORM_FIRE")

    -- Determine target zone: raycast from camera or use look direction
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {character}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local lookResult = workspace:Raycast(rootPart.Position, rootPart.CFrame.LookVector * 40, rp)
    local zoneCenter = lookResult and lookResult.Position or (rootPart.Position + rootPart.CFrame.LookVector * 30)
    zoneCenter = Vector3.new(zoneCenter.X, zoneCenter.Y, zoneCenter.Z)

    -- VFX: zone indicator ring
    -- VFXRemote:FireAllClients("SkeletonArrowStormZone", zoneCenter, ZONE_RADIUS)

    -- Fire arrows one by one
    for i = 1, NUM_ARROWS do
        task.delay((i - 1) * FIRE_INT, function()
            if not rootPart.Parent then return end

            -- Randomise landing within zone radius
            local rx = math.random(-ZONE_RADIUS * 10, ZONE_RADIUS * 10) / 10
            local rz = math.random(-ZONE_RADIUS * 10, ZONE_RADIUS * 10) / 10
            local landPos = zoneCenter + Vector3.new(rx, 0, rz)
            local fallOrigin = landPos + Vector3.new(0, 35, 0)
            local fallDir = Vector3.new(0, -1, 0)

            -- VFX: arrow descent visual
            -- VFXRemote:FireAllClients("SkeletonArrowStormArrow", fallOrigin, landPos)

            -- Camera: minor rhythmic shake
            -- CameraShakeRemote:FireAllClients("rhythmic", landPos, 10)

            HitboxSystem.SpawnProjectile({
                Origin       = fallOrigin,
                Direction    = fallDir,
                Speed        = 50,
                MaxRange     = 40,
                HitboxRadius = 1.5,
                Attacker     = character,
                Gravity      = 0,
                OnHit        = function(victim, hitPos)
                    HitStun.Apply(victim, {
                        Damage         = DAMAGE,
                        StunType       = "light",
                        KnockbackForce = KB_FORCE,
                        KnockbackDir   = Vector3.new(0, -1, 0),
                    })
                    -- VFXRemote:FireAllClients("SkeletonArrowStormImpact", hitPos or landPos)
                end,
                OnExpire = function()
                    -- VFXRemote:FireAllClients("SkeletonArrowStormGroundHit", landPos)
                end,
            })
        end)
    end
end

return Skeleton_ArrowStorm
