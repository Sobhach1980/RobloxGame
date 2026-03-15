--[[
    ImpactEffect.lua  —  Step 15
    Client-side impact burst effect.
    Used for melee hits, projectile impacts, and AoE detonations.

    Spawns a short-lived Part with ParticleEmitters that burst on creation
    then auto-destroy. Configurable per character and per hit type.
--]]

local Debris = game:GetService("Debris")

local ImpactEffect = {}

--[[
    Spawn(config)
    config = {
        Position    : Vector3
        Color       : Color3           -- primary particle color
        SecondColor : Color3|nil       -- secondary (sparkle) color
        Size        : number           -- 1.0 = standard
        Count       : number           -- particle burst count
        Speed       : NumberRange      -- particle speed
        Spread      : number           -- cone spread in degrees
        Lifetime    : NumberRange      -- particle lifetime
        Style       : string          -- "spark"|"smoke"|"glow"|"shard"|"explosion"
    }
--]]
function ImpactEffect.Spawn(config)
    local pos     = config.Position   or Vector3.new(0, 0, 0)
    local color   = config.Color      or Color3.fromRGB(255, 255, 255)
    local color2  = config.SecondColor or color
    local sz      = config.Size       or 1.0
    local count   = config.Count      or 12
    local speed   = config.Speed      or NumberRange.new(8, 20)
    local spread  = config.Spread     or 45
    local life    = config.Lifetime   or NumberRange.new(0.2, 0.5)
    local style   = config.Style      or "spark"

    -- Invisible root part
    local root = Instance.new("Part")
    root.Name        = "ImpactFX"
    root.Anchored    = true
    root.CanCollide  = false
    root.Transparency = 1
    root.Size        = Vector3.new(0.1, 0.1, 0.1)
    root.CFrame      = CFrame.new(pos)
    root.Parent      = workspace

    -- Primary particle emitter
    local pe1 = Instance.new("ParticleEmitter")
    pe1.Color       = ColorSequence.new({ ColorSequenceKeypoint.new(0, color), ColorSequenceKeypoint.new(1, color2) })
    pe1.Size        = NumberSequence.new({ NumberSequenceKeypoint.new(0, sz * 0.3), NumberSequenceKeypoint.new(1, 0) })
    pe1.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.3), NumberSequenceKeypoint.new(1, 1) })
    pe1.Speed       = speed
    pe1.SpreadAngle = Vector2.new(spread, spread)
    pe1.Lifetime    = life
    pe1.Rate        = 0
    pe1.LightEmission = (style == "glow" or style == "explosion") and 0.8 or 0.2
    pe1.LightInfluence = 0.5

    if style == "smoke" then
        pe1.RotSpeed = NumberRange.new(-45, 45)
        pe1.Rotation = NumberRange.new(0, 360)
        pe1.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
    elseif style == "explosion" then
        pe1.Size   = NumberSequence.new({ NumberSequenceKeypoint.new(0, sz * 1.5), NumberSequenceKeypoint.new(0.4, sz * 0.8), NumberSequenceKeypoint.new(1, 0) })
        pe1.Speed  = NumberRange.new(speed.Min * 0.5, speed.Max * 0.5)
    end

    pe1.Parent = root

    -- Sparkle secondary emitter
    if style ~= "smoke" then
        local pe2 = Instance.new("ParticleEmitter")
        pe2.Color       = ColorSequence.new(color2)
        pe2.Size        = NumberSequence.new({ NumberSequenceKeypoint.new(0, sz * 0.1), NumberSequenceKeypoint.new(1, 0) })
        pe2.Speed       = NumberRange.new(speed.Max * 0.6, speed.Max * 1.4)
        pe2.SpreadAngle = Vector2.new(90, 90)
        pe2.Lifetime    = NumberRange.new(life.Min * 0.5, life.Max * 0.8)
        pe2.Rate        = 0
        pe2.LightEmission = 1
        pe2.Parent      = root
        pe2:Emit(math.floor(count * 0.4))
    end

    -- Burst
    pe1:Emit(count)

    -- Billboard glow flash
    if style == "glow" or style == "explosion" then
        local bb = Instance.new("BillboardGui")
        bb.Size      = UDim2.new(0, sz * 80, 0, sz * 80)
        bb.AlwaysOnTop = false
        bb.Parent    = root
        local img = Instance.new("ImageLabel", bb)
        img.Size             = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.Image            = "rbxassetid://GLOW_FLARE_ASSET"
        img.ImageColor3      = color
        img.ImageTransparency = 0

        -- Fade out the flash
        local TweenService = game:GetService("TweenService")
        TweenService:Create(img, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { ImageTransparency = 1 }):Play()
    end

    -- Auto-cleanup
    Debris:AddItem(root, life.Max + 0.5)

    return root
