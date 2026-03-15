--[[
    ResultsUI.lua
    End-of-match screen shown after the winner is decided.

    Displays:
      • VICTORY! / DEFEAT / DRAW in large text with appropriate colour
      • Round-score line  e.g.  "You  2 – 1  Bob"
      • Rematch countdown  "Rematch in 10s…"

    The rematch counter is updated each second by GameClient
    via ResultsUI.UpdateRematch(secondsLeft).

    Usage (GameClient):
      local ResultsUI = require(script.Parent.ResultsUI)
      ResultsUI.Show(isWin, isDraw, opponentName, myWins, oppWins, rematchSec)
      ResultsUI.UpdateRematch(9)
      ResultsUI.Hide()
--]]

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ResultsUI = {}

local localPlayer = Players.LocalPlayer
local gui         = nil

-- ── Build ──────────────────────────────────────────────────────────────────

local function buildScreen(isWin, isDraw, opponentName, myWins, oppWins, rematchSec)
    if gui then gui:Destroy() end

    gui = Instance.new("ScreenGui")
    gui.Name            = "ResultsUI"
    gui.ResetOnSpawn    = false
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.Parent          = localPlayer.PlayerGui

    -- Dark overlay (starts transparent for fade-in)
    local bg = Instance.new("Frame")
    bg.Name                   = "Background"
    bg.Size                   = UDim2.fromScale(1, 1)
    bg.BackgroundColor3       = Color3.fromRGB(5, 5, 12)
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel        = 0
    bg.Parent                 = gui

    -- Outcome
    local outcomeText, outcomeColor
    if isDraw then
        outcomeText  = "DRAW"
        outcomeColor = Color3.fromRGB(200, 200, 80)
    elseif isWin then
        outcomeText  = "VICTORY!"
        outcomeColor = Color3.fromRGB(80, 255, 100)
    else
        outcomeText  = "DEFEAT"
        outcomeColor = Color3.fromRGB(255, 60, 60)
    end

    local outcome = Instance.new("TextLabel")
    outcome.Name                    = "Outcome"
    outcome.Size                    = UDim2.new(1, 0, 0, 100)
    outcome.Position                = UDim2.new(0, 0, 0.20, 0)
    outcome.BackgroundTransparency  = 1
    outcome.Text                    = outcomeText
    outcome.Font                    = Enum.Font.GothamBold
    outcome.TextSize                = 76
    outcome.TextColor3              = outcomeColor
    outcome.TextStrokeTransparency  = 0.3
    outcome.TextStrokeColor3        = Color3.fromRGB(0, 0, 0)
    outcome.TextTransparency        = 1
    outcome.Parent                  = bg

    -- Score line
    local score = Instance.new("TextLabel")
    score.Name                   = "Score"
    score.Size                   = UDim2.new(1, 0, 0, 40)
    score.Position               = UDim2.new(0, 0, 0.48, 0)
    score.BackgroundTransparency = 1
    score.Text                   = string.format(
        "%s  %d – %d  %s",
        localPlayer.Name, myWins, oppWins, opponentName
    )
    score.Font                   = Enum.Font.Gotham
    score.TextSize               = 26
    score.TextColor3             = Color3.fromRGB(220, 220, 220)
    score.TextTransparency       = 1
    score.Parent                 = bg

    -- Rematch countdown
    local rematch = Instance.new("TextLabel")
    rematch.Name                   = "RematchLabel"
    rematch.Size                   = UDim2.new(1, 0, 0, 28)
    rematch.Position               = UDim2.new(0, 0, 0.64, 0)
    rematch.BackgroundTransparency = 1
    rematch.Text                   = "Rematch in " .. tostring(rematchSec) .. "s…"
    rematch.Font                   = Enum.Font.Gotham
    rematch.TextSize               = 20
    rematch.TextColor3             = Color3.fromRGB(150, 150, 160)
    rematch.TextTransparency       = 1
    rematch.Parent                 = bg

    -- Fade everything in
    TweenService:Create(bg,      TweenInfo.new(0.5), { BackgroundTransparency = 0.22 }):Play()
    TweenService:Create(outcome, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
    TweenService:Create(score,   TweenInfo.new(0.6), { TextTransparency = 0 }):Play()
    TweenService:Create(rematch, TweenInfo.new(0.7), { TextTransparency = 0 }):Play()
end

-- ── Public API ─────────────────────────────────────────────────────────────

function ResultsUI.Show(isWin, isDraw, opponentName, myWins, oppWins, rematchSec)
    buildScreen(
        isWin     or false,
        isDraw    or false,
        opponentName or "Opponent",
        myWins    or 0,
        oppWins   or 0,
        rematchSec or 10
    )
end

function ResultsUI.UpdateRematch(secondsLeft)
    if not gui then return end
    local bg  = gui:FindFirstChild("Background")
    local lbl = bg and bg:FindFirstChild("RematchLabel")
    if lbl then
        lbl.Text = "Rematch in " .. tostring(secondsLeft) .. "s…"
    end
end

function ResultsUI.Hide()
    if gui then
        gui:Destroy()
        gui = nil
    end
end

return ResultsUI
