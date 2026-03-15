--[[
    Steve_CreativeOverride.lua
    Ultimate Ability 1 (Q): Creative Override
    Character: Steve | Form: Undying Resurgence

    Description:
      Steve taps into Creative Mode, briefly becoming immune to all damage
      and gaining massively boosted speed. During Override, his M1s deal
      bonus damage and leave terrain scorch marks. Lasts 3 seconds.
      Perfect for closing distance or escaping lethal combo pressure during ult form.

    Values:
      Cooldown (within ult) : 8.0 s
      Duration              : 3.0 s
      Speed boost           : +60% walk speed
      M1 bonus damage       : +10 flat while active
      Immunity              : full (damage received = 0)
      Terrain decal         : CreativeOverrideMark (black lightning scar)
      VFX                   : Steve glows white, black smoke aura, eye flash
--]]

local Steve_CreativeOverride = {}

local COOLDOWN    = 8.0
local DURATION    = 3.0
local SPEED_MULT  = 1.60
local M1_BONUS    = 10

function Steve_CreativeOverride.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("CreativeOverride") then return end
    if not cooldowns:Start("CreativeOverride", COOLDOWN) then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Play activation animation
    -- AnimHelper.Play(character, "rbxassetid://STEVE_CREATIVEOVERRIDE_START")

    -- VFX: white glow, black lightning rings, eye flash
    -- VFXRemote:FireAllClients("SteveCreativeOverride", character, true)

    -- Speed boost
    local baseSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = baseSpeed * SPEED_MULT

    -- Set immunity attribute (server damage pipeline reads this)
    character:SetAttribute("CreativeOverrideActive", true)
    character:SetAttribute("CreativeOverrideM1Bonus", M1_BONUS)

    task.delay(DURATION, function()
        if not humanoid.Parent then return end
        character:SetAttribute("CreativeOverrideActive", false)
        character:SetAttribute("CreativeOverrideM1Bonus", 0)
        humanoid.WalkSpeed = baseSpeed

        -- VFX: glow fades
        -- VFXRemote:FireAllClients("SteveCreativeOverride", character, false)
    end)
end

return Steve_CreativeOverride