end

-- Pre-built presets for common impact types
function ImpactEffect.SpawnPreset(presetName, position)
    local presets = {
        SteveSlash = {
            Color = Color3.fromRGB(220, 230, 255), SecondColor = Color3.fromRGB(150, 160, 255),
            Size = 1.0, Count = 10, Speed = NumberRange.new(12, 22), Style = "spark",
        },
        SteveExplosion = {
            Color = Color3.fromRGB(255, 160, 50), SecondColor = Color3.fromRGB(255, 80, 20),
            Size = 2.5, Count = 30, Speed = NumberRange.new(20, 50), Style = "explosion",
        },
        AlexRedstone = {
            Color = Color3.fromRGB(255, 50, 50), SecondColor = Color3.fromRGB(255, 150, 150),
            Size = 0.8, Count = 14, Speed = NumberRange.new(15, 30), Style = "glow",
        },
        AlexDragon = {
            Color = Color3.fromRGB(140, 0, 220), SecondColor = Color3.fromRGB(200, 100, 255),
            Size = 3.0, Count = 40, Speed = NumberRange.new(25, 60), Style = "explosion",
        },
        ZombieDecay = {
            Color = Color3.fromRGB(50, 180, 50), SecondColor = Color3.fromRGB(100, 100, 30),
            Size = 1.5, Count = 18, Speed = NumberRange.new(8, 18), Style = "smoke",
        },
        ZombieBite = {
            Color = Color3.fromRGB(180, 255, 80), SecondColor = Color3.fromRGB(50, 200, 50),
            Size = 0.7, Count = 8, Speed = NumberRange.new(10, 20), Style = "spark",
        },
        EndermanVoid = {
            Color = Color3.fromRGB(80, 0, 160), SecondColor = Color3.fromRGB(160, 80, 255),
            Size = 1.2, Count = 16, Speed = NumberRange.new(15, 35), Style = "glow",
        },
        EndermanSlam = {
            Color = Color3.fromRGB(60, 0, 120), SecondColor = Color3.fromRGB(200, 150, 255),
            Size = 2.0, Count = 25, Speed = NumberRange.new(20, 45), Style = "explosion",
        },
        SkeletonArrow = {
            Color = Color3.fromRGB(150, 220, 255), SecondColor = Color3.fromRGB(200, 240, 255),
            Size = 0.6, Count = 8, Speed = NumberRange.new(12, 25), Style = "spark",
        },
        SkeletonBonebreaker = {
            Color = Color3.fromRGB(100, 200, 255), SecondColor = Color3.fromRGB(255, 255, 255),
            Size = 2.5, Count = 35, Speed = NumberRange.new(30, 70), Style = "explosion",
        },
        ParryClash = {
            Color = Color3.fromRGB(255, 240, 100), SecondColor = Color3.fromRGB(255, 255, 255),
            Size = 1.0, Count = 20, Speed = NumberRange.new(15, 35), Style = "spark",
        },
        GuardBreak = {
            Color = Color3.fromRGB(255, 100, 50), SecondColor = Color3.fromRGB(255, 200, 100),
            Size = 1.5, Count = 25, Speed = NumberRange.new(20, 40), Style = "explosion",
        },
    }

    local p = presets[presetName]
    if not p then
        p = { Color = Color3.new(1,1,1), Size=1, Count=10, Speed=NumberRange.new(10,20), Style="spark" }
    end
    p.Position = position
    return ImpactEffect.Spawn(p)
end

return ImpactEffect
