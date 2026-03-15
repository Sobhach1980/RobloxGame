--[[
    UltimateGaugeSystem.lua
    Tracks ultimate meter for a single character.
    Gauge fills from: damage dealt, damage taken, passive trickle.
    When full, notifies the character controller that ult is available.
--]]

local UltimateGaugeSystem = {}
UltimateGaugeSystem.__index = UltimateGaugeSystem

local MAX_GAUGE       = 100
local DEALT_GAIN_MULT = 0.30   -- gauge per point of damage dealt
local TAKEN_GAIN_MULT = 0.50   -- gauge per point of damage received
local PASSIVE_RATE    = 0.0    -- gauge per second (0 = disabled by default)

function UltimateGaugeSystem.new(onFull)
    local self         = setmetatable({}, UltimateGaugeSystem)
    self.Gauge         = 0
    self.IsReady       = false
    self.IsActive      = false   -- true while ult is running
    self._onFull       = onFull or function() end
    self._passiveConn  = nil
    return self
end

-- Must be called once to start passive regen (if any)
function UltimateGaugeSystem:StartPassive()
    if PASSIVE_RATE <= 0 then return end
    self._passiveConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not self.IsActive then
            self:_add(PASSIVE_RATE * dt)
        end
    end)
end

function UltimateGaugeSystem:StopPassive()
    if self._passiveConn then
        self._passiveConn:Disconnect()
        self._passiveConn = nil
    end
end

-- Call when character deals damage
function UltimateGaugeSystem:OnDamageDealt(amount)
    if self.IsActive then return end
    self:_add(amount * DEALT_GAIN_MULT)
end

-- Call when character receives damage
function UltimateGaugeSystem:OnDamageTaken(amount)
    if self.IsActive then return end
    self:_add(amount * TAKEN_GAIN_MULT)
end

function UltimateGaugeSystem:_add(amount)
    if self.IsReady then return end
    self.Gauge = math.min(MAX_GAUGE, self.Gauge + amount)
    if self.Gauge >= MAX_GAUGE then
        self.Gauge   = MAX_GAUGE
        self.IsReady = true
        self._onFull()
    end
end

-- Call when ult is activated (consume the gauge)
function UltimateGaugeSystem:Consume()
    if not self.IsReady then return false end
    self.Gauge    = 0
    self.IsReady  = false
    self.IsActive = true
    return true
end

-- Call when ult expires
function UltimateGaugeSystem:EndUlt()
    self.IsActive = false
end

-- 0.0–1.0 fill ratio for HUD
function UltimateGaugeSystem:FillRatio()
    return self.Gauge / MAX_GAUGE
end

return UltimateGaugeSystem
