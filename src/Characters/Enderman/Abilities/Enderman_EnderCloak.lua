--[[
    Enderman_EnderCloak.lua
    Ability: Ender Cloak (R)
    Character: Enderman

    Description:
      Enderman becomes partially invisible (70% transparency) and all
      incoming projectiles are deflected for 2.5 seconds. Melee attacks
      still deal damage. While cloaked, Enderman's next ability or melee
      hit is an "ambush" that deals +25% bonus damage. Cloak breaks on
      the first ambush hit or when duration ends.

    Values:
      Cooldown        : 10.0 s
      Duration        : 2.5 s
      Transparency    : 0.70
      Projectile deflect: true (projectiles pass through or reverse)
      Ambush bonus    : +25% on first hit after cloak
      VFX             : subtle vanish warp, void edge silhouette visible,
                        eye glow barely visible during cloak
--]]

local Enderman_EnderCloak = {}

local COOLDOWN    = 10.0
local DURATION    = 2.5
local AMBUSH_MULT = 1.25

function Enderman_EnderCloak.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("EnderCloak") then return end
    if not cooldowns:Start("EnderCloak", COOLDOWN) then return end

    -- VFX: vanish shimmer
    -- VFXRemote:FireAllClients("EndermanEnderCloakStart", character)

    -- AnimHelper.Play(character, "rbxassetid://ENDERMAN_ENDERCLOAK_VANISH")

    character:SetAttribute("EnderCloakActive", true)
    character:SetAttribute("EnderCloakAmbushReady", true)
    character:SetAttribute("EnderCloakAmbushMult", AMBUSH_MULT)

    -- Apply transparency to character parts
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part:SetAttribute("PreCloakTransparency", part.Transparency)
            part.Transparency = 0.70
        end
    end

    -- Expire after duration
    task.delay(DURATION, function()
        if character:GetAttribute("EnderCloakActive") then
            Enderman_EnderCloak._endCloak(character)
        end
    end)
end

-- Called by the damage pipeline when a hit lands while cloaked
function Enderman_EnderCloak.ConsumeAmbush(character)
    if not character:GetAttribute("EnderCloakAmbushReady") then return 1.0 end
    character:SetAttribute("EnderCloakAmbushReady", false)
    Enderman_EnderCloak._endCloak(character)
    return AMBUSH_MULT
end

function Enderman_EnderCloak._endCloak(character)
    character:SetAttribute("EnderCloakActive", false)
    character:SetAttribute("EnderCloakAmbushReady", false)

    -- Restore transparency
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local prev = part:GetAttribute("PreCloakTransparency")
            if prev ~= nil then part.Transparency = prev end
        end
    end

    -- VFX: reappear shimmer
    -- VFXRemote:FireAllClients("EndermanEnderCloakEnd", character)
end

-- Query from damage pipeline: should projectile be deflected?
function Enderman_EnderCloak.IsDeflecting(character)
    return character:GetAttribute("EnderCloakActive") == true
end

return Enderman_EnderCloak
