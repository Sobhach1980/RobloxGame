--[[
    M1System.lua
    Core 4-hit basic combo framework.
    Handles: hit confirm logic, combo reset timing, per-hit stun,
    final hit knockback, and cancel windows into abilities.

    Each character supplies its own HitProfile table with unique
    damage values, stun duration, animations, and VFX per hit.
--]]

local HitboxSystem   = require(script.Parent.HitboxSystem)
local HitStun        = require(script.Parent.HitStunKnockback)

local M1System = {}
M1System.__index = M1System

-- Combo window: time player has to press M1 again to continue string
local COMBO_WINDOW   = 0.55
-- Reset delay: after final hit or missed window, combo resets
local COMBO_RESET    = 0.9

--[[
    HitProfile format per character:
    {
        [hitIndex] = {
            Damage        = number,
            StunType      = "light"|"medium"|"heavy"|"launcher",
            KnockbackForce= number,       -- non-zero on final hit
            AnimId        = "rbxassetid://...",
            VFX           = "string",
            HitboxSize    = Vector3,
            HitboxOffset  = Vector3,      -- forward offset from root
            CancelWindow  = number,       -- seconds after hit player can cancel into ability
            MoveLock      = number,       -- seconds movement is locked during swing
        }
    }
--]]

local HIT_PROFILES = {
    Steve = {
        -- Sword-based close combat; clean 4-hit saber string
        [1] = { Damage=12, StunType="light",   KnockbackForce=0,  AnimId="rbxassetid://STEVE_M1_1", VFX="SteveSwordSwipe1", HitboxSize=Vector3.new(6,5,5), HitboxOffset=Vector3.new(0,0,-3), CancelWindow=0.3, MoveLock=0.18 },
        [2] = { Damage=13, StunType="light",   KnockbackForce=0,  AnimId="rbxassetid://STEVE_M1_2", VFX="SteveSwordSwipe2", HitboxSize=Vector3.new(6,5,5), HitboxOffset=Vector3.new(0,0,-3), CancelWindow=0.3, MoveLock=0.18 },
        [3] = { Damage=14, StunType="medium",  KnockbackForce=0,  AnimId="rbxassetid://STEVE_M1_3", VFX="SteveSwordSwipe3", HitboxSize=Vector3.new(7,5,5), HitboxOffset=Vector3.new(0,0,-3.5), CancelWindow=0.35, MoveLock=0.20 },
        [4] = { Damage=18, StunType="heavy",   KnockbackForce=55, AnimId="rbxassetid://STEVE_M1_4", VFX="SteveSwordFinisher", HitboxSize=Vector3.new(8,5,6), HitboxOffset=Vector3.new(0,0,-4), CancelWindow=0,   MoveLock=0.28 },
    },
    Alex = {
        -- Tool/weapon hybrid; slightly faster tempo with different arcs
        [1] = { Damage=11, StunType="light",   KnockbackForce=0,  AnimId="rbxassetid://ALEX_M1_1", VFX="AlexToolSwipe1", HitboxSize=Vector3.new(5,5,5), HitboxOffset=Vector3.new(0,0,-2.5), CancelWindow=0.3, MoveLock=0.16 },
        [2] = { Damage=12, StunType="light",   KnockbackForce=0,  AnimId="rbxassetid://ALEX_M1_2", VFX="AlexToolSwipe2", HitboxSize=Vector3.new(5,5,5), HitboxOffset=Vector3.new(0,0,-2.5), CancelWindow=0.3, MoveLock=0.16 },
        [3] = { Damage=13, StunType="medium",  KnockbackForce=0,  AnimId="rbxassetid://ALEX_M1_3", VFX="AlexToolSwipe3", HitboxSize=Vector3.new(6,5,5), HitboxOffset=Vector3.new(0,0,-3),   CancelWindow=0.35, MoveLock=0.18 },
        [4] = { Damage=20, StunType="launcher",KnockbackForce=65, AnimId="rbxassetid://ALEX_M1_4", VFX="AlexToolFinisher", HitboxSize=Vector3.new(7,5,6), HitboxOffset=Vector3.new(0,0,-3.5), CancelWindow=0, MoveLock=0.26 },
    },
    Zombie = {
        -- Claw/slash style; slower but more damage per hit
        [1] = { Damage=14, StunType="light",   KnockbackForce=0,  AnimId="rbxassetid://ZOMBIE_M1_1", VFX="ZombieClawSwipe1", HitboxSize=Vector3.new(6,5,5), HitboxOffset=Vector3.new(0,0,-3), CancelWindow=0.28, MoveLock=0.22 },
        [2] = { Damage=15, StunType="light",   KnockbackForce=0,  AnimId="rbxassetid://ZOMBIE_M1_2", VFX="ZombieClawSwipe2", HitboxSize=Vector3.new(6,5,5), HitboxOffset=Vector3.new(0,0,-3), CancelWindow=0.28, MoveLock=0.22 },
        [3] = { Damage=17, StunType="medium",  KnockbackForce=0,  AnimId="rbxassetid://ZOMBIE_M1_3", VFX="ZombieClawSwipe3", HitboxSize=Vector3.new(7,5,5), HitboxOffset=Vector3.new(0,0,-3.5), CancelWindow=0.3, MoveLock=0.24 },
        [4] = { Damage=22, StunType="heavy",   KnockbackForce=60, AnimId="rbxassetid://ZOMBIE_M1_4", VFX="ZombieClawFinisher", HitboxSize=Vector3.new(8,5,6), HitboxOffset=Vector3.new(0,0,-4), CancelWindow=0, MoveLock=0.30 },
    },
    Enderman = {
        -- Long-arm void swipes; extended reach
        [1] = { Damage=11, StunType="light",   KnockbackForce=0,  AnimId="rbxassetid://ENDERMAN_M1_1", VFX="EndermanVoidSwipe1", HitboxSize=Vector3.new(7,5,6), HitboxOffset=Vector3.new(0,0,-4),   CancelWindow=0.3, MoveLock=0.17 },
        [2] = { Damage=12, StunType="light",   KnockbackForce=0,  AnimId="rbxassetid://ENDERMAN_M1_2", VFX="EndermanVoidSwipe2", HitboxSize=Vector3.new(7,5,6), HitboxOffset=Vector3.new(0,0,-4),   CancelWindow=0.3, MoveLock=0.17 },
        [3] = { Damage=13, StunType="medium",  KnockbackForce=0,  AnimId="rbxassetid://ENDERMAN_M1_3", VFX="EndermanVoidSwipe3", HitboxSize=Vector3.new(8,5,7), HitboxOffset=Vector3.new(0,0,-4.5), CancelWindow=0.35, MoveLock=0.19 },
        [4] = { Damage=19, StunType="heavy",   KnockbackForce=58, AnimId="rbxassetid://ENDERMAN_M1_4", VFX="EndermanVoidFinisher", HitboxSize=Vector3.new(9,5,7), HitboxOffset=Vector3.new(0,0,-5), CancelWindow=0, MoveLock=0.27 },
    },
    Skeleton = {
        -- Bow bash / bone jab / short-range backup; fastest string but least damage
        [1] = { Damage=9,  StunType="light",   KnockbackForce=0,  AnimId="rbxassetid://SKELETON_M1_1", VFX="SkeletonBowBash1", HitboxSize=Vector3.new(5,5,4), HitboxOffset=Vector3.new(0,0,-2.5), CancelWindow=0.32, MoveLock=0.15 },
        [2] = { Damage=10, StunType="light",   KnockbackForce=0,  AnimId="rbxassetid://SKELETON_M1_2", VFX="SkeletonBoneJab1", HitboxSize=Vector3.new(5,5,4), HitboxOffset=Vector3.new(0,0,-2.5), CancelWindow=0.32, MoveLock=0.15 },
        [3] = { Damage=11, StunType="medium",  KnockbackForce=0,  AnimId="rbxassetid://SKELETON_M1_3", VFX="SkeletonBowBash2", HitboxSize=Vector3.new(5,5,5), HitboxOffset=Vector3.new(0,0,-3),   CancelWindow=0.35, MoveLock=0.17 },
        [4] = { Damage=16, StunType="heavy",   KnockbackForce=52, AnimId="rbxassetid://SKELETON_M1_4", VFX="SkeletonBoneFinisher", HitboxSize=Vector3.new(6,5,5), HitboxOffset=Vector3.new(0,0,-3.5), CancelWindow=0, MoveLock=0.24 },
    },
}

