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

local RunService = game:GetService("RunService")

local MovementSystem      = require(script.Parent.Parent.Parent.Shared.CombatEngine.MovementSystem)
local DashSystem          = require(script.Parent.Parent.Parent.Shared.CombatEngine.DashSystem)
local M1System            = require(script.Parent.Parent.Parent.Shared.CombatEngine.M1System)
local BlockParrySystem    = require(script.Parent.Parent.Parent.Shared.CombatEngine.BlockParrySystem)
local EvasiveSystem       = require(script.Parent.Parent.Parent.Shared.CombatEngine.EvasiveSystem)
local CooldownManager     = require(script.Parent.Parent.Parent.Shared.CombatEngine.CooldownManager)
local UltimateGaugeSystem = require(script.Parent.Parent.Parent.Shared.CombatEngine.UltimateGaugeSystem)
local UltimateTimerSystem = require(script.Parent.Parent.Parent.Shared.CombatEngine.UltimateTimerSystem)
local AnimationManager    = require(script.Parent.Parent.Parent.Shared.Animation.AnimationManager)
local UltActivatorSequence = require(script.Parent.Parent.Parent.Shared.Cinematic.UltActivatorSequence)
local VFXSystem           = require(script.Parent.Parent.Parent.Shared.VFX.VFXSystem)

local UndeadSlash      = require(script.Parent.Abilities.Zombie_UndeadSlash)
local ZombiePlague     = require(script.Parent.Abilities.Zombie_ZombiePlague)
local ZombieHorde      = require(script.Parent.Abilities.Zombie_ZombieHorde)
local DecayWave        = require(script.Parent.Abilities.Zombie_DecayWave)
local InfectionSpread  = require(script.Parent.Abilities.Zombie_InfectionSpread)
local GraveMarch       = require(script.Parent.Abilities.Zombie_GraveMarch)
local RelentlessHunger = require(script.Parent.Abilities.Zombie_RelentlessHunger)

local ZombieController = {}
ZombieController.__index = ZombieController

local ULT_DURATION = 25

function ZombieController.new(character, player, remotes)
    local self = setmetatable({}, ZombieController)
    self.Character  = character
    self.Player     = player
    self.Remotes    = remotes
    self.IsAwakened = false

    self.Movement  = MovementSystem.new(character, "Zombie")
    self.Dash      = DashSystem.new(character, "Zombie", self.Movement)
    self.M1        = M1System.new(character, "Zombie", self.Movement)
    self.Block     = BlockParrySystem.new(character, self.Movement)
    self.Evasive   = EvasiveSystem.new(character, "Zombie", self.Movement)
    self.Cooldowns = CooldownManager.new()
    self.UltTimer  = UltimateTimerSystem.new()
    self.Anim      = AnimationManager.new(character, "Zombie")

    self.UltGauge = UltimateGaugeSystem.new(function()
        remotes.HUDRemote:FireClient(player, "UltReady", true)
    end)
    self.UltGauge:StartPassive()

    -- Set by the match system to identify the opposing player.
    -- Used so the ult cutscene plays in full only for the opponent.
    self.OpponentPlayer = nil

    self.Abilities = {
        base = { Q = UndeadSlash, E = ZombiePlague, R = ZombieHorde, F = DecayWave },
        ult  = { Q = InfectionSpread, E = GraveMarch, R = RelentlessHunger },
    }

    self._heartbeat = RunService.Heartbeat:Connect(function(dt)
        self.Movement:Update(dt)
    end)

    return self
end

-- Called by the match system when a new opponent is assigned or cleared
function ZombieController:SetOpponent(player)
    self.OpponentPlayer = player
end

function ZombieController:OnM1()           self.M1:Attack() end
function ZombieController:OnDash(dir)      self.Dash:Dash(dir) end
function ZombieController:OnBlockDown()    self.Block:StartBlock() end
function ZombieController:OnBlockUp()      self.Block:EndBlock() end
function ZombieController:OnEvasive(d)     self.Evasive:Activate(d) end

function ZombieController:OnAbility(slot)
    local set     = self.IsAwakened and self.Abilities.ult or self.Abilities.base
    local ability = set[slot]
    if ability then ability.Use(self.Character, self.Cooldowns, self.Movement, self.Remotes, self.Anim) end
end

function ZombieController:OnUltimate()
    if self.IsAwakened then return end
    if not self.UltGauge:Consume() then return end
    self:_activateUlt()
end

function ZombieController:_activateUlt()
    self.IsAwakened     = true
    self._ultDamageMult = 0.80

    UltActivatorSequence.Activate({
        character      = self.Character,
        characterId    = "Zombie",
        animManager    = self.Anim,
        remotes        = self.Remotes,
        movementSystem = self.Movement,
        opponentPlayer = self.OpponentPlayer,
        onComplete     = function()
            VFXSystem.Fire("ZombieUltForm", self.Character, true)
            self.Remotes.HUDRemote:FireClient(self.Player, "UltActivated", "Zombie", ULT_DURATION)

            -- Ult passive: 20% damage reduction + +4 WalkSpeed
            local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                self._ultPrevSpeed = humanoid.WalkSpeed
                humanoid.WalkSpeed = humanoid.WalkSpeed + 4
            end

            self.UltTimer:Start(ULT_DURATION,
                function(timeLeft, ratio)
                    self.Remotes.HUDRemote:FireClient(self.Player, "UltTick", timeLeft, ratio)
                end,
                function()
                    self:_revertUlt()
                end
            )
        end,
    })
end

function ZombieController:_revertUlt()
    self.IsAwakened     = false
    self._ultDamageMult = 1.0

    local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and self._ultPrevSpeed then
        humanoid.WalkSpeed = self._ultPrevSpeed
    end

    VFXSystem.Fire("ZombieUltForm", self.Character, false)
    UltActivatorSequence.Revert({
        remotes     = self.Remotes,
        character   = self.Character,
        characterId = "Zombie",
    })

    self.Remotes.HUDRemote:FireClient(self.Player, "UltReverted", "Zombie")
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
