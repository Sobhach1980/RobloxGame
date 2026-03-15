--[[
    BlockParrySystem.lua
    Defensive system: hold block, timed parry, block break, guard stun,
    and clash spark VFX.

    Some ultimate attacks partially bypass or heavily pressure guard.
    That is handled by the ability scripts passing bypassBlock = true
    or a guardPressure multiplier.
--]]

local BlockParrySystem = {}
BlockParrySystem.__index = BlockParrySystem

-- Parry window: how long after block input registers a perfect parry
local PARRY_WINDOW       = 0.25   -- seconds
-- Guard stun on successful parry (applied to attacker)
local PARRY_GUARD_STUN   = 0.6
-- Block damage reduction (0.0–1.0)
local BLOCK_DAMAGE_MULT  = 0.25
-- Block guard health (depletes on hits; regenerates)
local GUARD_MAX          = 100
local GUARD_REGEN_RATE   = 15     -- per second
local GUARD_REGEN_DELAY  = 1.5    -- seconds after last hit before regen starts

function BlockParrySystem.new(character, movementSystem)
    local self          = setmetatable({}, BlockParrySystem)
    self.Character      = character
    self.MovementSystem = movementSystem
    self.IsBlocking     = false
    self.InParryWindow  = false
    self.GuardHealth    = GUARD_MAX
    self.IsGuardBroken  = false
    self._regenTimer    = nil
    self._parryTimer    = nil
    return self
end

-- Called on block key down
function BlockParrySystem:StartBlock()
    if self.IsGuardBroken then return end
    self.IsBlocking   = true
    self.InParryWindow = true

    -- Open parry window
    if self._parryTimer then task.cancel(self._parryTimer) end
    self._parryTimer = task.delay(PARRY_WINDOW, function()
        self.InParryWindow = false
    end)

    -- Slow movement while blocking
    self.MovementSystem:SetState("combat")

    -- VFX: raise guard
    -- VFXRemote:FireAllClients("BlockRaise", self.Character)
end

-- Called on block key up
function BlockParrySystem:EndBlock()
    self.IsBlocking    = false
    self.InParryWindow = false
    self.MovementSystem:SetState("walk")
    -- VFXRemote:FireAllClients("BlockLower", self.Character)
end

--[[
    OnHitReceived(attacker, damage, config) -> actualDamage
    config = {
        bypassBlock     : boolean|nil
        guardPressure   : number|nil   -- extra guard damage multiplier (ult moves)
    }
    Returns the final damage the character takes.
--]]
function BlockParrySystem:OnHitReceived(attacker, damage, config)
    config = config or {}

    -- Perfect parry
    if self.IsBlocking and self.InParryWindow and not config.bypassBlock then
        self:_triggerParry(attacker)
        -- VFXRemote:FireAllClients("ClashSpark", self.Character.HumanoidRootPart.Position)
        return 0   -- no damage on perfect parry
    end

    -- Hold block
    if self.IsBlocking and not config.bypassBlock then
        local reducedDmg = math.ceil(damage * BLOCK_DAMAGE_MULT)
        local guardDmg   = damage * (config.guardPressure or 1.0)
        self:_damageGuard(guardDmg)
        return reducedDmg
    end

    -- Unblocked / bypass
    return damage
end

function BlockParrySystem:_triggerParry(attacker)
    -- Apply guard stun to attacker
    local attackerHuman = attacker and attacker:FindFirstChildOfClass("Humanoid")
    if attackerHuman then
        local prevSpeed = attackerHuman.WalkSpeed
        attackerHuman.WalkSpeed = 0
        task.delay(PARRY_GUARD_STUN, function()
            if attackerHuman.Parent then
                attackerHuman.WalkSpeed = prevSpeed
            end
        end)
    end
end

function BlockParrySystem:_damageGuard(amount)
    self.GuardHealth = math.max(0, self.GuardHealth - amount)

    if self.GuardHealth <= 0 and not self.IsGuardBroken then
        self:_breakGuard()
        return
    end

    -- Delay regen
    if self._regenTimer then task.cancel(self._regenTimer) end
    self._regenTimer = task.delay(GUARD_REGEN_DELAY, function()
        self:_regenGuard()
    end)
end

function BlockParrySystem:_breakGuard()
    self.IsGuardBroken = true
    self.IsBlocking    = false
    self.InParryWindow = false
    self.MovementSystem:SetState("walk")
    -- VFXRemote:FireAllClients("GuardBreak", self.Character)

    -- Recover after a delay
    task.delay(2.0, function()
        self.IsGuardBroken = false
        self.GuardHealth   = GUARD_MAX * 0.5
        -- VFXRemote:FireAllClients("GuardRecover", self.Character)
    end)
end

function BlockParrySystem:_regenGuard()
    if self.IsGuardBroken then return end
    -- Regen via heartbeat
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if self.GuardHealth >= GUARD_MAX or self.IsGuardBroken then
            connection:Disconnect()
            return
        end
        self.GuardHealth = math.min(GUARD_MAX, self.GuardHealth + GUARD_REGEN_RATE * dt)
    end)
end

return BlockParrySystem