function M1System.new(character, characterName, movementSystem)
    local self = setmetatable({}, M1System)
    self.Character      = character
    self.Name           = characterName
    self.Profile        = HIT_PROFILES[characterName]
    self.MovementSystem = movementSystem
    self.ComboIndex     = 0
    self.InComboWindow  = false
    self.IsAttacking    = false
    self._windowTimer   = nil
    self._resetTimer    = nil
    return self
end

function M1System:Attack()
    if self.IsAttacking then return false end
    -- Advance combo index
    local nextIndex = self.ComboIndex + 1
    if nextIndex > 4 then nextIndex = 1 end
    self.ComboIndex = nextIndex

    local hit = self.Profile[nextIndex]
    self.IsAttacking = true
    self.InComboWindow = false

    -- Cancel previous timers
    if self._windowTimer then task.cancel(self._windowTimer) end
    if self._resetTimer  then task.cancel(self._resetTimer)  end

    -- Lock movement during swing
    self.MovementSystem:LockMovement(hit.MoveLock)

    -- Play animation
    self:_playAnimation(hit.AnimId)

    -- Spawn hitbox
    local rootPart = self.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local hitboxPos = rootPart.CFrame:PointToWorldSpace(hit.HitboxOffset)
        HitboxSystem.SpawnMeleeHitbox({
            Position   = hitboxPos,
            Size       = hit.HitboxSize,
            Duration   = 0.12,
            Attacker   = self.Character,
            OnHit      = function(victim)
                HitStun.Apply(victim, {
                    Damage        = hit.Damage,
                    StunType      = hit.StunType,
                    KnockbackForce= hit.KnockbackForce,
                    KnockbackDir  = rootPart.CFrame.LookVector,
                })
                self:_fireVFX(hit.VFX, hitboxPos)
            end,
        })
    end

    -- Open cancel window into abilities
    task.delay(hit.MoveLock, function()
        self.IsAttacking = false
        if nextIndex < 4 then
            -- Open combo continuation window
            self.InComboWindow = true
            self._windowTimer = task.delay(COMBO_WINDOW, function()
                self.InComboWindow = false
                self:_resetCombo()
            end)
        else
            -- Final hit: force reset
            self._resetTimer = task.delay(COMBO_RESET, function()
                self:_resetCombo()
            end)
        end
    end)

    return true
end

function M1System:_resetCombo()
    self.ComboIndex    = 0
    self.InComboWindow = false
    self.IsAttacking   = false
end

function M1System:_playAnimation(animId)
    local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local track = animator:LoadAnimation(anim)
    track:Play()
    anim:Destroy()
end

function M1System:_fireVFX(vfxName, position)
    -- VFXRemote:FireAllClients(vfxName, position)
end

return M1System
