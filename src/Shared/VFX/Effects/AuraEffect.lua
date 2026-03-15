--[[
    AuraEffect.lua  —  Step 15
    Client-side persistent aura / form visual attached to a character.
    Used for:
      - Ultimate form auras (Steve white smoke, Alex purple dragon energy,
        Zombie decay mist, Enderman void distortion, Skeleton icy blue glow)
      - Ability buff states (Creative Override glow, Alex Advancement circuit)
      - Bleed / infection visual indicators on victims

    Attaches ParticleEmitters and PointLight directly to character parts.
    Returns a cleanup function that removes all added instances.
--]]

local TweenService = game:GetService("TweenService")

local AuraEffect = {}

--[[
    Attach(character, config) -> cleanupFn
    config = {
        ParticleColor   : Color3
        ParticleColor2  : Color3|nil
        Rate            : number          -- particles/sec (continuous)
        Size            : NumberSequence  -- particle size over lifetime
        Speed           : NumberRange
        Lifetime        : NumberRange
        LightColor      : Color3|nil      -- if set, adds PointLight
        LightBrightness : number          -- default 2
        LightRange      : number          -- default 15
        TargetParts     : {string}        -- part names to attach to
                                          -- default: {"HumanoidRootPart","UpperTorso"}
        TransparencySeq : NumberSequence|nil
        Rotation        : NumberRange|nil
        RotSpeed        : NumberRange|nil
        WindResistance  : number|nil
        LightEmission   : number          -- 0-1
        FadeInTime      : number          -- seconds to reach full Rate
    }
--]]
function AuraEffect.Attach(character, config)
    config = config or {}

    local color1   = config.ParticleColor  or Color3.fromRGB(200, 200, 255)
    local color2   = config.ParticleColor2 or color1
    local rate     = config.Rate           or 20
    local speed    = config.Speed          or NumberRange.new(1, 4)
    local lifetime = config.Lifetime       or NumberRange.new(0.8, 1.5)
    local sizeSeq  = config.Size           or NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.3, 0.4),
        NumberSequenceKeypoint.new(1, 0),
    })
    local tranSeq  = config.TransparencySeq or NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    local fadeTime = config.FadeInTime or 0.5
    local emit     = config.LightEmission or 0.5
    local targetParts = config.TargetParts or {"HumanoidRootPart", "UpperTorso"}

    local added = {}   -- all instances to clean up

    for _, partName in ipairs(targetParts) do
        local part = character:FindFirstChild(partName, true)
        if not part then continue end

        -- Main aura emitter
        local pe = Instance.new("ParticleEmitter")
        pe.Color            = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color1),
            ColorSequenceKeypoint.new(1, color2),
        })
        pe.Size             = sizeSeq
        pe.Transparency     = tranSeq
        pe.Speed            = speed
        pe.Lifetime         = lifetime
        pe.Rate             = 0            -- start at 0, fade in
        pe.SpreadAngle      = Vector2.new(180, 180)
        pe.LightEmission    = emit
        pe.LightInfluence   = 0.4
        pe.RotSpeed         = config.RotSpeed   or NumberRange.new(-30, 30)
        pe.Rotation         = config.Rotation   or NumberRange.new(0, 360)
        if config.WindResistance then
            pe.WindResistance = config.WindResistance
        end
        pe.Parent           = part
        table.insert(added, pe)

        -- Fade in rate
        local startTime = tick()
        local fadeConn
        fadeConn = game:GetService("RunService").Heartbeat:Connect(function()
            local t = math.min(1, (tick() - startTime) / fadeTime)
            pe.Rate = rate * t
            if t >= 1 then fadeConn:Disconnect() end
        end)
        table.insert(added, { disconnect = function() fadeConn:Disconnect() end })
    end

    -- Optional point light (on HumanoidRootPart)
    if config.LightColor then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            local light = Instance.new("PointLight")
            light.Color      = config.LightColor
            light.Brightness = config.LightBrightness or 2
            light.Range      = config.LightRange or 15
            light.Shadows    = false
            light.Parent     = root
            table.insert(added, light)
        end
    end

    -- Return cleanup function
    return function()
        for _, item in ipairs(added) do
            if typeof(item) == "Instance" then
                if item:IsA("ParticleEmitter") then
                    -- Fade out Rate before destroying
                    item.Rate = 0
                    task.delay(item.Lifetime.Max, function()
                        if item.Parent then item:Destroy() end
                    end)
                else
                    if item.Parent then item:Destroy() end
                end
            elseif type(item) == "table" and item.disconnect then
                item.disconnect()
            end
        end
    end
end

