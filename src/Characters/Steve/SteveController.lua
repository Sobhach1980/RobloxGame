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

local MovementSystem    = require(script.Parent.Parent.Parent.Shared.CombatEngine.MovementSystem)
local DashSystem        = require(script.Parent.Parent.Parent.Shared.CombatEngine.DashSystem)
local M1System          = require(script.Parent.Parent.Parent.Shared.CombatEngine.M1System)
local BlockParrySystem  = require(script.Parent.Parent.Parent.Shared.CombatEngine.BlockParrySystem)
local EvasiveSystem     = require(script.Parent.Parent.Parent.Shared.CombatEngine.EvasiveSystem)
local CooldownManager   = require(script.Parent.Parent.Parent.Shared.CombatEngine.CooldownManager)
local UltimateGaugeSystem = require(script.Parent.Parent.Parent.Shared.CombatEngine.UltimateGaugeSystem)
local UltimateTimerSystem = require(script.Parent.Parent.Parent.Shared.CombatEngine.UltimateTimerSystem)

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

-- Ultimate form duration in seconds
local ULT_DURATION = 30

function SteveController.new(character)
    local self = setmetatable({}, SteveController)
    self.Character   = character
    self.IsAwakened  = false

    -- Combat systems
    self.Movement    = MovementSystem.new(character, "Steve")
    self.Dash        = DashSystem.new(character, "Steve", self.Movement)
    self.M1          = M1System.new(character, "Steve", self.Movement)
    self.Block       = BlockParrySystem.new(character, self.Movement)
    self.Evasive     = EvasiveSystem.new(character, "Steve", self.Movement)
    self.Cooldowns   = CooldownManager.new()
    self.UltTimer    = UltimateTimerSystem.new()

    -- Ultimate gauge – triggers awakening when full
    self.UltGauge = UltimateGaugeSystem.new(function()
        -- Notify HUD that ult is ready
        -- HUDEvent:FireClient(player, "UltReady", true)
    end)
    self.UltGauge:StartPassive()

    -- Instantiate abilities (they hold no character state; context passed at use)
    self.Abilities = {
        base = {
            Q = OakShield,
            E = Advancement,
            R = SwordSlash,
            F = TNTToss,
        },
        ult = {
            Q = CreativeOverride,
            E = WorldEditCleave,
            R = LastBlockStanding,
        },
    }

    -- Heartbeat update
    self._heartbeat = game:GetService("RunService").Heartbeat:Connect(function(dt)
        self.Movement:Update(dt)
    end)

    return self
end

-- ─── Input handlers ────────────────────────────────────────────────────────

function SteveController:OnM1()
    self.M1:Attack()
end

function SteveController:OnDash(direction)
    self.Dash:Dash(direction)
end

function SteveController:OnBlockDown()
    self.Block:StartBlock()
end

function SteveController:OnBlockUp()
    self.Block:EndBlock()
end

function SteveController:OnEvasive(direction)
    self.Evasive:Activate(direction)
end

function SteveController:OnAbility(slot)
    local set = self.IsAwakened and self.Abilities.ult or self.Abilities.base
    local ability = set[slot]
    if not ability then return end
    ability.Use(self.Character, self.Cooldowns, self.Movement)
end

function SteveController:OnUltimate()
    if self.IsAwakened then return end
    if not self.UltGauge:Consume() then return end
    self:_activateUlt()
end

-- ─── Ultimate activation ───────────────────────────────────────────────────

function SteveController:_activateUlt()
    self.IsAwakened = true

    -- Lock player briefly for cinematic
    self.Movement:LockMovement(2.5)

    -- Play Steve activation sequence:
    --   glowing white eyes, black smoke, arena setup camera
    -- VFXRemote:FireAllClients("SteveUltActivation", self.Character)
    -- CinematicRemote:FireAllClients("SteveUltCinematic")

    -- Apply form visuals (aura, white eye glow, dark smoke)
    -- VFXRemote:FireAllClients("SteveUltForm", self.Character, true)

    -- Apply ultimate passive: Steve gains slight damage reduction in ult form
    self._ultPassiveDamageMult = 0.90   -- takes 10% less damage

    -- Notify HUD to swap moveset icons
    -- HUDEvent:FireClient(player, "UltActivated", "Steve", ULT_DURATION)

    -- Start countdown
    self.UltTimer:Start(ULT_DURATION,
        function(timeLeft, ratio)
            -- HUDEvent:FireClient(player, "UltTick", timeLeft, ratio)
        end,
        function()
            self:_revertUlt()
        end
    )
end

-- ─── Ultimate revert ───────────────────────────────────────────────────────

function SteveController:_revertUlt()
    self.IsAwakened              = false
    self._ultPassiveDamageMult   = 1.0

    -- Remove form visuals
    -- VFXRemote:FireAllClients("SteveUltForm", self.Character, false)

    -- Restore base HUD icons
    -- HUDEvent:FireClient(player, "UltReverted", "Steve")

    self.UltGauge:EndUlt()
end

-- ─── Damage pipeline ───────────────────────────────────────────────────────

--[[
    OnHitReceived(attacker, damage, config) -> actualDamage
    Called by the server damage pipeline before applying health loss.
--]]
function SteveController:OnHitReceived(attacker, damage, config)
    -- Invincibility frames from evasive
    if self.Evasive:IsCurrentlyInvincible() then return 0 end

    -- Block / parry handling
    local finalDamage = self.Block:OnHitReceived(attacker, damage, config)

    -- Ult passive damage reduction
    if self.IsAwakened and self._ultPassiveDamageMult then
        finalDamage = math.ceil(finalDamage * self._ultPassiveDamageMult)
    end

    -- Update ultimate gauge on damage taken
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
