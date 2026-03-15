--[[
    SkeletonController.lua
    Character: Skeleton (Boney Sniper)
    Role: Long-range precision fighter. Less close-range mobility;
    excels at range, tracking shots, and trap-based area denial.

    Base moveset:
      Q – Bone Barrage
      E – Arrow Storm
      R – Skeleton Trap
      F – Aimbot

    Ultimate: Perfect Aim
    Ult moveset (replaces base):
      Q – Perfect Aim Protocol
      E – Arrowstorm Barrage
      R – Bonebreaker Shot
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

local BoneBarrage        = require(script.Parent.Abilities.Skeleton_BoneBarrage)
local ArrowStorm         = require(script.Parent.Abilities.Skeleton_ArrowStorm)
local SkeletonTrap       = require(script.Parent.Abilities.Skeleton_SkeletonTrap)
local Aimbot             = require(script.Parent.Abilities.Skeleton_Aimbot)
local PerfectAimProtocol = require(script.Parent.Abilities.Skeleton_PerfectAimProtocol)
local ArrowstormBarrage  = require(script.Parent.Abilities.Skeleton_ArrowstormBarrage)
local BonebreakerShot    = require(script.Parent.Abilities.Skeleton_BonebreakerShot)

local SkeletonController = {}
SkeletonController.__index = SkeletonController

local ULT_DURATION = 20

function SkeletonController.new(character, player, remotes)
    local self = setmetatable({}, SkeletonController)
    self.Character  = character
    self.Player     = player
    self.Remotes    = remotes
    self.IsAwakened = false

    self.Movement  = MovementSystem.new(character, "Skeleton")
    self.Dash      = DashSystem.new(character, "Skeleton", self.Movement)
    self.M1        = M1System.new(character, "Skeleton", self.Movement)
    self.Block     = BlockParrySystem.new(character, self.Movement)
    self.Evasive   = EvasiveSystem.new(character, "Skeleton", self.Movement)
    self.Cooldowns = CooldownManager.new()
    self.UltTimer  = UltimateTimerSystem.new()
    self.Anim      = AnimationManager.new(character, "Skeleton")

    self.UltGauge = UltimateGaugeSystem.new(function()
        remotes.HUDRemote:FireClient(player, "UltReady", true)
    end)
    self.UltGauge:StartPassive()

    self.Abilities = {
        base = { Q = BoneBarrage, E = ArrowStorm, R = SkeletonTrap, F = Aimbot },
        ult  = { Q = PerfectAimProtocol, E = ArrowstormBarrage, R = BonebreakerShot },
    }

    self._heartbeat = RunService.Heartbeat:Connect(function(dt)
        self.Movement:Update(dt)
    end)

    return self
end

function SkeletonController:OnM1()           self.M1:Attack() end
function SkeletonController:OnDash(dir)      self.Dash:Dash(dir) end
function SkeletonController:OnBlockDown()    self.Block:StartBlock() end
function SkeletonController:OnBlockUp()      self.Block:EndBlock() end
function SkeletonController:OnEvasive(d)     self.Evasive:Activate(d) end

function SkeletonController:OnAbility(slot)
    local set     = self.IsAwakened and self.Abilities.ult or self.Abilities.base
    local ability = set[slot]
    if ability then ability.Use(self.Character, self.Cooldowns, self.Movement, self.Remotes, self.Anim) end
end

function SkeletonController:OnUltimate()
    if self.IsAwakened then return end
    if not self.UltGauge:Consume() then return end
    self:_activateUlt()
end

function SkeletonController:_activateUlt()
    self.IsAwakened = true

    UltActivatorSequence.Activate({
        character      = self.Character,
        characterId    = "Skeleton",
        animManager    = self.Anim,
        remotes        = self.Remotes,
        movementSystem = self.Movement,
        onComplete     = function()
            VFXSystem.Fire("SkeletonUltForm", self.Character, true)
            self.Remotes.HUDRemote:FireClient(self.Player, "UltActivated", "Skeleton", ULT_DURATION)

            -- Ult passive: PerfectAimActive → ability scripts guarantee no gravity + homing
            self.Character:SetAttribute("PerfectAimActive", true)

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

function SkeletonController:_revertUlt()
    self.IsAwakened = false
    self.Character:SetAttribute("PerfectAimActive", false)

    VFXSystem.Fire("SkeletonUltForm", self.Character, false)
    UltActivatorSequence.Revert({
        remotes     = self.Remotes,
        character   = self.Character,
        characterId = "Skeleton",
    })

    self.Remotes.HUDRemote:FireClient(self.Player, "UltReverted", "Skeleton")
    self.UltGauge:EndUlt()
end

function SkeletonController:OnHitReceived(attacker, damage, config)
    if self.Evasive:IsCurrentlyInvincible() then return 0 end
    local finalDamage = self.Block:OnHitReceived(attacker, damage, config)
    self.UltGauge:OnDamageTaken(finalDamage)
    return finalDamage
end

function SkeletonController:OnDamageDealt(amount)
    self.UltGauge:OnDamageDealt(amount)
end

function SkeletonController:Destroy()
    self.UltTimer:Stop()
    self.UltGauge:StopPassive()
    if self._heartbeat then self._heartbeat:Disconnect() end
end

return SkeletonController
