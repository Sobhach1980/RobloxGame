--[[
    CharacterSelectUI.lua
    Character selection screen shown at the start of each match.

    Layout:
      • 5 character cards in a horizontal row (portrait + role tag)
      • Detail panel below the cards (name, subtitle, role, description)
      • Confirm button (enabled after a card is clicked)

    Flow:
      1. Show()  — builds & displays the ScreenGui
      2. Player hovers a card → detail panel updates
      3. Player clicks a card → card highlights, Confirm enables
      4. Player clicks Confirm → fires SelectCharacter remote, Hide() called
      5. Hide() — destroys the ScreenGui

    Usage (GameClient):
      local CharacterSelectUI = require(script.Parent.CharacterSelectUI)
      CharacterSelectUI.Init(selectRemote)
      CharacterSelectUI.Show()
--]]

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RosterConfig = require(ReplicatedStorage.RosterConfig)

local CharacterSelectUI = {}

local localPlayer  = Players.LocalPlayer
local selectRemote = nil
local screenGui    = nil

-- Per-character accent colours
local CHAR_COLORS = {
    Steve    = Color3.fromRGB(70,  130, 200),
    Alex     = Color3.fromRGB(200,  90,  60),
    Zombie   = Color3.fromRGB( 80, 160,  80),
    Enderman = Color3.fromRGB(120,  60, 180),
    Skeleton = Color3.fromRGB(210, 210, 180),
}

-- ── Build ──────────────────────────────────────────────────────────────────

