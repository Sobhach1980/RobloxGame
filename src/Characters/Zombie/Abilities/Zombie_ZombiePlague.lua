--[[
    Zombie_ZombiePlague.lua
    Ability: Zombie Plague (E)
    Character: Zombie

    Description:
      Zombie vomits a plague cloud forward that infects the first enemy
      hit. Infection deals 8 damage per second for 4 seconds and, if the
      infected target hits another player within the duration, that player
      also becomes infected (chain infection, max 2 chains).

    Values:
      Cooldown        : 11.0 s
      Cloud range     : 14 studs
      Cloud hitbox    : 5 stud radius sphere (slow-moving)
      Cloud speed     : 18
      Infection DPS   : 8  |  Duration: 4 s
      Chain limit     : 2 additional players infected per cast
      VFX             : green vomit cloud projectile, wet corruption SFX,
                        green glow on infected targets, chain arc on spread
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Zombie_ZombiePlague = {}

local COOLDOWN     = 11.0
local CLOUD_SPEED  = 18
local CLOUD_RANGE  = 14
local CLOUD_RADIUS = 5
local INFECT_DPS   = 8
local INFECT_DUR   = 4.0
local MAX_CHAINS   = 2

function Zombie_ZombiePlague.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("ZombiePlague") then return end
    if not cooldowns:Start("ZombiePlague", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- AnimHelper.Play(character, "rbxassetid://ZOMBIE_ZOMBIEPLAGUE_VOMIT")
    local fireDir = rootPart.CFrame.LookVector + Vector3.new(0, 0.1, 0)
    local origin  = rootPart.Position + Vector3.new(0, 0.5, 0)

    -- VFX: cloud spawns
    -- VFXRemote:FireAllClients("ZombiePlagueCloud", origin, fireDir)

    HitboxSystem.SpawnProjectile({
        Origin       = origin,
        Direction    = fireDir,
        Speed        = CLOUD_SPEED,
        MaxRange     = CLOUD_RANGE,
        HitboxRadius = CLOUD_RADIUS,
        Attacker     = character,
        Gravity      = 5,
        OnHit        = function(victim, hitPos)
            Zombie_ZombiePlague._infect(victim, character, MAX_CHAINS, 0)
        end,
        OnExpire = function()
            -- VFX: cloud dissipates
        end,
    })
end

function Zombie_ZombiePlague._infect(victim, originalAttacker, chainsLeft, depth)
    local humanoid = victim:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if victim:GetAttribute("ZombiePlagueInfected") then return end

    victim:SetAttribute("ZombiePlagueInfected", true)
    victim:SetAttribute("ZombiePlagueChains", chainsLeft)

    -- VFX: green glow on victim
    -- VFXRemote:FireAllClients("ZombiePlagueInfect", victim.HumanoidRootPart.Position, depth)

    local elapsed = 0
    local conn

    conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not humanoid.Parent then conn:Disconnect() return end
        elapsed = elapsed + dt
        if elapsed >= INFECT_DUR then
            conn:Disconnect()
            victim:SetAttribute("ZombiePlagueInfected", false)
            -- VFXRemote:FireAllClients("ZombiePlagueExpire", victim.HumanoidRootPart.Position)
            return
        end
        if math.floor(elapsed) > math.floor(elapsed - dt) then
            humanoid:TakeDamage(INFECT_DPS)
        end
    end)

    -- Chain infection: watch for victim dealing melee damage
    if chainsLeft > 0 then
        -- In production: hook into the victim's hit events
        -- For now, attribute signals the chain is live
        victim:SetAttribute("ZombiePlagueCanChain", true)
        task.delay(INFECT_DUR, function()
            victim:SetAttribute("ZombiePlagueCanChain", false)
        end)
    end
end

-- Called by the server damage pipeline when an infected player hits someone
function Zombie_ZombiePlague.TryChainInfect(infectedAttacker, victimHit)
    if not infectedAttacker:GetAttribute("ZombiePlagueCanChain") then return end
    local chainsLeft = infectedAttacker:GetAttribute("ZombiePlagueChains") or 0
    if chainsLeft <= 0 then return end

    infectedAttacker:SetAttribute("ZombiePlagueCanChain", false)
    infectedAttacker:SetAttribute("ZombiePlagueChains", chainsLeft - 1)

    -- VFX: chain arc between players
    -- VFXRemote:FireAllClients("ZombiePlagueChain", infectedAttacker.HumanoidRootPart.Position, victimHit.HumanoidRootPart.Position)

    Zombie_ZombiePlague._infect(victimHit, nil, chainsLeft - 1, 1)
end

return Zombie_ZombiePlague
