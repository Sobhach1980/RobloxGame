--[[
    Zombie_InfectionSpread.lua
    Ultimate Ability 1 (Q): Infection Spread
    Character: Zombie | Form: Relentless Hunger

    Description:
      Zombie releases a massive infection burst that instantly infects ALL
      enemies within a large radius. Each infected player takes 10 dmg/s
      for 5 s and has 30% reduced healing. If any infected player dies
      during this period, a new zombie minion spawns at their location.

    Values:
      Cooldown (within ult) : 10.0 s
      Burst radius          : 18 studs
      Infection DPS         : 10  |  Duration: 5 s
      Healing reduction     : 30%
      Death spawn           : 1 zombie minion on kill
      VFX                   : massive green toxic burst, infection glow on all
                              affected targets, green haze fills arena
--]]

local HitboxSystem     = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun          = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)
local ZombieHorde      = require(script.Parent.Zombie_ZombieHorde)

local Zombie_InfectionSpread = {}

local COOLDOWN    = 10.0
local RADIUS      = 18
local INFECT_DPS  = 10
local INFECT_DUR  = 5.0
local HEAL_REDUCE = 0.70   -- multiplier (30% reduction)

function Zombie_InfectionSpread.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("InfectionSpread") then return end
    if not cooldowns:Start("InfectionSpread", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- AnimHelper.Play(character, "rbxassetid://ZOMBIE_INFECTIONSPREAD_BURST")
    -- VFXRemote:FireAllClients("ZombieInfectionSpread", rootPart.Position, RADIUS)
    -- CameraShakeRemote:FireAllClients("medium", rootPart.Position, 25)

    local center = rootPart.Position

    HitboxSystem.SpawnAoE({
        Position = center,
        Radius   = RADIUS,
        Attacker = character,
        OnHit    = function(victim)
            Zombie_InfectionSpread._applyMassInfect(victim, character)
        end,
    })
end

function Zombie_InfectionSpread._applyMassInfect(victim, owner)
    local humanoid = victim:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if victim:GetAttribute("ZombieMassInfectActive") then return end

    victim:SetAttribute("ZombieMassInfectActive", true)
    victim:SetAttribute("ZombieMassInfectHealMult", HEAL_REDUCE)

    -- VFX: green glow on victim
    -- VFXRemote:FireAllClients("ZombieMassInfect", victim.HumanoidRootPart.Position)

    local elapsed   = 0
    local prevHealth = humanoid.Health
    local conn

    conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not humanoid.Parent then conn:Disconnect() return end
        elapsed = elapsed + dt

        if elapsed >= INFECT_DUR then
            conn:Disconnect()
            victim:SetAttribute("ZombieMassInfectActive", false)
            victim:SetAttribute("ZombieMassInfectHealMult", 1)
            return
        end

        -- Tick damage every second
        if math.floor(elapsed) > math.floor(elapsed - dt) then
            if humanoid.Health <= 0 then
                conn:Disconnect()
                return
            end
            humanoid:TakeDamage(INFECT_DPS)

            -- On kill: spawn minion
            if humanoid.Health <= 0 then
                local vRoot = victim:FindFirstChild("HumanoidRootPart")
                if vRoot then
                    ZombieHorde._runMinion(owner, vRoot.Position, function() end)
                end
            end
        end
    end)
end

return Zombie_InfectionSpread
