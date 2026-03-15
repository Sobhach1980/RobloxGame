--[[
    Steve_Advancement.lua
    Ability: Advancement (E)
    Character: Steve

    Description:
      Steve charges forward with his sword levelled, dealing moderate damage
      to the first enemy hit and sending them airborne. Scales toward an
      iron-state power surge as Steve's match progression increases.
      NOTE: This is Steve's unique Advancement — different values, arc, and
      combat purpose from Alex's Advancement.

    Values:
      Cooldown        : 8.0 s
      Charge distance : 14 studs
      Charge speed    : 80 (burst velocity)
      Damage          : 22
      StunType        : launcher
      KnockbackForce  : 48
      Move lock       : 0.45 s
      VFX             : forward sword charge trail, black smoke burst
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Steve_Advancement = {}

local COOLDOWN       = 8.0
local CHARGE_SPEED   = 80
local CHARGE_DIST    = 14
local DAMAGE         = 22
local STUN_TYPE      = "launcher"
local KB_FORCE       = 48
local MOVE_LOCK      = 0.45
local HITBOX_SIZE    = Vector3.new(5, 5, 6)

function Steve_Advancement.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("Advancement") then return end
    if not cooldowns:Start("Advancement", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Lock movement during charge
    movementSystem:LockMovement(MOVE_LOCK)

    -- Play charge animation
    -- AnimHelper.Play(character, "rbxassetid://STEVE_ADVANCEMENT_CHARGE")

    -- Burst forward
    local chargeDir = rootPart.CFrame.LookVector
    rootPart.AssemblyLinearVelocity = chargeDir * CHARGE_SPEED

    -- VFX: sword trail, black smoke behind Steve
    -- VFXRemote:FireAllClients("SteveAdvancementCharge", rootPart.Position, chargeDir)

    local hit    = false
    local elapsed = 0
    local conn

    conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if hit or elapsed >= (CHARGE_DIST / CHARGE_SPEED) + 0.1 then
            conn:Disconnect()
            return
        end

        local hitboxPos = rootPart.CFrame:PointToWorldSpace(Vector3.new(0, 0, -3.5))
        HitboxSystem.SpawnMeleeHitbox({
            Position    = hitboxPos,
            Size        = HITBOX_SIZE,
            Duration    = dt,
            Attacker    = character,
            PierceCount = 1,
            OnHit       = function(victim)
                hit = true
                HitStun.Apply(victim, {
                    Damage         = DAMAGE,
                    StunType       = STUN_TYPE,
                    KnockbackForce = KB_FORCE,
                    KnockbackDir   = chargeDir,
                })
                -- VFXRemote:FireAllClients("SteveAdvancementHit", victim.HumanoidRootPart.Position)
            end,
        })
    end)
end

return Steve_Advancement
