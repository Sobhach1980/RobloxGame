--[[
    Zombie_RelentlessHunger.lua
    Ultimate Ability 3 (R): Relentless Hunger
    Character: Zombie | Form: Relentless Hunger

    Description:
      The ultimate finisher. Zombie locks onto the nearest enemy and
      performs a devastating lunge-bite sequence — 3 rapid bites, each
      healing Zombie for the damage dealt. The final bite deals massive
      damage and drains any remaining infection effects, converting
      all active infection ticks into an instant burst of damage.

    Values:
      Cooldown (within ult) : 16.0 s
      Lock range            : 20 studs
      Bite count            : 3
      Bite interval         : 0.30 s
      Bite 1 & 2 damage     : 25  |  StunType: medium  |  Lifesteal: 50%
      Bite 3 damage         : 45  |  StunType: heavy   |  Lifesteal: 100%
      Infection drain       : all active infection ticks converted to instant dmg
      Move lock             : 1.2 s
      VFX                   : lunge animation, red bite flash, lifesteal drain
                              visual, infection purge burst
      Camera                : medium shake on bite 3
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Zombie_RelentlessHunger = {}

local COOLDOWN    = 16.0
local LOCK_RANGE  = 20
local BITES       = {
    { delay=0.0,  damage=25, stunType="medium", lifesteal=0.50 },
    { delay=0.30, damage=25, stunType="medium", lifesteal=0.50 },
    { delay=0.60, damage=45, stunType="heavy",  lifesteal=1.00, final=true },
}
local MOVE_LOCK   = 1.2

function Zombie_RelentlessHunger.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("RelentlessHunger") then return end
    if not cooldowns:Start("RelentlessHunger", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    -- Find nearest enemy
    local target, targetRoot = Zombie_RelentlessHunger._findNearest(character, rootPart, LOCK_RANGE)
    if not target or not targetRoot then return end

    movementSystem:LockMovement(MOVE_LOCK)

    -- Lunge toward target
    local lungeDir = (targetRoot.Position - rootPart.Position).Unit
    rootPart.AssemblyLinearVelocity = lungeDir * 60

    -- AnimHelper.Play(character, "rbxassetid://ZOMBIE_RELENTLESSHUNGER_LUNGE")
    -- VFXRemote:FireAllClients("ZombieRelentlessHungerLunge", rootPart.Position, lungeDir)

    for _, bite in ipairs(BITES) do
        task.delay(bite.delay, function()
            if not rootPart.Parent or not targetRoot.Parent then return end

            -- AnimHelper.Play(character, "rbxassetid://ZOMBIE_BITE_" .. _)
            -- VFXRemote:FireAllClients("ZombieRelentlessHungerBite", targetRoot.Position, bite.final)

            if bite.final then
                -- Camera: medium shake on final bite
                -- CameraShakeRemote:FireAllClients("medium", targetRoot.Position, 20)

                -- Drain infection: convert remaining ticks to instant burst
                if target:GetAttribute("ZombieBleedActive") or target:GetAttribute("ZombiePlagueInfected") then
                    local burstDmg = 30
                    local tHum = target:FindFirstChildOfClass("Humanoid")
                    if tHum then tHum:TakeDamage(burstDmg) end
                    humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + burstDmg * bite.lifesteal)
                    target:SetAttribute("ZombieBleedActive", false)
                    target:SetAttribute("ZombiePlagueInfected", false)
                    -- VFXRemote:FireAllClients("ZombieInfectionDrain", targetRoot.Position)
                end
            end

            HitboxSystem.SpawnMeleeHitbox({
                Position    = targetRoot.Position,
                Size        = Vector3.new(5, 5, 5),
                Duration    = 0.10,
                Attacker    = character,
                PierceCount = 1,
                OnHit       = function(victim)
                    HitStun.Apply(victim, {
                        Damage         = bite.damage,
                        StunType       = bite.stunType,
                        KnockbackForce = bite.final and 50 or 15,
                        KnockbackDir   = lungeDir,
                    })
                    -- Lifesteal
                    humanoid.Health = math.min(
                        humanoid.MaxHealth,
                        humanoid.Health + bite.damage * bite.lifesteal
                    )
                    -- VFXRemote:FireAllClients("ZombieLifesteal", rootPart.Position, bite.damage * bite.lifesteal)
                end,
            })
        end)
    end
end

function Zombie_RelentlessHunger._findNearest(character, rootPart, range)
    local nearest    = nil
    local nearestRoot = nil
    local nearestDist = range + 1

    for _, model in ipairs(workspace:GetChildren()) do
        if model ~= character and model:IsA("Model") then
            local hum  = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                local dist = (root.Position - rootPart.Position).Magnitude
                if dist < nearestDist then
                    nearestDist  = dist
                    nearest      = model
                    nearestRoot  = root
                end
            end
        end
    end

    return nearest, nearestRoot
end

return Zombie_RelentlessHunger
