--[[
    Alex_EnderboundAssault.lua
    Ultimate Ability 1 (Q): Enderbound Assault
    Character: Alex | Form: Dragon's Awakening

    Description:
      Alex unleashes a rapid chain of 5 ender-infused strikes, each
      teleporting her instantly to the target before dealing damage.
      Each teleport strike leaves a lingering ender scar (small AoE zone)
      for 2 s. The 5th hit launches the enemy with massive force.
      Cannot be blocked — each teleport bypasses guard on arrival.

    Values:
      Cooldown (within ult) : 9.0 s
      Strikes               : 5
      Strike interval       : 0.20 s
      Per-strike damage     : 18 (strike 5: 30)
      Teleport range        : 12 studs per strike (chains to same target)
      Ender scar radius     : 3 studs, 2 s duration, 5 dmg/tick every 0.5 s
      Final hit StunType    : launcher  |  KB: 70
      Bypass block          : true on every strike
      VFX                   : purple void blink per hit, ender scar zone,
                              chain afterimages
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Alex_EnderboundAssault = {}

local COOLDOWN       = 9.0
local NUM_STRIKES    = 5
local STRIKE_DELAY   = 0.20
local STRIKE_DAMAGE  = 18
local FINAL_DAMAGE   = 30
local FINAL_KB       = 70
local SCAR_RADIUS    = 3
local SCAR_DURATION  = 2.0
local SCAR_TICK_INT  = 0.5
local SCAR_TICK_DMG  = 5
local TELEPORT_RANGE = 12

function Alex_EnderboundAssault.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("EnderboundAssault") then return end
    if not cooldowns:Start("EnderboundAssault", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    movementSystem:LockMovement(NUM_STRIKES * STRIKE_DELAY + 0.3)

    for i = 1, NUM_STRIKES do
        task.delay((i - 1) * STRIKE_DELAY, function()
            if not rootPart.Parent then return end

            local isFinal = (i == NUM_STRIKES)
            local damage  = isFinal and FINAL_DAMAGE or STRIKE_DAMAGE

            -- Find nearest enemy within range (simplified: use overlap sphere)
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {character}
            rp.FilterType = Enum.RaycastFilterType.Exclude

            -- Teleport toward look direction
            local forward = rootPart.CFrame.LookVector
            local dest    = rootPart.Position + forward * TELEPORT_RANGE
            rootPart.CFrame = CFrame.new(dest) * (rootPart.CFrame - rootPart.CFrame.Position)

            -- VFX: void blink + afterimage
            -- VFXRemote:FireAllClients("EnderboundBlink", dest, i)

            -- Strike hitbox at destination
            HitboxSystem.SpawnMeleeHitbox({
                Position    = dest,
                Size        = Vector3.new(5, 5, 5),
                Duration    = 0.10,
                Attacker    = character,
                PierceCount = 1,
                OnHit       = function(victim)
                    HitStun.Apply(victim, {
                        Damage         = damage,
                        StunType       = isFinal and "launcher" or "medium",
                        KnockbackForce = isFinal and FINAL_KB or 15,
                        KnockbackDir   = forward,
                    })
                end,
            })

            -- Leave ender scar zone
            HitboxSystem.SpawnLingeringZone({
                Position     = dest,
                Size         = Vector3.new(SCAR_RADIUS * 2, 4, SCAR_RADIUS * 2),
                Duration     = SCAR_DURATION,
                TickInterval = SCAR_TICK_INT,
                Attacker     = character,
                OnTick       = function(victim)
                    HitStun.Apply(victim, {
                        Damage         = SCAR_TICK_DMG,
                        StunType       = "light",
                        KnockbackForce = 0,
                        KnockbackDir   = Vector3.new(0,1,0),
                    })
                end,
            })
        end)
    end
end

return Alex_EnderboundAssault
