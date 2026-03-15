--[[
    AlexController.lua
    Character: Alex (Green Shirt Gal)
    Role: Agile utility fighter with redstone/ender tech and dragon ult.

    Base moveset:
      Q – Quarry Strike
      E – Advancement  (Alex-specific: utility-focused, different from Steve's)
      R – Redstone Pulse
      F – Ender Shift

    Ultimate: Dragon's Awakening
    Ult moveset (replaces base):
      Q – Enderbound Assault
      E – Redstone Overdrive
      R – Dragonfall Execution
--]]

local MovementSystem    = require(script.Parent.Parent.Parent.Shared.CombatEngine.MovementSystem)
local DashSystem        = require(script.Parent.Parent.Parent.Shared.CombatEngine.DashSystem)
local M1System          = require(script.Parent.Parent.Parent.Shared.CombatEngine.M1System)
local BlockParrySystem  = require(script.Parent.Parent.Parent.Shared.CombatEngine.BlockParrySystem)
local EvasiveSystem     = require(script.Parent.Parent.Parent.Shared.CombatEngine.EvasiveSystem)
local CooldownManager   = require(script.Parent.Parent.Parent.Shared.CombatEngine.CooldownManager)
local UltimateGaugeSystem = require(script.Parent.Parent.Parent.Shared.CombatEngine.UltimateGaugeSystem)
local UltimateTimerSystem = require(script.Parent.Parent.Parent.Shared.CombatEngine.UltimateTimerSystem)

local QuarryStrike        = require(script.Parent.Abilities.Alex_QuarryStrike)
local Advancement         = require(script.Parent.Abilities.Alex_Advancement)
local RedstonePulse       = require(script.Parent.Abilities.Alex_RedstonePulse)
local EnderShift          = require(script.Parent.Abilities.Alex_EnderShift)
local EnderboundAssault   = require(script.Parent.Abilities.Alex_EnderboundAssault)
local RedstoneOverdrive   = require(script.Parent.Abilities.Alex_RedstoneOverdrive)
local DragonFallExecution = require(script.Parent.Abilities.Alex_DragonFallExecution)

local AlexController = {}
AlexController.__index = AlexController

local ULT_DURATION = 28   -- Dragon's Awakening duration (seconds)

function AlexController.new(character)
    local self = setmetatable({}, AlexController)
    self.Character  = character
    self.IsAwakened = false

    self.Movement  = MovementSystem.new(character, "Alex")
    self.Dash      = DashSystem.new(character, "Alex", self.Movement)
    self.M1        = M1System.new(character, "Alex", self.Movement)
    self.Block     = BlockParrySystem.new(character, self.Movement)
    self.Evasive   = EvasiveSystem.new(character, "Alex", self.Movement)
    self.Cooldowns = CooldownManager.new()
    self.UltTimer  = UltimateTimerSystem.new()

    self.UltGauge  = UltimateGaugeSystem.new(function()
        -- HUDEvent:FireClient(player, "UltReady", true)
    end)
    self.UltGauge:StartPassive()

    self.Abilities = {
        base = {
            Q = QuarryStrike,
            E = Advancement,
            R = RedstonePulse,
            F = EnderShift,
        },
        ult = {
            Q = EnderboundAssault,
            E = RedstoneOverdrive,
            R = DragonFallExecution,
        },
    }

    self._heartbeat = game:GetService("RunService").Heartbeat:Connect(function(dt)
        self.Movement:Update(dt)
    end)

    return self
end

function AlexController:OnM1()        self.M1:Attack() end
function AlexController:OnDash(dir)   self.Dash:Dash(dir) end
function AlexController:OnBlockDown() self.Block:StartBlock() end
function AlexController:OnBlockUp()   self.Block:EndBlock() end
function AlexController:OnEvasive(d)  self.Evasive:Activate(d) end

function AlexController:OnAbility(slot)
    local set     = self.IsAwakened and self.Abilities.ult or self.Abilities.base
    local ability = set[slot]
    if ability then ability.Use(self.Character, self.Cooldowns, self.Movement) end
end

function AlexController:OnUltimate()
    if self.IsAwakened then return end
    if not self.UltGauge:Consume() then return end
    self:_activateUlt()
end

function AlexController:_activateUlt()
    self.IsAwakened = true
    self.Movement:LockMovement(3.0)

    -- Dragon's Awakening cinematic:
    --   orbit cam, dragon silhouette, purple pulse, dragon roar
    -- CinematicRemote:FireAllClients("AlexDragonAwakening", self.Character)
    -- VFXRemote:FireAllClients("AlexUltForm", self.Character, true)

    -- Ult passive: Alex gains increased air control + 15% speed
    local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        self._ultPrevSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = humanoid.WalkSpeed * 1.15
    end

    -- HUDEvent:FireClient(player, "UltActivated", "Alex", ULT_DURATION)

    self.UltTimer:Start(ULT_DURATION,
        function(timeLeft, ratio)
            -- HUDEvent:FireClient(player, "UltTick", timeLeft, ratio)
        end,
        function()
            self:_revertUlt()
        end
    )
end

function AlexController:_revertUlt()
    self.IsAwakened = false
    local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and self._ultPrevSpeed then
        humanoid.WalkSpeed = self._ultPrevSpeed
    end
    -- VFXRemote:FireAllClients("AlexUltForm", self.Character, false)
    -- HUDEvent:FireClient(player, "UltReverted", "Alex")
    self.UltGauge:EndUlt()
end

function AlexController:OnHitReceived(attacker, damage, config)
    if self.Evasive:IsCurrentlyInvincible() then return 0 end
    local finalDamage = self.Block:OnHitReceived(attacker, damage, config)
    self.UltGauge:OnDamageTaken(finalDamage)
    return finalDamage
end

function AlexController:OnDamageDealt(amount)
    self.UltGauge:OnDamageDealt(amount)
end

function AlexController:Destroy()
    self.UltTimer:Stop()
    self.UltGauge:StopPassive()
    if self._heartbeat then self._heartbeat:Disconnect() end
end

return AlexController
