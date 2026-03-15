--[[
    Alex_Advancement.lua
    Ability: Advancement (E)
    Character: Alex

    NOTE: This is Alex's unique Advancement. Completely different gameplay
    purpose from Steve's Advancement (which is a forward sword charge).
    Alex's Advancement is a utility buff that improves her redstone synergy
    and mining pressure — reflects her role as a tech/utility fighter.

    Description:
      Alex activates a short Advancement boost that increases her next
      ability's effectiveness. For 4 seconds: Redstone Pulse gains +30%
      damage and extended range, Quarry Strike gains +15 damage and removes
      its ground-lock delay (instant), and Ender Shift's teleport distance
      is doubled. Only one ability benefits before Advancement expires.

    Values:
      Cooldown        : 9.0 s
      Buff duration   : 4.0 s (or until one ability consumes it)
      Redstone bonus  : +30% damage, +4 stud range
      Quarry bonus    : +15 damage, ground-lock instant
      EnderShift bonus: teleport distance x2
      VFX             : redstone circuit glow on arms, green energy pulse
--]]

local Alex_Advancement = {}

local COOLDOWN      = 9.0
local BUFF_DURATION = 4.0

function Alex_Advancement.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("Advancement") then return end
    if not cooldowns:Start("Advancement", COOLDOWN) then return end

    -- VFX: redstone circuit lights up on Alex's arms, green energy pulse
    -- VFXRemote:FireAllClients("AlexAdvancement", character, true)

    -- Play short buff animation
    -- AnimHelper.Play(character, "rbxassetid://ALEX_ADVANCEMENT_ACTIVATE")

    -- Set advancement attribute that other abilities check
    character:SetAttribute("AlexAdvancementActive", true)
    character:SetAttribute("AlexAdvancementConsumed", false)

    task.delay(BUFF_DURATION, function()
        if not character:GetAttribute("AlexAdvancementConsumed") then
            Alex_Advancement._expire(character)
        end
    end)
end

-- Called by other Alex abilities when they consume the buff
function Alex_Advancement.Consume(character)
    if not character:GetAttribute("AlexAdvancementActive") then return false end
    character:SetAttribute("AlexAdvancementActive", false)
    character:SetAttribute("AlexAdvancementConsumed", true)
    -- VFXRemote:FireAllClients("AlexAdvancement", character, false)
    return true
end

function Alex_Advancement._expire(character)
    character:SetAttribute("AlexAdvancementActive", false)
    -- VFXRemote:FireAllClients("AlexAdvancement", character, false)
end

-- Query helper used by other ability scripts
function Alex_Advancement.IsActive(character)
    return character:GetAttribute("AlexAdvancementActive") == true
end

return Alex_Advancement
