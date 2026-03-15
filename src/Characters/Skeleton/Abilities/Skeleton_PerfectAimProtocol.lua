--[[
    Skeleton_PerfectAimProtocol.lua
    Ultimate Ability 1 (Q): Perfect Aim Protocol
    Character: Skeleton | Form: Perfect Aim

    Description:
      Skeleton activates a combat algorithm that guarantees every
      projectile homes perfectly onto the nearest target for 4 seconds.
      During this window all arrows deal +50% damage, have zero gravity,
      and ignore dodge i-frames. Each hit applies a "Markedf" debuff that
      increases all subsequent damage taken from Skeleton by 20% for 5 s.

    Values:
      Cooldown (within ult) : 8.0 s
      Duration              : 4.0 s
      Damage boost          : +50% on all projectiles
      Gravity override      : 0
      Dodge bypass          : true
      Marked debuff         : +20% damage taken from Skeleton, 5 s
      VFX                   : tracking lines on screen, icy blue eye glow,
                              lock-on reticle on all projectiles during window
--]]

local Skeleton_PerfectAimProtocol = {}

local COOLDOWN    = 8.0
local DURATION    = 4.0
local DMG_BOOST   = 1.50
local MARK_MULT   = 1.20
local MARK_DUR    = 5.0

function Skeleton_PerfectAimProtocol.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("PerfectAimProtocol") then return end
    if not cooldowns:Start("PerfectAimProtocol", COOLDOWN) then return end

    -- AnimHelper.Play(character, "rbxassetid://SKELETON_PERFECTAIMPROTOCOL_ACTIVATE")
    -- VFXRemote:FireAllClients("SkeletonPerfectAimProtocol", character, true)
    -- SFXRemote:FireAllClients("SkeletonPerfectAimTone", character)

    character:SetAttribute("PerfectAimProtocolActive", true)
    character:SetAttribute("PerfectAimProtocolDmgMult", DMG_BOOST)
    character:SetAttribute("PerfectAimProtocolMarkMult", MARK_MULT)
    character:SetAttribute("PerfectAimProtocolMarkDur", MARK_DUR)

    task.delay(DURATION, function()
        character:SetAttribute("PerfectAimProtocolActive", false)
        character:SetAttribute("PerfectAimProtocolDmgMult", 1.0)
        -- VFXRemote:FireAllClients("SkeletonPerfectAimProtocol", character, false)
    end)
end

-- Called by projectile abilities to get current damage multiplier
function Skeleton_PerfectAimProtocol.GetDmgMult(character)
    if not character:GetAttribute("PerfectAimProtocolActive") then return 1.0 end
    return character:GetAttribute("PerfectAimProtocolDmgMult") or 1.0
end

-- Called when a projectile hits an enemy while protocol is active
function Skeleton_PerfectAimProtocol.ApplyMark(character, victim)
    if not character:GetAttribute("PerfectAimProtocolActive") then return end
    local mult = character:GetAttribute("PerfectAimProtocolMarkMult") or 1.0
    local dur  = character:GetAttribute("PerfectAimProtocolMarkDur") or MARK_DUR

    victim:SetAttribute("SkeletonMarked", true)
    victim:SetAttribute("SkeletonMarkedMult", mult)
    victim:SetAttribute("SkeletonMarkedExpiry", tick() + dur)
    -- VFXRemote:FireAllClients("SkeletonMarkApplied", victim.HumanoidRootPart.Position)
end

-- Called by damage pipeline: returns final multiplier for Skeleton vs this victim
function Skeleton_PerfectAimProtocol.GetMarkMult(victim)
    if not victim:GetAttribute("SkeletonMarked") then return 1.0 end
    if tick() > (victim:GetAttribute("SkeletonMarkedExpiry") or 0) then
        victim:SetAttribute("SkeletonMarked", false)
        return 1.0
    end
    return victim:GetAttribute("SkeletonMarkedMult") or 1.0
end

return Skeleton_PerfectAimProtocol
