--[[
    UltimateTimerSystem.lua
    Manages the countdown timer for an active ultimate form.
    Handles: start, tick callbacks for HUD, and expiry callback
    that triggers revert logic in the character controller.
--]]

local UltimateTimerSystem = {}
UltimateTimerSystem.__index = UltimateTimerSystem

function UltimateTimerSystem.new()
    local self       = setmetatable({}, UltimateTimerSystem)
    self.IsRunning   = false
    self.TimeLeft    = 0
    self.TotalTime   = 0
    self._conn       = nil
    self._onExpire   = nil
    self._onTick     = nil
    return self
end

--[[
    Start(duration, onTick, onExpire)
    onTick(timeLeft, ratio)  -- called every heartbeat
    onExpire()               -- called when timer hits 0
--]]
function UltimateTimerSystem:Start(duration, onTick, onExpire)
    if self.IsRunning then self:Stop() end

    self.IsRunning = true
    self.TotalTime = duration
    self.TimeLeft  = duration
    self._onExpire = onExpire
    self._onTick   = onTick

    self._conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not self.IsRunning then return end

        self.TimeLeft = math.max(0, self.TimeLeft - dt)
        local ratio   = self.TimeLeft / self.TotalTime

        if self._onTick then
            self._onTick(self.TimeLeft, ratio)
        end

        if self.TimeLeft <= 0 then
            self:Stop()
            if self._onExpire then
                self._onExpire()
            end
        end
    end)
end

function UltimateTimerSystem:Stop()
    self.IsRunning = false
    if self._conn then
        self._conn:Disconnect()
        self._conn = nil
    end
end

-- 0.0–1.0 (1 = full duration remaining)
function UltimateTimerSystem:Ratio()
    if self.TotalTime <= 0 then return 0 end
    return self.TimeLeft / self.TotalTime
end

return UltimateTimerSystem
