--[[
    Zombie_UndeadSlash.lua
    Ability: Undead Slash (Q)
    Character: Zombie

    Description:
      A vicious claw double-swipe that deals high damage. The second hit
      applies "Bleeding" — the victim loses 5 HP/s for 3 seconds and has
      their healing effects reduced by 50% during that time.

    Values:
      Cooldown        : 6.0 s
      Hit 1 damage    : 20  |  StunType: medium
      Hit 2 damage    : 28  |  StunType: heavy  |  applies Bleeding
      Bleeding        : 5 dmg/s for 3 s, -50% healing received
      Hitbox Size     : 7 x 5 x 6
      Move lock       : 0.55 s
      VFX             : claw gash arcs, decay mist trail, green bleed proc
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Zombie_UndeadSlash = {}

local COOLDOWN     = 6.0
local BLEED_DPS    = 5
local BLEED_DUR    = 3.0
local HITBOX_SIZE  = Vector3.new(7, 5, 6)

local HITS = {
    { delay=0.0,  damage=20, stunType="medium", kbForce=0,  bleed=false },
    { delay=0.28, damage=28, stunType="heavy",  kbForce=40, bleed=true  },
}

function Zombie_UndeadSlash.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("UndeadSlash") then return end
    if not cooldowns:Start("UndeadSlash", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    movementSystem:LockMovement(0.60)

    for _, hit in ipairs(HITS) do
        task.delay(hit.delay, function()
            if not rootPart.Parent then return end

            -- AnimHelper.Play(character, "rbxassetid://ZOMBIE_UNDEADSLASH_" .. _)
            local hitboxPos = rootPart.CFrame:PointToWorldSpace(Vector3.new(0, 0, -3.5))
            local slashDir  = rootPart.CFrame.LookVector

            -- VFX: claw arc
            -- VFXRemote:FireAllClients("ZombieUndeadSlash", hitboxPos, hit.bleed)

            HitboxSystem.SpawnMeleeHitbox({
                Position = hitboxPos,
                Size     = HITBOX_SIZE,
                Duration = 0.14,
                Attacker = character,
                OnHit    = function(victim)
                    HitStun.Apply(victim, {
                        Damage         = hit.damage,
                        StunType       = hit.stunType,
                        KnockbackForce = hit.kbForce,
                        KnockbackDir   = slashDir,
                    })

                    if hit.bleed then
                        Zombie_UndeadSlash._applyBleed(victim)
                    end
                end,
            })
        end)
    end
end

function Zombie_UndeadSlash._applyBleed(victim)
    -- Prevent bleed stacking (refresh instead)
    if victim:GetAttribute("ZombieBleedActive") then return end

    victim:SetAttribute("ZombieBleedActive", true)
    victim:SetAttribute("ZombieBleedHealReduction", 0.5)

    local elapsed = 0
    local humanoid = victim:FindFirstChildOfClass("Humanoid")
    local conn

    conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not humanoid or not humanoid.Parent then
            conn:Disconnect()
            return
        end
        elapsed = elapsed + dt
        if elapsed >= BLEED_DUR then
            conn:Disconnect()
            victim:SetAttribute("ZombieBleedActive", false)
            victim:SetAttribute("ZombieBleedHealReduction", 0)
            -- VFXRemote:FireAllClients("ZombieBleedEnd", victim.HumanoidRootPart.Position)
            return
        end
        -- Tick damage every 1 s
        if math.floor(elapsed) > math.floor(elapsed - dt) then
            humanoid:TakeDamage(BLEED_DPS)
        end
    end)

    -- VFX: green bleed proc on victim
    -- VFXRemote:FireAllClients("ZombieBleedStart", victim.HumanoidRootPart.Position)
end

return Zombie_UndeadSlash
