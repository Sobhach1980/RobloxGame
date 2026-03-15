--[[
    Alex_Advancement.lua
    Ability: Advancement (E)
    Character: Alex

    Description:
      Alex raises her iron pickaxe skyward with both hands, arms fully
      extended overhead. Redstone-orange light floods through the handle
      and spreads up into the pick head, intensifying until the whole
      tool blazes — then a blinding flash, and it re-materialises as a
      gleaming diamond pickaxe.

      For 20 seconds Alex's M1 attacks gain diamond weapon stats:
        +10 flat damage, +15% attack speed, -0.1 s Quarry Strike CD
        per M1 hit, and +15% walk speed.
      After the duration the pickaxe reverts to iron and the cooldown begins.

    Animation:
      1. Alex grips pickaxe with both hands and thrusts it straight up.
      2. Orange-white redstone light floods up from grip to pick head.
      3. Glow intensifies to a full blinding flash frame.
      4. Pickaxe re-materialises in diamond form (ALEX_ADVANCEMENT_TRANSFORM).
      5. Alex lowers the pickaxe into her ready stance.

    Values:
      Cooldown              : 20.0 s  (starts after diamond form expires)
      Buff duration         : 20.0 s
      M1 damage bonus       : +10 flat
      Attack speed bonus    : +15%
      Quarry Strike CD shed : -0.1 s per M1 hit while active
      Walk speed bonus      : +15%
      Anim lock             : 1.8 s
      VFX                   : pickaxe hold-up → orange-white glow → diamond materialise
--]]

local Alex_Advancement = {}

local COOLDOWN        = 20.0
local BUFF_DURATION   = 20.0
local M1_DAMAGE_BONUS = 10
local SPEED_MULT      = 1.15
local ANIM_LOCK       = 1.8

function Alex_Advancement.Use(character, cooldowns, movementSystem, remotes, animManager)
    if cooldowns:IsOnCooldown("Advancement") then return end
    -- Prevent re-use while diamond form is already active
    if character:GetAttribute("AlexAdvancementActive") then return end

    -- Lock input for transform animation
    movementSystem:LockMovement(ANIM_LOCK)

    -- Play: both-hands raise → orange glow floods up the pick → flash → diamond
    -- AnimHelper.Play(character, "rbxassetid://ALEX_ADVANCEMENT_RAISE")

    -- VFX: redstone-orange light floods through the pickaxe, full-white flash
    -- VFXRemote:FireAllClients("AlexAdvancementTransform", character, "diamond")

    task.delay(ANIM_LOCK, function()
        if not character or not character.Parent then return end

        -- Mark diamond form active and set M1 damage bonus attribute
        -- (M1System reads AlexM1DamageBonus each swing and adds it to base damage)
        character:SetAttribute("AlexAdvancementActive", true)
        character:SetAttribute("AlexM1DamageBonus", M1_DAMAGE_BONUS)

        -- Apply walk speed boost
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local prevSpeed
        if humanoid then
            prevSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = humanoid.WalkSpeed * SPEED_MULT
        end

        -- Signal HUD: swap pickaxe icon to diamond, show buff timer
        -- remotes.HUDRemote:FireClient(player, "AdvancementActive", "diamond", BUFF_DURATION)

        -- Revert after buff duration; cooldown starts only after revert
        task.delay(BUFF_DURATION, function()
            Alex_Advancement._revert(character, humanoid, prevSpeed)
            cooldowns:Start("Advancement", COOLDOWN)
        end)
    end)
end

-- Reverts diamond form back to iron and clears all stat bonuses
function Alex_Advancement._revert(character, humanoid, prevSpeed)
    if not character or not character.Parent then return end

    character:SetAttribute("AlexAdvancementActive", false)
    character:SetAttribute("AlexM1DamageBonus", 0)

    if humanoid and prevSpeed then
        humanoid.WalkSpeed = prevSpeed
    end

    -- VFX: diamond pickaxe dims and reforms as iron
    -- VFXRemote:FireAllClients("AlexAdvancementTransform", character, "iron")

    -- HUD: revert pickaxe icon back to iron
    -- remotes.HUDRemote:FireClient(player, "AdvancementExpired")
end

return Alex_Advancement
