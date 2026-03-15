--[[
    MovementSystem.lua
    Universal combat movement foundation for all characters.
    Handles grounded movement, air movement, gravity, friction,
    jump tuning, turning speed, and movement lock during attacks.
--]]

local MovementSystem = {}
MovementSystem.__index = MovementSystem

-- Default baseline tuning (Steve / Alex balanced baseline)
local DEFAULTS = {
    WalkSpeed         = 16,
    SprintSpeed       = 24,
    CombatSpeed       = 14,   -- speed while attacking
    AirSpeed          = 12,
    JumpPower         = 50,
    Gravity           = 196.2,
    Friction          = 0.35,
    TurningSpeed      = 8,
    MoveLockDuration  = 0,    -- seconds movement is locked during attack (set per character)
    AirControl        = 0.6,  -- 0–1 scale
}

-- Per-character overrides applied on top of defaults
local CHARACTER_TUNING = {
    Steve = {
        WalkSpeed    = 16,
        SprintSpeed  = 24,
        JumpPower    = 50,
        Gravity      = 196.2,
        Friction     = 0.35,
        -- Balanced baseline; feels grounded and sturdy
    },
    Alex = {
        WalkSpeed    = 17,
        SprintSpeed  = 26,
        JumpPower    = 52,
        Gravity      = 190,
        Friction     = 0.30,
        AirControl   = 0.7,
        -- Agile and slightly quicker than Steve
    },
    Zombie = {
        WalkSpeed    = 14,
        SprintSpeed  = 20,
        JumpPower    = 44,
        Gravity      = 210,
        Friction     = 0.40,
        TurningSpeed = 6,
        AirControl   = 0.45,
        -- Heavier, slower to turn; relentless charge feel
    },
    Enderman = {
        WalkSpeed    = 15,
        SprintSpeed  = 22,
        JumpPower    = 58,
        Gravity      = 170,
        Friction     = 0.28,
        AirControl   = 0.75,
        -- Slightly floatier; suits teleport-style movement
    },
    Skeleton = {
        WalkSpeed    = 15,
        SprintSpeed  = 22,
        JumpPower    = 48,
        Gravity      = 196.2,
        Friction     = 0.32,
        CombatSpeed  = 12,
        -- Less close-range mobility; excels at range and evasion
    },
}

-- Merge defaults with character overrides
local function buildTuning(characterName)
    local tuning = {}
    for k, v in pairs(DEFAULTS) do tuning[k] = v end
    local overrides = CHARACTER_TUNING[characterName]
    if overrides then
        for k, v in pairs(overrides) do tuning[k] = v end
    end
    return tuning
end

--[[
    new(character: Model, characterName: string) -> MovementSystem
    Initialises the movement system for a specific character.
--]]
function MovementSystem.new(character, characterName)
    local self = setmetatable({}, MovementSystem)
    self.Character     = character
    self.Name          = characterName
    self.Tuning        = buildTuning(characterName)
    self.IsLocked      = false      -- true during attack move-lock windows
    self.IsAirborne    = false
    self.IsSprinting   = false
    self.CurrentSpeed  = self.Tuning.WalkSpeed

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed  = self.Tuning.WalkSpeed
        humanoid.JumpPower  = self.Tuning.JumpPower
        self.Humanoid = humanoid
    end

    return self
end

-- Apply movement lock for the given duration (called by attack scripts)
function MovementSystem:LockMovement(duration)
    if self.IsLocked then return end
    self.IsLocked = true
    if self.Humanoid then
        self.Humanoid.WalkSpeed = 0
    end
    task.delay(duration, function()
        self.IsLocked = false
        self:ApplyCurrentSpeed()
    end)
end

-- Switch between walk / sprint / combat speed states
function MovementSystem:SetState(state)
    if self.IsLocked then return end
    local t = self.Tuning
    if state == "sprint" then
        self.IsSprinting = true
        self.CurrentSpeed = t.SprintSpeed
    elseif state == "combat" then
        self.IsSprinting = false
        self.CurrentSpeed = t.CombatSpeed
    else
        self.IsSprinting = false
        self.CurrentSpeed = t.WalkSpeed
    end
    self:ApplyCurrentSpeed()
end

function MovementSystem:ApplyCurrentSpeed()
    if self.Humanoid and not self.IsLocked then
        self.Humanoid.WalkSpeed = self.CurrentSpeed
    end
end

-- Called each frame / heartbeat by character controller
function MovementSystem:Update(dt)
    if not self.Humanoid then return end
    local rootPart = self.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Detect airborne state
    local rayOrigin = rootPart.Position
    local rayDir    = Vector3.new(0, -3.5, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {self.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(rayOrigin, rayDir, rayParams)
    self.IsAirborne = (result == nil)

    -- Apply air-control friction when airborne
    if self.IsAirborne and not self.IsLocked then
        local vel = rootPart.AssemblyLinearVelocity
        local horizontal = Vector3.new(vel.X, 0, vel.Z)
        local t = self.Tuning
        local maxAirVel = t.AirSpeed
        if horizontal.Magnitude > maxAirVel then
            local clamped = horizontal.Unit * maxAirVel
            rootPart.AssemblyLinearVelocity = Vector3.new(
                clamped.X, vel.Y, clamped.Z
            )
        end
    end
end

return MovementSystem