-- Pre-built presets for each character's ult form aura
function AuraEffect.AttachPreset(presetName, character)
    local presets = {
        SteveUltAura = {
            ParticleColor  = Color3.fromRGB(200, 210, 255),
            ParticleColor2 = Color3.fromRGB(80, 80, 80),     -- black smoke mixed in
            Rate           = 25,
            Speed          = NumberRange.new(2, 6),
            Lifetime       = NumberRange.new(0.6, 1.2),
            LightColor     = Color3.fromRGB(200, 220, 255),
            LightBrightness = 1.5,
            LightRange     = 12,
            LightEmission  = 0.6,
            TargetParts    = { "HumanoidRootPart", "UpperTorso", "Head" },
        },
        AlexUltAura = {
            ParticleColor  = Color3.fromRGB(140, 0, 220),
            ParticleColor2 = Color3.fromRGB(200, 100, 255),
            Rate           = 35,
            Speed          = NumberRange.new(3, 8),
            Lifetime       = NumberRange.new(0.5, 1.0),
            LightColor     = Color3.fromRGB(160, 50, 255),
            LightBrightness = 2.5,
            LightRange     = 18,
            LightEmission  = 0.8,
            TargetParts    = { "HumanoidRootPart", "UpperTorso", "Head", "LeftUpperArm", "RightUpperArm" },
            Rotation       = NumberRange.new(0, 360),
            RotSpeed       = NumberRange.new(-60, 60),
        },
        ZombieUltAura = {
            ParticleColor  = Color3.fromRGB(50, 200, 50),
            ParticleColor2 = Color3.fromRGB(100, 80, 20),    -- decay brown
            Rate           = 30,
            Speed          = NumberRange.new(1, 3),
            Lifetime       = NumberRange.new(1.0, 2.0),
            LightColor     = Color3.fromRGB(0, 220, 60),
            LightBrightness = 1.8,
            LightRange     = 14,
            LightEmission  = 0.4,
            WindResistance = 0.5,
            TargetParts    = { "HumanoidRootPart", "UpperTorso", "Head", "LeftUpperLeg", "RightUpperLeg" },
        },
        EndermanUltAura = {
            ParticleColor  = Color3.fromRGB(80, 0, 160),
            ParticleColor2 = Color3.fromRGB(200, 150, 255),
            Rate           = 40,
            Speed          = NumberRange.new(3, 10),
            Lifetime       = NumberRange.new(0.4, 0.9),
            LightColor     = Color3.fromRGB(120, 0, 200),
            LightBrightness = 3.0,
            LightRange     = 20,
            LightEmission  = 1.0,
            TargetParts    = { "HumanoidRootPart", "UpperTorso", "Head",
                               "LeftUpperArm", "RightUpperArm",
                               "LeftUpperLeg", "RightUpperLeg" },
        },
        SkeletonUltAura = {
            ParticleColor  = Color3.fromRGB(100, 200, 255),
            ParticleColor2 = Color3.fromRGB(200, 240, 255),
            Rate           = 20,
            Speed          = NumberRange.new(1, 5),
            Lifetime       = NumberRange.new(0.6, 1.4),
            LightColor     = Color3.fromRGB(120, 210, 255),
            LightBrightness = 2.0,
            LightRange     = 16,
            LightEmission  = 0.7,
            TargetParts    = { "HumanoidRootPart", "Head", "LeftHand", "RightHand" },
        },
        -- Buff state auras
        AlexAdvancement = {
            ParticleColor  = Color3.fromRGB(255, 80, 80),
            ParticleColor2 = Color3.fromRGB(255, 180, 180),
            Rate           = 15,
            Speed          = NumberRange.new(0.5, 2),
            Lifetime       = NumberRange.new(0.3, 0.7),
            LightColor     = Color3.fromRGB(255, 80, 80),
            LightBrightness = 1.0,
            LightRange     = 8,
            LightEmission  = 0.9,
            TargetParts    = { "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm" },
        },
        ZombieBleed = {
            ParticleColor  = Color3.fromRGB(80, 255, 80),
            ParticleColor2 = Color3.fromRGB(50, 150, 50),
            Rate           = 8,
            Speed          = NumberRange.new(0.5, 1.5),
            Lifetime       = NumberRange.new(0.5, 1.0),
            LightEmission  = 0.2,
            TargetParts    = { "HumanoidRootPart" },
        },
        InvincibleFlash = {
            ParticleColor  = Color3.fromRGB(255, 255, 255),
            Rate           = 50,
            Speed          = NumberRange.new(5, 10),
            Lifetime       = NumberRange.new(0.1, 0.2),
            LightEmission  = 1.0,
            LightColor     = Color3.fromRGB(255, 255, 255),
            LightBrightness = 3,
            LightRange     = 10,
            TargetParts    = { "HumanoidRootPart" },
        },
    }

    local p = presets[presetName]
    if not p then
        warn("AuraEffect: Unknown preset " .. tostring(presetName))
        return function() end
    end
    return AuraEffect.Attach(character, p)
end

return AuraEffect
