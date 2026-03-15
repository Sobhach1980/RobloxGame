--[[
    MatchUI.lua
    In-match HUD overlay — shown during Fighting and Countdown states.

    Elements:
      • Round timer  (top centre)
      • Stock icons  (bottom-left P1, bottom-right P2)
      • Announcement banners (centre screen — FIGHT!, KO!, ROUND N, etc.)

    Called from GameClient in response to MatchUIRemote events.

    Usage:
      local MatchUI = require(script.Parent.MatchUI)
      MatchUI.Show()
      MatchUI.SetTimer(173)
      MatchUI.ShowFight()
      MatchUI.UpdateStocks({ Alice=2, Bob=3 }, 3)
--]]

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local MatchUI = {}

local localPlayer = Players.LocalPlayer
local gui         = nil
local timerLabel  = nil

-- ── ScreenGui lifecycle ────────────────────────────────────────────────────

local function getGui()
    if gui and gui.Parent then return gui end
    gui = Instance.new("ScreenGui")
    gui.Name            = "MatchUI"
    gui.ResetOnSpawn    = false
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.Parent          = localPlayer.PlayerGui
    return gui
end

-- ── Timer ─────────────────────────────────────────────────────────────────

local function ensureTimer()
    if timerLabel and timerLabel.Parent then return timerLabel end
    local g = getGui()

    local frame = Instance.new("Frame")
    frame.Name                   = "TimerFrame"
    frame.Size                   = UDim2.new(0, 110, 0, 48)
    frame.Position               = UDim2.new(0.5, -55, 0, 14)
    frame.BackgroundColor3       = Color3.fromRGB(10, 10, 10)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel        = 0
    frame.Parent                 = g

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent       = frame

    timerLabel = Instance.new("TextLabel")
    timerLabel.Name              = "TimerLabel"
    timerLabel.Size              = UDim2.fromScale(1, 1)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Font              = Enum.Font.GothamBold
    timerLabel.TextSize          = 32
    timerLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
    timerLabel.Text              = "--"
    timerLabel.Parent            = frame

    return timerLabel
end

-- ── Stock icon rows ────────────────────────────────────────────────────────

local function rebuildStockRow(parent, count, maxCount, color)
    for _, c in ipairs(parent:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end

    for i = 1, maxCount do
        local icon = Instance.new("Frame")
        icon.Size                   = UDim2.new(0, 22, 0, 22)
        icon.BackgroundColor3       = (i <= count)
            and color
            or Color3.fromRGB(50, 50, 50)
        icon.BackgroundTransparency = (i <= count) and 0 or 0.5
        icon.BorderSizePixel        = 0
        icon.Parent                 = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent       = icon
    end
end

local function ensureStockFrame(name, xOffset)
    local g = getGui()
    local f = g:FindFirstChild(name)
    if f then return f end

    f = Instance.new("Frame")
    f.Name                   = name
    f.Size                   = UDim2.new(0, 180, 0, 34)
    f.Position               = UDim2.new(xOffset, 0, 1, -54)
    f.BackgroundTransparency = 1
    f.Parent                 = g

    local layout = Instance.new("UIListLayout")
    layout.FillDirection       = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.Padding             = UDim.new(0, 6)
    layout.Parent              = f

    return f
end

-- ── Announcement banners ───────────────────────────────────────────────────

local function announce(text, color, duration, size)
    local g = getGui()

    local lbl = Instance.new("TextLabel")
    lbl.Name                    = "Banner"
    lbl.Size                    = UDim2.new(0.65, 0, 0, 80)
    lbl.Position                = UDim2.new(0.175, 0, 0.36, 0)
    lbl.BackgroundTransparency  = 1
    lbl.Text                    = text
    lbl.Font                    = Enum.Font.GothamBold
    lbl.TextSize                = size or 52
    lbl.TextColor3              = color or Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency  = 0.35
    lbl.TextStrokeColor3        = Color3.fromRGB(0, 0, 0)
    lbl.TextScaled              = false
    lbl.TextWrapped             = false
    lbl.TextTransparency        = 1
    lbl.Parent                  = g

    TweenService:Create(lbl, TweenInfo.new(0.12), { TextTransparency = 0 }):Play()
    task.delay(duration or 1.4, function()
        TweenService:Create(lbl, TweenInfo.new(0.28), { TextTransparency = 1 }):Play()
        task.delay(0.32, function()
            if lbl.Parent then lbl:Destroy() end
        end)
    end)
end

-- ── Public API ─────────────────────────────────────────────────────────────

function MatchUI.Show()
    getGui().Enabled = true
end

function MatchUI.Hide()
    if gui then gui.Enabled = false end
end

function MatchUI.SetTimer(seconds)
    local lbl  = ensureTimer()
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    lbl.Text      = string.format("%d:%02d", mins, secs)
    lbl.TextColor3 = (seconds <= 10)
        and Color3.fromRGB(255, 60, 60)
        or  Color3.fromRGB(255, 255, 255)
end

-- stockTable: { [playerName] = stockCount }
function MatchUI.UpdateStocks(stockTable, maxStocks)
    local players = game:GetService("Players"):GetPlayers()
    local p1      = localPlayer
    local p2      = nil
    for _, p in ipairs(players) do
        if p ~= localPlayer then p2 = p; break end
    end

    local p1Stocks = stockTable[p1.Name] or 0
    local p2Stocks = p2 and (stockTable[p2.Name] or 0) or 0

    local f1 = ensureStockFrame("P1Stocks", 0.02)
    rebuildStockRow(f1, p1Stocks, maxStocks, Color3.fromRGB(80, 160, 255))

    local f2 = ensureStockFrame("P2Stocks", 0.78)
    rebuildStockRow(f2, p2Stocks, maxStocks, Color3.fromRGB(255, 100, 80))
end

function MatchUI.ShowCountdown(n)
    announce(tostring(n), Color3.fromRGB(255, 255, 255), 0.82, 64)
end

function MatchUI.ShowFight()
    announce("FIGHT!", Color3.fromRGB(80, 255, 100), 1.1, 60)
end

function MatchUI.ShowRoundBanner(roundNumber)
    announce("ROUND  " .. roundNumber, Color3.fromRGB(255, 220, 80), 2.0, 48)
end

function MatchUI.ShowKO(playerName)
    announce(playerName .. "  KO!", Color3.fromRGB(255, 70, 70), 1.8, 46)
end

function MatchUI.ShowRoundWin(playerName)
    announce(playerName .. "\nWINS THE ROUND", Color3.fromRGB(255, 220, 80), 2.4, 38)
end

function MatchUI.ShowTimerExpired()
    announce("TIME!", Color3.fromRGB(255, 150, 50), 1.4, 54)
end

function MatchUI.ShowRoundDraw()
    announce("DRAW", Color3.fromRGB(200, 200, 80), 2.0, 54)
end

return MatchUI