local function buildUI()
    local gui = Instance.new("ScreenGui")
    gui.Name            = "CharacterSelectUI"
    gui.ResetOnSpawn    = false
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.Parent          = localPlayer.PlayerGui

    -- Dark background overlay
    local bg = Instance.new("Frame")
    bg.Name                   = "Background"
    bg.Size                   = UDim2.fromScale(1, 1)
    bg.BackgroundColor3       = Color3.fromRGB(10, 10, 18)
    bg.BackgroundTransparency = 0.15
    bg.BorderSizePixel        = 0
    bg.Parent                 = gui

    -- Title
    local title = Instance.new("TextLabel")
    title.Size                   = UDim2.new(1, 0, 0, 60)
    title.Position               = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text                   = "SELECT YOUR CHARACTER"
    title.Font                   = Enum.Font.GothamBold
    title.TextSize               = 34
    title.TextColor3             = Color3.fromRGB(255, 220, 80)
    title.Parent                 = bg

    -- Card row container
    local cardRow = Instance.new("Frame")
    cardRow.Name                   = "CardRow"
    cardRow.Size                   = UDim2.new(0.88, 0, 0, 190)
    cardRow.Position               = UDim2.new(0.06, 0, 0.16, 0)
    cardRow.BackgroundTransparency = 1
    cardRow.Parent                 = bg

    local layout = Instance.new("UIListLayout")
    layout.FillDirection       = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.Padding             = UDim.new(0, 14)
    layout.Parent              = cardRow

    -- Detail panel
    local detail = Instance.new("Frame")
    detail.Name                   = "Detail"
    detail.Size                   = UDim2.new(0.42, 0, 0, 120)
    detail.Position               = UDim2.new(0.29, 0, 0.56, 0)
    detail.BackgroundColor3       = Color3.fromRGB(18, 18, 30)
    detail.BackgroundTransparency = 0.25
    detail.BorderSizePixel        = 0
    detail.Parent                 = bg

    local detailCorner = Instance.new("UICorner")
    detailCorner.CornerRadius = UDim.new(0, 8)
    detailCorner.Parent       = detail

    local function makeLabel(name, size, pos, textSize, bold, color)
        local lbl = Instance.new("TextLabel")
        lbl.Name                   = name
        lbl.Size                   = size
        lbl.Position               = pos
        lbl.BackgroundTransparency = 1
        lbl.Font                   = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        lbl.TextSize               = textSize
        lbl.TextColor3             = color or Color3.fromRGB(220, 220, 220)
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.TextWrapped            = true
        lbl.Text                   = ""
        lbl.Parent                 = detail
        return lbl
    end

    local lblName  = makeLabel("CharName",  UDim2.new(1,-12,0,28), UDim2.new(0,8,0, 6), 20, true,  Color3.fromRGB(255,220,80))
    local lblSub   = makeLabel("CharSub",   UDim2.new(1,-12,0,20), UDim2.new(0,8,0,34), 13, false, Color3.fromRGB(160,160,180))
    local lblRole  = makeLabel("CharRole",  UDim2.new(1,-12,0,18), UDim2.new(0,8,0,54), 12, false, Color3.fromRGB(200,180,100))
    local lblDesc  = makeLabel("CharDesc",  UDim2.new(1,-12,0,46), UDim2.new(0,8,0,72), 11, false, Color3.fromRGB(200,200,210))

    -- Confirm button
    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Name                   = "ConfirmButton"
    confirmBtn.Size                   = UDim2.new(0, 210, 0, 52)
    confirmBtn.Position               = UDim2.new(0.5, -105, 0.86, 0)
    confirmBtn.BackgroundColor3       = Color3.fromRGB(50, 180, 70)
    confirmBtn.BackgroundTransparency = 0.5
    confirmBtn.BorderSizePixel        = 0
    confirmBtn.Text                   = "CONFIRM"
    confirmBtn.Font                   = Enum.Font.GothamBold
    confirmBtn.TextSize               = 22
    confirmBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
    confirmBtn.AutoButtonColor        = false
    confirmBtn.Active                 = false
    confirmBtn.Parent                 = bg

    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 8)
    confirmCorner.Parent       = confirmBtn

    -- ── Character cards ──────────────────────────────────────────────────

    local selectedId = nil

    for _, charData in ipairs(RosterConfig.Characters) do
        local color = CHAR_COLORS[charData.Id] or Color3.fromRGB(100, 100, 100)

        local card = Instance.new("TextButton")
        card.Name                   = charData.Id
        card.Size                   = UDim2.new(0, 138, 0, 182)
        card.BackgroundColor3       = color
        card.BackgroundTransparency = 0.42
        card.BorderSizePixel        = 0
        card.AutoButtonColor        = false
        card.Text                   = ""
        card.Parent                 = cardRow

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent       = card

        -- Role tag (top)
        local roleTag = Instance.new("TextLabel")
        roleTag.Size                   = UDim2.new(1, -10, 0, 20)
        roleTag.Position               = UDim2.new(0, 5, 0, 6)
        roleTag.BackgroundTransparency = 1
        roleTag.Text                   = charData.Role
        roleTag.Font                   = Enum.Font.Gotham
        roleTag.TextSize               = 11
        roleTag.TextColor3             = Color3.fromRGB(230, 230, 230)
        roleTag.Parent                 = card

        -- Character name (bottom)
        local nameTag = Instance.new("TextLabel")
        nameTag.Size                   = UDim2.new(1, -10, 0, 30)
        nameTag.Position               = UDim2.new(0, 5, 1, -34)
        nameTag.BackgroundTransparency = 1
        nameTag.Text                   = charData.DisplayName
        nameTag.Font                   = Enum.Font.GothamBold
        nameTag.TextSize               = 18
        nameTag.TextColor3             = Color3.fromRGB(255, 255, 255)
        nameTag.Parent                 = card

        -- ── Interactions ──────────────────────────────────────────────

        card.MouseEnter:Connect(function()
            if selectedId ~= charData.Id then
                TweenService:Create(card, TweenInfo.new(0.1), {
                    BackgroundTransparency = 0.2
                }):Play()
            end
            lblName.Text = charData.DisplayName
            lblSub.Text  = charData.Subtitle
            lblRole.Text = charData.Role
            lblDesc.Text = charData.Description
        end)

        card.MouseLeave:Connect(function()
            if selectedId ~= charData.Id then
                TweenService:Create(card, TweenInfo.new(0.1), {
                    BackgroundTransparency = 0.42
                }):Play()
            end
        end)

        card.MouseButton1Click:Connect(function()
            -- Deselect previously selected card
            if selectedId then
                local old = cardRow:FindFirstChild(selectedId)
                if old then
                    TweenService:Create(old, TweenInfo.new(0.1), {
                        BackgroundTransparency = 0.42
                    }):Play()
                end
            end

            selectedId = charData.Id

            TweenService:Create(card, TweenInfo.new(0.1), {
                BackgroundTransparency = 0
            }):Play()

            -- Enable Confirm
            confirmBtn.Active                 = true
            confirmBtn.BackgroundTransparency = 0

            -- Pre-notify server of hover selection
            if selectRemote then
                selectRemote:FireServer(charData.Id)
            end
        end)
    end

    -- ── Confirm button ────────────────────────────────────────────────────

    confirmBtn.MouseButton1Click:Connect(function()
        if not selectedId then return end
        if selectRemote then
            selectRemote:FireServer(selectedId)
        end
        CharacterSelectUI.Hide()
    end)

    return gui
end

-- ── Public API ─────────────────────────────────────────────────────────────

function CharacterSelectUI.Init(remote)
    selectRemote = remote
end

function CharacterSelectUI.Show()
    if screenGui then screenGui:Destroy() end
    screenGui = buildUI()
end

function CharacterSelectUI.Hide()
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
end

return CharacterSelectUI
