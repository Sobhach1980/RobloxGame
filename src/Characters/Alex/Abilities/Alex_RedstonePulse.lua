--[[
    Alex_RedstonePulse.lua
    Ability: Redstone Pulse (R)
    Character: Alex

    Description:
      Alex fires a burst of redstone energy in a straight line that
      detonates on the first target or at max range, dealing damage and
      applying a "Shocked" debuff that briefly halves the victim's movement
      speed. If Advancement is active, damage is increased by 30% and range
      extended by 4 studs.

    Values:
      Cooldown        : 6.0 s
      Projectile speed: 55
      Base range      : 22 studs
      Base damage     : 28
      Shocked debuff  : 1.5 s (50% speed reduction)
      Hitbox radius   : 2.5
      VFX             : red redstone bolt, mechanical pulse hum on fire,
                        electric crackle on hit
--]]

local HitboxSystem   = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun        = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)
local AlexAdvancement = require(script.Parent.Alex_Advancement)

local Alex_RedstonePulse = {}

local COOLDOWN      = 6.0
local BASE_DAMAGE   = 28
local BASE_RANGE    = 22
local PROJ_SPEED    = 55
local HB_RADIUS     = 2.5
local ADV_DMG_MULT  = 1.30
local ADV_RANGE_ADD = 4
local SHOCK_DUR     = 1.5

function Alex_RedstonePulse.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("RedstonePulse") then return end
    if not cooldowns:Start("RedstonePulse", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Check advancement buff
    local advActive = AlexAdvancement.IsActive(character)
    local damage    = advActive and (BASE_DAMAGE * ADV_DMG_MULT) or BASE_DAMAGE
    local range     = advActive and (BASE_RANGE + ADV_RANGE_ADD) or BASE_RANGE
    if advActive then AlexAdvancement.Consume(character) end

    -- Play fire animation
    -- AnimHelper.Play(character, "rbxassetid://ALEX_REDSTONEPULSE_FIRE")

    local fireDir = rootPart.CFrame.LookVector
    local origin  = rootPart.Position + Vector3.new(0, 0.5, 0)

    -- VFX: redstone bolt spawns
    -- VFXRemote:FireAllClients("AlexRedstonePulse", origin, fireDir, advActive)

    HitboxSystem.SpawnProjectile({
        Origin       = origin,
        Direction    = fireDir,
        Speed        = PROJ_SPEED,
        MaxRange     = range,
        HitboxRadius = HB_RADIUS,
        Attacker     = character,
        Gravity      = 0,
        OnHit        = function(victim, hitPos)
            -- Apply shocked debuff
            local vHum = victim:FindFirstChildOfClass("Humanoid")
            if vHum then
                local prevSpeed = vHum.WalkSpeed
                vHum.WalkSpeed  = prevSpeed * 0.5
                task.delay(SHOCK_DUR, function()
                    if vHum.Parent then vHum.WalkSpeed = prevSpeed end
                end)
            end

            HitStun.Apply(victim, {
                Damage         = damage,
                StunType       = "medium",
                KnockbackForce = 20,
                KnockbackDir   = fireDir,
            })

            -- VFX: electric crackle on hit
            -- VFXRemote:FireAllClients("RedstonePulseHit", hitPos)
        end,
        OnExpire = function()
            -- VFX: pulse dissipates at max range
            -- VFXRemote:FireAllClients("RedstonePulseExpire", origin + fireDir * range)
        end,
    })
end

return Alex_RedstonePulse
