--[[
    Steve_OakShield.lua
    Ability: Oak Shield (Q)
    Character: Steve

    Description:
      Steve conjures an oak-wood shield in front of him, absorbing the
      next incoming hit completely and dealing a short knockback counter
      to the attacker if the shield holds. The shield shatters after one
      blocked hit or when the duration expires.

    Values:
      Duration        : 2.0 s
      Cooldown        : 10.0 s
      Absorption      : 100% of one hit (cap 60 damage)
      Counter KB      : 30 force on attacker
      Movement penalty: 50% speed reduction while held
      VFX             : wooden block slam, shield glow
--]]

local HitboxSystem  = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun       = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Steve_OakShield = {}

local COOLDOWN       = 10.0
local SHIELD_DURATION = 2.0
local ABSORB_CAP     = 60
local COUNTER_FORCE  = 30
local SPEED_PENALTY  = 0.50

function Steve_OakShield.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("OakShield") then return end
    if not cooldowns:Start("OakShield", COOLDOWN) then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    -- Play shield raise animation
    -- AnimHelper.Play(character, "rbxassetid://STEVE_OAKSHIELD_RAISE")

    -- VFX: oak block materialises, glows
    -- VFXRemote:FireAllClients("SteveOakShieldUp", rootPart.Position)

    -- Apply speed penalty
    local prevSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = prevSpeed * SPEED_PENALTY

    local shieldActive = true
    local shattered    = false

    --[[
        The shield works by attaching a temporary attribute to the character
        that the server damage pipeline checks. When OakShieldActive == true,
        the pipeline calls Steve_OakShield.AbsorbHit() instead of applying
        normal damage.
    --]]
    character:SetAttribute("OakShieldActive", true)
    character:SetAttribute("OakShieldAbsorbCap", ABSORB_CAP)

    -- Expire after duration
    task.delay(SHIELD_DURATION, function()
        if shieldActive and not shattered then
            Steve_OakShield._shatter(character, humanoid, prevSpeed, false)
        end
    end)
end

--[[
    AbsorbHit(character, attacker, damage) -> finalDamage
    Called by the server damage pipeline when OakShieldActive is true.
    Returns the actual damage the character takes (0 on successful block).
--]]
function Steve_OakShield.AbsorbHit(character, attacker, damage)
    if not character:GetAttribute("OakShieldActive") then
        return damage
    end

    local cap = character:GetAttribute("OakShieldAbsorbCap") or ABSORB_CAP
    local absorbed = math.min(damage, cap)
    local leftover = damage - absorbed

    -- Counter-knockback the attacker
    local attackerRoot = attacker and attacker:FindFirstChild("HumanoidRootPart")
    local myRoot       = character:FindFirstChild("HumanoidRootPart")
    if attackerRoot and myRoot then
        local pushDir = (attackerRoot.Position - myRoot.Position).Unit
        HitStun.Apply(attacker, {
            Damage         = 0,
            StunType       = "medium",
            KnockbackForce = COUNTER_FORCE,
            KnockbackDir   = pushDir,
        })
    end

    -- Shatter the shield
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    Steve_OakShield._shatter(character, humanoid, nil, true)

    -- VFX: shield shatter
    -- VFXRemote:FireAllClients("SteveOakShieldShatter", myRoot and myRoot.Position)

    return leftover
end

function Steve_OakShield._shatter(character, humanoid, prevSpeed, wasHit)
    character:SetAttribute("OakShieldActive", false)
    character:SetAttribute("OakShieldAbsorbCap", 0)

    if humanoid and prevSpeed then
        humanoid.WalkSpeed = prevSpeed
    end

    -- VFX: lower / destroy shield visual
    -- VFXRemote:FireAllClients("SteveOakShieldDown", wasHit)
end

return Steve_OakShield
