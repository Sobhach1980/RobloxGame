--[[
    Zombie_ZombieHorde.lua
    Ability: Zombie Horde (R)
    Character: Zombie

    Description:
      Zombie summons 3 small zombie minions that spawn around him and
      charge toward the nearest enemy. Each minion has its own hitbox
      and persists for 8 seconds or until destroyed. Minions deal
      light melee damage and slow their targets. Zombie can summon
      additional hordes before the first expires (max 6 minions total).

    Values:
      Cooldown        : 14.0 s
      Minions spawned : 3
      Minion HP       : 40
      Minion damage   : 10 per hit  |  StunType: light
      Minion speed    : 12 (slower than players)
      Slow on hit     : 25% for 1.0 s
      Minion lifetime : 8 s
      Max total minions: 6
      VFX             : summoning gesture, ground rupture, 3 zombie minions rise,
                        decay mist from spawn points
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Zombie_ZombieHorde = {}

local COOLDOWN       = 14.0
local MINION_COUNT   = 3
local MINION_HP      = 40
local MINION_DAMAGE  = 10
local MINION_SPEED   = 12
local MINION_LIFE    = 8.0
local MAX_MINIONS    = 6
local SLOW_DUR       = 1.0
local SLOW_AMOUNT    = 0.75   -- multiplier (75% of base speed)
local ATTACK_RANGE   = 5
local ATTACK_COOLDOWN = 1.2

-- Track active minion count per character
local activeMinionCounts = {}

function Zombie_ZombieHorde.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("ZombieHorde") then return end
    if not cooldowns:Start("ZombieHorde", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local charId = tostring(character)
    activeMinionCounts[charId] = activeMinionCounts[charId] or 0

    -- Check max cap
    local canSpawn = math.min(MINION_COUNT, MAX_MINIONS - activeMinionCounts[charId])
    if canSpawn <= 0 then return end

    -- AnimHelper.Play(character, "rbxassetid://ZOMBIE_ZOMBIEHORDE_SUMMON")
    -- VFXRemote:FireAllClients("ZombieHordeSummon", rootPart.Position)

    local spawnOffsets = {
        Vector3.new(-4, 0, -2),
        Vector3.new(4, 0, -2),
        Vector3.new(0, 0, -5),
    }

    for i = 1, canSpawn do
        activeMinionCounts[charId] = activeMinionCounts[charId] + 1
        local spawnPos = rootPart.Position + spawnOffsets[i]

        -- VFX: ground crack, minion rises
        -- VFXRemote:FireAllClients("ZombieHordeMinionSpawn", spawnPos, i)

        -- Spawn minion as a simple NPC model (production: clone from ServerStorage)
        -- For behaviour logic we simulate with heartbeat AI
        Zombie_ZombieHorde._runMinion(character, spawnPos, function()
            activeMinionCounts[charId] = math.max(0, activeMinionCounts[charId] - 1)
        end)
    end
end

function Zombie_ZombieHorde._runMinion(owner, spawnPos, onDeath)
    -- In production: clone a pre-built minion model, parent it, run pathfinding.
    -- Stub AI loop using hitbox polling.

    local minionHP    = MINION_HP
    local alive       = true
    local elapsed     = 0
    local attackTimer = 0

    -- Simulate a small invisible hitbox representing the minion
    local minionPart = Instance.new("Part")
    minionPart.Name        = "ZombieMinion"
    minionPart.Size        = Vector3.new(3, 5, 3)
    minionPart.CFrame      = CFrame.new(spawnPos)
    minionPart.Transparency = 0.8
    minionPart.CanCollide  = false
    minionPart.Anchored    = false
    minionPart:SetAttribute("HittableTag", "Summon")
    minionPart:SetAttribute("MinionHP", minionHP)
    minionPart.Parent      = workspace

    -- VFX: attach minion visuals (production: full character model)
    -- VFXRemote:FireAllClients("ZombieMinionAppear", spawnPos)

    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not alive then conn:Disconnect() return end
        elapsed     = elapsed     + dt
        attackTimer = attackTimer + dt

        -- Lifetime check
        if elapsed >= MINION_LIFE then
            alive = false
            conn:Disconnect()
            if minionPart.Parent then minionPart:Destroy() end
            onDeath()
            return
        end

        -- HP check (damage applied via attribute by damage pipeline)
        local currentHP = minionPart:GetAttribute("MinionHP")
        if currentHP and currentHP <= 0 then
            alive = false
            conn:Disconnect()
            if minionPart.Parent then minionPart:Destroy() end
            -- VFXRemote:FireAllClients("ZombieMinionDeath", minionPart.Position)
            onDeath()
            return
        end

        -- Simple chase + attack AI
        if attackTimer >= ATTACK_COOLDOWN then
            attackTimer = 0
            HitboxSystem.SpawnMeleeHitbox({
                Position    = minionPart.Position,
                Size        = Vector3.new(ATTACK_RANGE, 5, ATTACK_RANGE),
                Duration    = 0.10,
                Attacker    = owner,
                PierceCount = 1,
                OnHit       = function(victim)
                    local vHum = victim:FindFirstChildOfClass("Humanoid")
                    if vHum then
                        local prev = vHum.WalkSpeed
                        vHum.WalkSpeed = prev * SLOW_AMOUNT
                        task.delay(SLOW_DUR, function()
                            if vHum.Parent then vHum.WalkSpeed = prev end
                        end)
                    end
                    HitStun.Apply(victim, {
                        Damage         = MINION_DAMAGE,
                        StunType       = "light",
                        KnockbackForce = 10,
                        KnockbackDir   = (victim:FindFirstChild("HumanoidRootPart") and
                                         (victim.HumanoidRootPart.Position - minionPart.Position).Unit)
                                         or Vector3.new(0,0,-1),
                    })
                end,
            })
        end
    end)
end

return Zombie_ZombieHorde
