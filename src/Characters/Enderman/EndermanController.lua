--[[
    EndermanController.lua
    Character: Enderman (Tall Guy)
    Role: Elusive teleport fighter. Floaty, disorienting, void-based.

    Base moveset:
      Q – Ender Teleportation
      E – Ender Strike
      R – Ender Cloak
      F – Teleportation Slam

    Ultimate: Void Dominion
    Ult moveset (replaces base):
      Q – Voidstep Frenzy
      E – Stolen Ground
      R – You Shouldn't Look
--]]

local MovementSystem    = require(script.Parent.Parent.Parent.Shared.CombatEngine.MovementSystem)
local DashSystem        = require(script.Parent.Parent.Parent.Shared.CombatEngine.DashSystem)
local M1System          = require(script.Parent.Parent.Parent.Shared.CombatEngine.M1System)
local BlockParrySystem  = require(script.Parent.Parent.Parent.Shared.CombatEngine.BlockParrySystem)
local EvasiveSystem     = require(script.Parent.Parent.Parent.Shared.CombatEngine.EvasiveSystem)
local CooldownManager   = require(script.Parent.Parent.Parent.Shared.CombatEngine.CooldownManager)
local UltimateGaugeSystem = require(script.Parent.Parent.Parent.Shared.CombatEngine.UltimateGaugeSystem)
local UltimateTimerSystem = require(script.Parent.Parent.Parent.Shared.CombatEngine.UltimateTimerSystem)

local EnderTeleportation = require(script.Parent.Abilities.Enderman_EnderTeleportation)
local EnderStrike        = require(script.Parent.Abilities.Enderman_EnderStrike)
local EnderCloak         = require(script.Parent.Abilities.Enderman_EnderCloak)
local TeleportationSlam  = require(script.Parent.Abilities.Enderman_TeleportationSlam)
local VoidstepFrenzy     = require(script.Parent.Abilities.Enderman_VoidstepFrenzy)
local StolenGround       = require(script.Parent.Abilities.Enderman_StolenGround)
local YouShouldntLook    = require(script.Parent.Abilities.Enderman_YouShouldntLook)

local EndermanController = {}
EndermanController.__index = EndermanController

local ULT_DURATION = 22

function EndermanController.new(character)
    local self = setmetatable({}, EndermanController)
    self.Character  = character
    self.IsAwakened = false

    self.Movement  = MovementSystem.new(character, "Enderman")
    self.Dash      = DashSystem.new(character, "Enderman", self.Movement)
    self.M1        = M1System.new(character, "Enderman", self.Movement)
    self.Block     = BlockParrySystem.new(character, self.Movement)
    self.Evasive   = EvasiveSystem.new(character, "Enderman", self.Movement)
    self.Cooldowns = CooldownManager.new()
    self.UltTimer  = UltimateTimerSystem.new()

    self.UltGauge  = UltimateGaugeSystem.new(function()
        -- HUDEvent:FireClient(player, "UltReady", true)
    end)
    self.UltGauge:StartPassive()

    self.Abilities = {
        base = {
            Q = EnderTeleportation,
            E = EnderStrike,
            R = EnderCloak,
            F = TeleportationSlam,
        },
        ult = {
            Q = VoidstepFrenzy,
            E = StolenGround,
            R = YouShouldntLook,
        },
    }

    self._heartbeat = game:GetService("RunService").Heartbeat:Connect(function(dt)
        self.Movement:Update(dt)
    end)

    return self
end

function EndermanController:OnM1()        self.M1:Attack() end
function EndermanController:OnDash(dir)   self.Dash:Dash(dir) end
function EndermanController:OnBlockDown() self.Block:StartBlock() end
function EndermanController:OnBlockUp()   self.Block:EndBlock() end
function EndermanController:OnEvasive(d)  self.Evasive:Activate(d) end

function EndermanController:OnAbility(slot)
    local set     = self.IsAwakened and self.Abilities.ult or self.Abilities.base
    local ability = set[slot]
    if ability then ability.Use(self.Character, self.Cooldowns, self.Movement) end
end

function EndermanController:OnUltimate()
    if self.IsAwakened then return end
    if not self.UltGauge:Consume() then return end
    self:_activateUlt()
end

function EndermanController:_activateUlt()
    self.IsAwakened = true
    self.Movement:LockMovement(2.5)

    -- Void Dominion cinematic:
    --   Screen distorts with void static, purple particle eruption,
    --   terrain fragments begin floating, warped teleport audio
    -- CinematicRemote:FireAllClients("EndermanVoidDominion", self.Character)
    -- VFXRemote:FireAllClients("EndermanUltForm", self.Character, true)

    -- Ult passive: Enderman leaves void distortion trails during teleports
    -- and all teleport-based abilities have 20% reduced cooldown
    self._ultCDMult = 0.80
    character:SetAttribute("VoidDominionActive", true)

    -- HUDEvent:FireClient(player, "UltActivated", "Enderman", ULT_DURATION)

    self.UltTimer:Start(ULT_DURATION,
        function(timeLeft, ratio)
            -- HUDEvent:FireClient(player, "UltTick", timeLeft, ratio)
        end,
        function()
            self:_revertUlt()
        end
    )
end

function EndermanController:_revertUlt()
    self.IsAwakened = false
    self._ultCDMult = 1.0
    self.Character:SetAttribute("VoidDominionActive", false)
    -- VFXRemote:FireAllClients("EndermanUltForm", self.Character, false)
    -- HUDEvent:FireClient(player, "UltReverted", "Enderman")
    self.UltGauge:EndUlt()
end

function EndermanController:OnHitReceived(attacker, damage, config)
    if self.Evasive:IsCurrentlyInvincible() then return 0 end
    local finalDamage = self.Block:OnHitReceived(attacker, damage, config)
    self.UltGauge:OnDamageTaken(finalDamage)
    return finalDamage
end

function EndermanController:OnDamageDealt(amount)
    self.UltGauge:OnDamageDealt(amount)
end

function EndermanController:Destroy()
    self.UltTimer:Stop()
    self.UltGauge:StopPassive()
    if self._heartbeat then self._heartbeat:Disconnect() end
end

return EndermanController
