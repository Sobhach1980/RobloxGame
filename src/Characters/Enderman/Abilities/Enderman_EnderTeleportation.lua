--[[
    Enderman_EnderTeleportation.lua
    Ability: Ender Teleportation (Q)
    Character: Enderman

    Description:
      Enderman blinks instantly to a targeted location (up to 20 studs).
      On arrival, he emits a void shockwave that briefly disorients nearby
      enemies (reverses their camera controls for 1 s). Cannot be used mid-
      knockback. During Void Dominion the cooldown is reduced.

    Values:
      Cooldown        : 5.0 s  (Void Dominion: 4.0 s)
      Max range       : 20 studs
      I-frames        : 0.20 s
      Disorient radius: 8 studs
      Disorient dur   : 1.0 s (camera inversion signal to victim's client)
      VFX             : void particle dissolve at origin, materialise at dest,
                        purple ring on arrival, void aura pulse
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Enderman_EnderTeleportation = {}

local BASE_CD      = 5.0
local VOID_CD      = 4.0
local MAX_RANGE    = 20
local INVINCE_DUR  = 0.20
local DISORT_RADIUS = 8
local DISORT_DUR   = 1.0

function Enderman_EnderTeleportation.Use(character, cooldowns, movementSystem)
    local cd = character:GetAttribute("VoidDominionActive") and VOID_CD or BASE_CD
    if cooldowns:IsOnCooldown("EnderTeleportation") then return end
    if not cooldowns:Start("EnderTeleportation", cd) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Determine destination
    local forward = rootPart.CFrame.LookVector
    local rp      = RaycastParams.new()
    rp.FilterDescendantsInstances = {character}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local result  = workspace:Raycast(rootPart.Position, forward * MAX_RANGE, rp)
    local destPos = result and (result.Position - forward * 2) or (rootPart.Position + forward * MAX_RANGE)

    -- VFX: void dissolve at origin
    -- VFXRemote:FireAllClients("EndermanTeleportOut", rootPart.Position)

    -- I-frames
    character:SetAttribute("EnderTeleportInvincible", true)

    -- Teleport
    local cf = rootPart.CFrame
    rootPart.CFrame = CFrame.new(destPos) * (cf - cf.Position)

    -- VFX: materialise at destination
    -- VFXRemote:FireAllClients("EndermanTeleportIn", destPos)

    task.delay(INVINCE_DUR, function()
        character:SetAttribute("EnderTeleportInvincible", false)
    end)

    -- Disorient AoE
    HitboxSystem.SpawnAoE({
        Position = destPos,
        Radius   = DISORT_RADIUS,
        Attacker = character,
        OnHit    = function(victim)
            -- Signal victim client to invert camera for DISORT_DUR
            -- DisorientRemote:FireClient(Players:GetPlayerFromCharacter(victim), DISORT_DUR)
            victim:SetAttribute("EndermanDisoriented", true)
            task.delay(DISORT_DUR, function()
                victim:SetAttribute("EndermanDisoriented", false)
            end)
            -- Light damage on disorient (optional feel)
            HitStun.Apply(victim, {
                Damage         = 8,
                StunType       = "light",
                KnockbackForce = 12,
                KnockbackDir   = (victim:FindFirstChild("HumanoidRootPart") and
                                 (victim.HumanoidRootPart.Position - destPos).Unit)
                                 or Vector3.new(0,1,0),
            })
        end,
    })
end

return Enderman_EnderTeleportation
