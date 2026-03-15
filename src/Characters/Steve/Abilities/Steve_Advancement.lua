--[[
    Steve_Advancement.lua
    Ability: Advancement (E)
    Character: Steve

    Description:
      Steve raises his iron sword above his head with one arm fully extended.
      The blade pulses with blue-white energy, glowing brighter and brighter
      until the whole sword is engulfed in a blinding flash — then it
      re-materialises as a shining diamond sword.

      For 20 seconds Steve's M1 attacks gain diamond weapon stats:
        +12 flat damage, +15% attack speed, +20% walk speed.
      After the duration the sword reverts to iron and the cooldown begins.

    Animation:
      1. Steve extends sword arm upward, sword tip pointing at the sky.
      2. Blade emits a rising blue-white glow (STEVE_ADVANCEMENT_GLOW anim).
      3. At peak brightness: full-white flash frame.
      4. Sword re-materialises in diamond form (STEVE_ADVANCEMENT_TRANSFORM anim).
      5. Steve lowers arm into ready stance.

    Values:
      Cooldown          : 20.0 s  (starts after diamond form expires)
      Buff duration     : 20.0 s
      M1 damage bonus   : +12 flat
      Attack speed bonus: +15%
      Walk speed bonus  : +20%
      Anim lock         : 1.8 s
      VFX               : sword hold-up → white-blue glow surge → diamond materialise
--]]

local Steve_Advancement = {}

local COOLDOWN        = 20.0
local BUFF_DURATION   = 20.0
local M1_DAMAGE_BONUS = 12
local SPEED_MULT      = 1.20
local ANIM_LOCK       = 1.8

function Steve_Advancement.Use(character, cooldowns, movementSystem, remotes, animManager)
    if cooldowns:IsOnCooldown("Advancement") then return end
    -- Prevent re-use while diamond form is already active
    if character:GetAttribute("SteveAdvancementActive") then return end

    -- Lock input for transform animation
    movementSystem:LockMovement(ANIM_LOCK)

    -- Play: extend sword skyward → glow → flash → diamond materialise
    -- AnimHelper.Play(character, "rbxassetid://STEVE_ADVANCEMENT_RAISE")

    -- VFX: blue-white energy floods up the blade, then a full-white flash
    -- VFXRemote:FireAllClients("SteveAdvancementTransform", character, "diamond")

    task.delay(ANIM_LOCK, function()
        if not character or not character.Parent then return end

        -- Mark diamond form active and set M1 damage bonus attribute
        -- (M1System reads SteveM1DamageBonus each swing and adds it to base damage)
        character:SetAttribute("SteveAdvancementActive", true)
        character:SetAttribute("SteveM1DamageBonus", M1_DAMAGE_BONUS)

        -- Apply walk speed boost
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local prevSpeed
        if humanoid then
            prevSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = humanoid.WalkSpeed * SPEED_MULT
        end

        -- Signal HUD: swap sword icon to diamond, show buff timer
        -- remotes.HUDRemote:FireClient(player, "AdvancementActive", "diamond", BUFF_DURATION)

        -- Revert after buff duration; cooldown starts only after revert
        task.delay(BUFF_DURATION, function()
            Steve_Advancement._revert(character, humanoid, prevSpeed)
            cooldowns:Start("Advancement", COOLDOWN)
        end)
    end)
end

-- Reverts diamond form back to iron and clears all stat bonuses
function Steve_Advancement._revert(character, humanoid, prevSpeed)
    if not character or not character.Parent then return end

    character:SetAttribute("SteveAdvancementActive", false)
    character:SetAttribute("SteveM1DamageBonus", 0)

    if humanoid and prevSpeed then
        humanoid.WalkSpeed = prevSpeed
    end

    -- VFX: diamond sword dims and reforms as iron
    -- VFXRemote:FireAllClients("SteveAdvancementTransform", character, "iron")

    -- HUD: revert sword icon back to iron
    -- remotes.HUDRemote:FireClient(player, "AdvancementExpired")
end

return Steve_Advancement
