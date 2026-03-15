--[[
    HUDController.lua
    Client-side HUD manager.
    Manages:
      - Health bar
      - 4 cooldown slots (base kit) / 3 ult slots + timer (awakened)
      - Ultimate gauge fill
      - Character portrait + awakened state indicator
      - Moveset icon swap on ult activation / revert
      - Ult timer countdown display
--]]

local HUDController = {}
HUDController.__index = HUDController

-- Roblox services (client-side)
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")

-- UI references (set in :Init)
local player        = Players.LocalPlayer
local playerGui     -- set in Init

-- HUD frame handles (production: wire to actual ScreenGui instances)
local _healthBar
local _ultGaugeFill
local _abilitySlots   = {}   -- [1..4] base slots
local _ultSlots       = {}   -- [1..3] ult slots
local _ultTimerLabel
local _portraitImage
local _awakenedIndicator

function HUDController.new()
    local self = setmetatable({}, HUDController)
    self.IsAwakened   = false
    self.CharacterId  = nil
    self._slotCDs     = {}   -- abilityName -> {total, startTime}
    self._conn        = nil
    return self
end

--[[
    Init(characterId, rosterConfig)
    Call once after character select to configure HUD for the chosen character.
--]]
function HUDController:Init(characterId, rosterConfig)
    self.CharacterId = characterId
    local config     = rosterConfig.Get(characterId)
    if not config then warn("HUDController: Unknown character " .. tostring(characterId)) return end

    -- Set portrait
    -- _portraitImage.Image = "rbxassetid://CHARACTER_PORTRAIT_" .. characterId:upper()

    -- Populate base ability slots
    for i, ability in ipairs(config.BaseAbilities) do
        local slot = _abilitySlots[i]
        if slot then
            -- slot.Icon.Image = "rbxassetid://ABILITY_ICON_" .. characterId:upper() .. "_" .. i
            -- slot.Label.Text = ability.Name
            self._slotCDs[ability.Name] = { total = ability.Cooldown, remaining = 0 }
        end
    end

    -- Hide ult slots initially
    for _, slot in ipairs(_ultSlots) do
        -- slot.Visible = false
    end
    -- _ultTimerLabel.Visible = false

    -- Start update loop
    self._conn = RunService.Heartbeat:Connect(function(dt)
        self:_update(dt)
    end)
end

-- ─── Health ───────────────────────────────────────────────────────────────

function HUDController:UpdateHealth(current, max)
    local ratio = math.clamp(current / max, 0, 1)
    -- _healthBar:TweenSize(UDim2.new(ratio, 0, 1, 0), "Out", "Quad", 0.12, true)
    -- Colour shift: green -> yellow -> red
    local r = math.min(1, 2 * (1 - ratio))
    local g = math.min(1, 2 * ratio)
    -- _healthBar.BackgroundColor3 = Color3.new(r, g, 0)
end

-- ─── Ultimate gauge ───────────────────────────────────────────────────────

function HUDController:UpdateUltGauge(fillRatio)
    -- _ultGaugeFill:TweenSize(UDim2.new(fillRatio, 0, 1, 0), "Out", "Quad", 0.1, true)
    if fillRatio >= 1.0 then
        -- Flash effect: gauge is ready
        -- TweenService:Create(_ultGaugeFill, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundColor3 = Color3.fromRGB(255,220,50) }):Play()
    end
end

-- ─── Cooldown slots ───────────────────────────────────────────────────────

function HUDController:StartCooldown(abilityName, duration)
    self._slotCDs[abilityName] = { total = duration, startTime = tick() }
end

function HUDController:_update(dt)
    local now = tick()
    for name, cd in pairs(self._slotCDs) do
        if cd.startTime then
            local elapsed  = now - cd.startTime
            local remaining = math.max(0, cd.total - elapsed)
            local ratio     = remaining / cd.total
            -- Update the corresponding slot overlay fill ratio
            -- self:_setSlotOverlay(name, ratio, remaining)
        end
    end
end

-- ─── Ultimate activation / revert ─────────────────────────────────────────

--[[
    OnUltActivated(characterId, duration)
    Swaps the 4 base ability slots to the 3 ult ability slots + timer.
--]]
function HUDController:OnUltActivated(characterId, duration, rosterConfig)
    self.IsAwakened = true
    local config    = rosterConfig.Get(characterId)
    if not config then return end

    -- Hide base slots
    for _, slot in ipairs(_abilitySlots) do
        -- TweenService:Create(slot, TweenInfo.new(0.3), {BackgroundTransparency=0.8}):Play()
        -- slot.Visible = false
    end

    -- Show ult slots with ult ability icons
    for i, ultAbilityName in ipairs(config.Ultimate.Abilities) do
        local slot = _ultSlots[i]
        if slot then
            -- slot.Icon.Image = "rbxassetid://ULT_ABILITY_ICON_" .. characterId:upper() .. "_" .. i
            -- slot.Label.Text = ultAbilityName
            -- slot.Visible = true
        end
    end

    -- Show and start ult timer
    self._ultDuration  = duration
    self._ultStartTime = tick()
    -- _ultTimerLabel.Visible = true
    -- _awakenedIndicator.Visible = true
    -- _awakenedIndicator.Text = config.Ultimate.Name
end

--[[
    OnUltTick(timeLeft, ratio)
    Called each heartbeat while ult is active.
--]]
function HUDController:OnUltTick(timeLeft, ratio)
    -- _ultTimerLabel.Text = string.format("%.1f", timeLeft)
    -- _ultTimerFill:TweenSize(UDim2.new(ratio, 0, 1, 0), "Out", "Linear", 0.1, true)
end

--[[
    OnUltReverted(characterId)
    Swaps back to the 4 base ability slots.
--]]
function HUDController:OnUltReverted(characterId, rosterConfig)
    self.IsAwakened = false
    local config    = rosterConfig.Get(characterId)
    if not config then return end

    -- Hide ult slots
    for _, slot in ipairs(_ultSlots) do
        -- slot.Visible = false
    end
    -- _ultTimerLabel.Visible = false
    -- _awakenedIndicator.Visible = false

    -- Restore base slots
    for i, ability in ipairs(config.BaseAbilities) do
        local slot = _abilitySlots[i]
        if slot then
            -- slot.Icon.Image = "rbxassetid://ABILITY_ICON_" .. characterId:upper() .. "_" .. i
            -- slot.Label.Text = ability.Name
            -- slot.Visible = true
        end
    end
end

-- ─── Cleanup ──────────────────────────────────────────────────────────────

function HUDController:Destroy()
    if self._conn then self._conn:Disconnect() end
end

return HUDController
