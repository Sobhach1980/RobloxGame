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

local QuarryStrike        = require(script.Parent.Abilities.Alex_QuarryStrike)
local Advancement         = require(script.Parent.Abilities.Alex_Advancement)
local RedstonePulse       = require(script.Parent.Abilities.Alex_RedstonePulse)
local EnderShift          = require(script.Parent.Abilities.Alex_EnderShift)
local EnderboundAssault   = require(script.Parent.Abilities.Alex_EnderboundAssault)
local RedstoneOverdrive   = require(script.Parent.Abilities.Alex_RedstoneOverdrive)
local DragonFallExecution = require(script.Parent.Abilities.Alex_DragonFallExecution)

local AlexController = {}
AlexController.__index = AlexController

local ULT_DURATION = 28

function AlexController.new(character, player, remotes)
    local self = setmetatable({}, AlexController)
    self.Character  = character
    self.Player     = player
    self.Remotes    = remotes
    self.IsAwakened = false

    self.Movement  = MovementSystem.new(character, "Alex")
    self.Dash      = DashSystem.new(character, "Alex", self.Movement)
    self.M1        = M1System.new(character, "Alex", self.Movement)
    self.Block     = BlockParrySystem.new(character, self.Movement)
    self.Evasive   = EvasiveSystem.new(character, "Alex", self.Movement)
    self.Cooldowns = CooldownManager.new()
    self.UltTimer  = UltimateTimerSystem.new()
    self.Anim      = AnimationManager.new(character, "Alex")

    self.UltGauge = UltimateGaugeSystem.new(function()
        remotes.HUDRemote:FireClient(player, "UltReady", true)
    end)
    self.UltGauge:StartPassive()

    -- Set by the match system to identify the opposing player.
    -- Used so the ult cutscene plays in full only for the opponent.
    self.OpponentPlayer = nil

    self.Abilities = {
        base = { Q = QuarryStrike, E = Advancement, R = RedstonePulse, F = EnderShift },
        ult  = { Q = EnderboundAssault, E = RedstoneOverdrive, R = DragonFallExecution },
    }

    self._heartbeat = RunService.Heartbeat:Connect(function(dt)
        self.Movement:Update(dt)
    end)

    return self
end

-- Called by the match system when a new opponent is assigned or cleared
function AlexController:SetOpponent(player)
    self.OpponentPlayer = player
end

function AlexController:OnM1()            self.M1:Attack() end
function AlexController:OnDash(dir)       self.Dash:Dash(dir) end
function AlexController:OnBlockDown()     self.Block:StartBlock() end
function AlexController:OnBlockUp()       self.Block:EndBlock() end
function AlexController:OnEvasive(d)      self.Evasive:Activate(d) end

function AlexController:OnAbility(slot)
    local set     = self.IsAwakened and self.Abilities.ult or self.Abilities.base
    local ability = set[slot]
    if ability then ability.Use(self.Character, self.Cooldowns, self.Movement, self.Remotes, self.Anim) end
end

function AlexController:OnUltimate()
    if self.IsAwakened then return end
    if not self.UltGauge:Consume() then return end
    self:_activateUlt()
end

function AlexController:_activateUlt()
    self.IsAwakened = true

    UltActivatorSequence.Activate({
        character      = self.Character,
        characterId    = "Alex",
        animManager    = self.Anim,
        remotes        = self.Remotes,
        movementSystem = self.Movement,
        opponentPlayer = self.OpponentPlayer,
        onComplete     = function()
            VFXSystem.Fire("AlexUltForm", self.Character, true)
            self.Remotes.HUDRemote:FireClient(self.Player, "UltActivated", "Alex", ULT_DURATION)

            -- Ult passive: +15% WalkSpeed
            local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                self._ultPrevSpeed = humanoid.WalkSpeed
                humanoid.WalkSpeed = humanoid.WalkSpeed * 1.15
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

function AlexController:_revertUlt()
    self.IsAwakened = false

    local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and self._ultPrevSpeed then
        humanoid.WalkSpeed = self._ultPrevSpeed
    end

    VFXSystem.Fire("AlexUltForm", self.Character, false)
    UltActivatorSequence.Revert({
        remotes     = self.Remotes,
        character   = self.Character,
        characterId = "Alex",
    })

    self.Remotes.HUDRemote:FireClient(self.Player, "UltReverted", "Alex")
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
