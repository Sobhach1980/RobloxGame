--[[
    CooldownManager.lua
    Tracks per-ability cooldowns for a single character.
    Abilities register themselves; the HUD queries remaining time.
--]]

local CooldownManager = {}
CooldownManager.__index = CooldownManager

function CooldownManager.new()
    local self = setmetatable({}, CooldownManager)
    self._cooldowns = {}   -- abilityName -> expiry timestamp
    return self
end

-- Start a cooldown; returns false if already on cooldown
function CooldownManager:Start(abilityName, duration)
    if self:IsOnCooldown(abilityName) then return false end
    self._cooldowns[abilityName] = tick() + duration
    return true
end

function CooldownManager:IsOnCooldown(abilityName)
    local expiry = self._cooldowns[abilityName]
    if not expiry then return false end
    if tick() >= expiry then
        self._cooldowns[abilityName] = nil
        return false
    end
    return true
end

-- Returns seconds remaining (0 if ready)
function CooldownManager:Remaining(abilityName)
    local expiry = self._cooldowns[abilityName]
    if not expiry then return 0 end
    return math.max(0, expiry - tick())
end

-- Returns 0.0–1.0 progress (1.0 = ready)
function CooldownManager:Progress(abilityName, totalDuration)
    local remaining = self:Remaining(abilityName)
    if totalDuration <= 0 then return 1 end
    return 1 - (remaining / totalDuration)
end

-- Force-clear a cooldown (e.g. on death / reset)
function CooldownManager:Clear(abilityName)
    self._cooldowns[abilityName] = nil
end

function CooldownManager:ClearAll()
    self._cooldowns = {}
end

return CooldownManager
