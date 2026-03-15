--[[
    Alex_EnderShift.lua
    Ability: Ender Shift (F)
    Character: Alex

    Description:
      Alex briefly phases through ender energy and teleports to the target
      location (aimed via reticle or toward crosshair direction). On arrival
      she emits a small AoE ender burst that deals light damage and knocks
      back nearby enemies. If Advancement is active, teleport distance is
      doubled and the burst radius is expanded.

    Values:
      Cooldown        : 8.5 s
      Base range      : 16 studs (Advancement: 32)
      Burst radius    : 6 studs  (Advancement: 10)
      Burst damage    : 15
      StunType        : light
      KnockbackForce  : 35 (radial)
      I-frames during teleport: 0.12 s
      VFX             : ender particle dissolve at origin, materialise at dest,
                        end portal fragment burst on arrival
--]]

local HitboxSystem    = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun         = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)
local AlexAdvancement = require(script.Parent.Alex_Advancement)

local Alex_EnderShift = {}

local COOLDOWN        = 8.5
local BASE_RANGE      = 16
local ADV_RANGE       = 32
local BASE_BURST_R    = 6
local ADV_BURST_R     = 10
local BURST_DAMAGE    = 15
local KB_FORCE        = 35
local INVINCE_DUR     = 0.12

function Alex_EnderShift.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("EnderShift") then return end
    if not cooldowns:Start("EnderShift", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local advActive = AlexAdvancement.IsActive(character)
    local range     = advActive and ADV_RANGE or BASE_RANGE
    local burstR    = advActive and ADV_BURST_R or BASE_BURST_R
    if advActive then AlexAdvancement.Consume(character) end

    -- Determine teleport destination (raycast forward)
    local origin  = rootPart.Position
    local forward = rootPart.CFrame.LookVector

    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {character}
    rp.FilterType = Enum.RaycastFilterType.Exclude

    local result  = workspace:Raycast(origin, forward * range, rp)
    local destPos = result and (result.Position - forward * 2) or (origin + forward * range)

    -- VFX: dissolve at origin
    -- VFXRemote:FireAllClients("AlexEnderShiftOut", origin)

    -- Brief i-frames
    character:SetAttribute("EnderShiftInvincible", true)

    -- Teleport
    local cf = rootPart.CFrame
    rootPart.CFrame = CFrame.new(destPos) * (cf - cf.Position)

    -- VFX: materialise at destination
    -- VFXRemote:FireAllClients("AlexEnderShiftIn", destPos, advActive)

    -- Burst AoE on arrival
    HitboxSystem.SpawnAoE({
        Position = destPos,
        Radius   = burstR,
        Attacker = character,
        OnHit    = function(victim)
            local vRoot    = victim:FindFirstChild("HumanoidRootPart")
            local blastDir = vRoot and (vRoot.Position - destPos).Unit or Vector3.new(0,1,0)
            HitStun.Apply(victim, {
                Damage         = BURST_DAMAGE,
                StunType       = "light",
                KnockbackForce = KB_FORCE,
                KnockbackDir   = blastDir,
            })
        end,
    })

    task.delay(INVINCE_DUR, function()
        character:SetAttribute("EnderShiftInvincible", false)
    end)
end

return Alex_EnderShift
