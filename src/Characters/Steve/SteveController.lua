--[[
    SteveController.lua
    Character: Steve (Blue Shirt Guy)
    Role: Balanced close-range sword fighter. Sturdy baseline.

    Base moveset:
      Q – Oak Shield
      E – Advancement
      R – Sword Slash
      F – TNT Toss

    Ultimate: Undying Resurgence
    Ult moveset (replaces base):
      Q – Creative Override
      E – World Edit Cleave
      R – Last Block Standing
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

-- Ability modules
local OakShield         = require(script.Parent.Abilities.Steve_OakShield)
local Advancement       = require(script.Parent.Abilities.Steve_Advancement)
local SwordSlash        = require(script.Parent.Abilities.Steve_SwordSlash)
local TNTToss           = require(script.Parent.Abilities.Steve_TNTToss)
local CreativeOverride  = require(script.Parent.Abilities.Steve_CreativeOverride)
local WorldEditCleave   = require(script.Parent.Abilities.Steve_WorldEditCleave)
local LastBlockStanding = require(script.Parent.Abilities.Steve_LastBlockStanding)

local SteveController = {}
SteveController.__index = SteveController

local ULT_DURATION = 30

--[[
    new(character, player, remotes)
      character : Model
      player    : Player instance (for HUD FireClient)
      remotes   : table of RemoteEvent instances from GameServer
--]]
function SteveController.new(character, player, remotes)
    local self = setmetatable({}, SteveController)
    self.Character   = character
    self.Player      = player
    self.Remotes     = remotes
    self.IsAwakened  = false

    -- Combat systems
    self.Movement    = MovementSystem.new(character, "Steve")
    self.Dash        = DashSystem.new(character, "Steve", self.Movement)
    self.M1          = M1System.new(character, "Steve", self.Movement)
    self.Block       = BlockParrySystem.new(character, self.Movement)
    self.Evasive     = EvasiveSystem.new(character, "Steve", self.Movement)
    self.Cooldowns   = CooldownManager.new()
    self.UltTimer    = UltimateTimerSystem.new()
    self.Anim        = AnimationManager.new(character, "Steve")

    self.UltGauge = UltimateGaugeSystem.new(function()
        remotes.HUDRemote:FireClient(player, "UltReady", true)
    end)
    self.UltGauge:StartPassive()

    self.Abilities = {
        base = { Q = OakShield, E = Advancement, R = SwordSlash, F = TNTToss },
        ult  = { Q = CreativeOverride, E = WorldEditCleave, R = LastBlockStanding },
    }

    self._heartbeat = RunService.Heartbeat:Connect(function(dt)
        self.Movement:Update(dt)
    end)

    return self
end

-- ─── Input handlers ────────────────────────────────────────────────────────

function SteveController:OnM1()             self.M1:Attack() end
function SteveController:OnDash(direction)  self.Dash:Dash(direction) end
function SteveController:OnBlockDown()      self.Block:StartBlock() end
function SteveController:OnBlockUp()        self.Block:EndBlock() end
function SteveController:OnEvasive(dir)     self.Evasive:Activate(dir) end

function SteveController:OnAbility(slot)
    local set = self.IsAwakened and self.Abilities.ult or self.Abilities.base
    local ability = set[slot]
    if not ability then return end
    ability.Use(self.Character, self.Cooldowns, self.Movement, self.Remotes, self.Anim)
end

function SteveController:OnUltimate()
    if self.IsAwakened then return end
    if not self.UltGauge:Consume() then return end
    self:_activateUlt()
end

-- ─── Ultimate activation ───────────────────────────────────────────────────

function SteveController:_activateUlt()
    self.IsAwakened = true
    self._ultPassiveDamageMult = 0.90

    UltActivatorSequence.Activate({
        character      = self.Character,
        characterId    = "Steve",
        animManager    = self.Anim,
        remotes        = self.Remotes,
        movementSystem = self.Movement,
        onComplete     = function()
            -- Aura on after cinematic lock ends
            VFXSystem.Fire("SteveUltForm", self.Character, true)
            self.Remotes.HUDRemote:FireClient(self.Player, "UltActivated", "Steve", ULT_DURATION)

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

-- ─── Ultimate revert ───────────────────────────────────────────────────────

function SteveController:_revertUlt()
    self.IsAwakened            = false
    self._ultPassiveDamageMult = 1.0

    VFXSystem.Fire("SteveUltForm", self.Character, false)
    UltActivatorSequence.Revert({
        remotes     = self.Remotes,
        character   = self.Character,
        characterId = "Steve",
    })

    self.Remotes.HUDRemote:FireClient(self.Player, "UltReverted", "Steve")
    self.UltGauge:EndUlt()
end

-- ─── Damage pipeline ───────────────────────────────────────────────────────

function SteveController:OnHitReceived(attacker, damage, config)
    if self.Evasive:IsCurrentlyInvincible() then return 0 end

    local finalDamage = self.Block:OnHitReceived(attacker, damage, config)

    if self.IsAwakened and self._ultPassiveDamageMult then
        finalDamage = math.ceil(finalDamage * self._ultPassiveDamageMult)
    end

    self.UltGauge:OnDamageTaken(finalDamage)
    return finalDamage
end

function SteveController:OnDamageDealt(amount)
    self.UltGauge:OnDamageDealt(amount)
end

-- ─── Cleanup ───────────────────────────────────────────────────────────────

function SteveController:Destroy()
    self.UltTimer:Stop()
    self.UltGauge:StopPassive()
    if self._heartbeat then self._heartbeat:Disconnect() end
end

return SteveController
