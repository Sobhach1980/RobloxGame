--[[
    ZombieController.lua
    Character: Zombie (Undead Blue Shirt Guy)
    Role: Heavy brawler. Slow, relentless, high damage. Infection mechanic.

    Base moveset:
      Q – Undead Slash
      E – Zombie Plague
      R – Zombie Horde
      F – Decay Wave

    Ultimate: Relentless Hunger
    Ult moveset (replaces base):
      Q – Infection Spread
      E – Grave March
      R – Relentless Hunger
--]]

local MovementSystem    = require(script.Parent.Parent.Parent.Shared.CombatEngine.MovementSystem)
local DashSystem        = require(script.Parent.Parent.Parent.Shared.CombatEngine.DashSystem)
local M1System          = require(script.Parent.Parent.Parent.Shared.CombatEngine.M1System)
local BlockParrySystem  = require(script.Parent.Parent.Parent.Shared.CombatEngine.BlockParrySystem)
local EvasiveSystem     = require(script.Parent.Parent.Parent.Shared.CombatEngine.EvasiveSystem)
local CooldownManager   = require(script.Parent.Parent.Parent.Shared.CombatEngine.CooldownManager)
local UltimateGaugeSystem = require(script.Parent.Parent.Parent.Shared.CombatEngine.UltimateGaugeSystem)
local UltimateTimerSystem = require(script.Parent.Parent.Parent.Shared.CombatEngine.UltimateTimerSystem)

local UndeadSlash     = require(script.Parent.Abilities.Zombie_UndeadSlash)
local ZombiePlague    = require(script.Parent.Abilities.Zombie_ZombiePlague)
local ZombieHorde     = require(script.Parent.Abilities.Zombie_ZombieHorde)
local DecayWave       = require(script.Parent.Abilities.Zombie_DecayWave)
local InfectionSpread = require(script.Parent.Abilities.Zombie_InfectionSpread)
local GraveMarch      = require(script.Parent.Abilities.Zombie_GraveMarch)
local RelentlessHunger = require(script.Parent.Abilities.Zombie_RelentlessHunger)

local ZombieController = {}
ZombieController.__index = ZombieController

local ULT_DURATION = 25

function ZombieController.new(character)
    local self = setmetatable({}, ZombieController)
    self.Character  = character
    self.IsAwakened = false

    self.Movement  = MovementSystem.new(character, "Zombie")
    self.Dash      = DashSystem.new(character, "Zombie", self.Movement)
    self.M1        = M1System.new(character, "Zombie", self.Movement)
    self.Block     = BlockParrySystem.new(character, self.Movement)
    self.Evasive   = EvasiveSystem.new(character, "Zombie", self.Movement)
    self.Cooldowns = CooldownManager.new()
    self.UltTimer  = UltimateTimerSystem.new()

    self.UltGauge  = UltimateGaugeSystem.new(function()
        -- HUDEvent:FireClient(player, "UltReady", true)
    end)
    self.UltGauge:StartPassive()

    self.Abilities = {
        base = {
            Q = UndeadSlash,
            E = ZombiePlague,
            R = ZombieHorde,
            F = DecayWave,
        },
        ult = {
            Q = InfectionSpread,
            E = GraveMarch,
            R = RelentlessHunger,
        },
    }

    self._heartbeat = game:GetService("RunService").Heartbeat:Connect(function(dt)
        self.Movement:Update(dt)
    end)

    return self
end

function ZombieController:OnM1()        self.M1:Attack() end
function ZombieController:OnDash(dir)   self.Dash:Dash(dir) end
function ZombieController:OnBlockDown() self.Block:StartBlock() end
function ZombieController:OnBlockUp()   self.Block:EndBlock() end
function ZombieController:OnEvasive(d)  self.Evasive:Activate(d) end

function ZombieController:OnAbility(slot)
    local set     = self.IsAwakened and self.Abilities.ult or self.Abilities.base
    local ability = set[slot]
    if ability then ability.Use(self.Character, self.Cooldowns, self.Movement) end
end

function ZombieController:OnUltimate()
    if self.IsAwakened then return end
    if not self.UltGauge:Consume() then return end
    self:_activateUlt()
end

function ZombieController:_activateUlt()
    self.IsAwakened = true
    self.Movement:LockMovement(2.0)

    -- Relentless Hunger cinematic:
    --   Zombie lurches forward, eyes glow bright green, decay mist erupts,
    --   screen distorts, infection particles fill the arena
    -- CinematicRemote:FireAllClients("ZombieRelentlessHungerCinematic", self.Character)
    -- VFXRemote:FireAllClients("ZombieUltForm", self.Character, true)

    -- Ult passive: Zombie takes 20% less damage and has increased
    -- movement speed (+4 WalkSpeed) while hungry
    local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        self._ultPrevSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = humanoid.WalkSpeed + 4
    end
    self._ultDamageMult = 0.80

    -- HUDEvent:FireClient(player, "UltActivated", "Zombie", ULT_DURATION)

    self.UltTimer:Start(ULT_DURATION,
        function(timeLeft, ratio)
            -- HUDEvent:FireClient(player, "UltTick", timeLeft, ratio)
        end,
        function()
            self:_revertUlt()
        end
    )
end

function ZombieController:_revertUlt()
    self.IsAwakened     = false
    self._ultDamageMult = 1.0
    local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and self._ultPrevSpeed then
        humanoid.WalkSpeed = self._ultPrevSpeed
    end
    -- VFXRemote:FireAllClients("ZombieUltForm", self.Character, false)
    -- HUDEvent:FireClient(player, "UltReverted", "Zombie")
    self.UltGauge:EndUlt()
end

function ZombieController:OnHitReceived(attacker, damage, config)
    if self.Evasive:IsCurrentlyInvincible() then return 0 end
    local finalDamage = self.Block:OnHitReceived(attacker, damage, config)
    if self.IsAwakened and self._ultDamageMult then
        finalDamage = math.ceil(finalDamage * self._ultDamageMult)
    end
    self.UltGauge:OnDamageTaken(finalDamage)
    return finalDamage
end

function ZombieController:OnDamageDealt(amount)
    self.UltGauge:OnDamageDealt(amount)
end

function ZombieController:Destroy()
    self.UltTimer:Stop()
    self.UltGauge:StopPassive()
    if self._heartbeat then self._heartbeat:Disconnect() end
end

return ZombieController
