--[[
    ExplosionEffect.lua  —  Step 15
    Client-side explosion / shockwave / crater visual.
    Used for TNT Toss, Last Block Standing, Dragonfall Execution,
    Decay Wave, Grave March slam, Stolen Ground, Bonebreaker impact.

    Spawns:
      - Expanding shockwave ring (scaled Part with Beam)
      - Burst ParticleEmitter
      - Optional persistent scorch/decay decal on terrain
      - Optional crater debris (small bouncing parts)
--]]

local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local ExplosionEffect = {}

--[[
    Spawn(config)
    config = {
        Position      : Vector3
        Preset        : string     -- see PRESETS below
        ScaleMult     : number     -- scale multiplier on top of preset (default 1)
        SpawnDebris   : boolean    -- spawn small debris shards
        SpawnDecal    : boolean    -- place ground scorch decal
        DecalId       : string     -- asset ID for decal texture
    }
--]]
function ExplosionEffect.Spawn(config)
    local pos       = config.Position  or Vector3.new(0, 0, 0)
    local scaleMult = config.ScaleMult or 1.0
    local preset    = config.Preset    or "Generic"

    local p = ExplosionEffect._presets()[preset] or ExplosionEffect._presets()["Generic"]

    -- ── Shockwave ring ─────────────────────────────────────────────────────
    local ring = Instance.new("Part")
    ring.Name        = "ShockwaveRing"
    ring.Anchored    = true
    ring.CanCollide  = false
    ring.CastShadow  = false
    ring.Transparency = 0.3
    ring.Size        = Vector3.new(0.5, 0.5, 0.5)
    ring.CFrame      = CFrame.new(pos)
    ring.Material    = Enum.Material.Neon
    ring.Color       = p.RingColor
    ring.Shape       = Enum.PartType.Cylinder
    ring.Parent      = workspace

    local targetSize = Vector3.new(p.RingRadius * 2 * scaleMult, 0.3, p.RingRadius * 2 * scaleMult)
    local expandInfo = TweenInfo.new(p.RingDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local expandTween = TweenService:Create(ring, expandInfo, {
        Size         = targetSize,
        Transparency = 1,
    })
    expandTween:Play()
    Debris:AddItem(ring, p.RingDuration + 0.1)

    -- ── Burst particle emitter ─────────────────────────────────────────────
    local root = Instance.new("Part")
    root.Name        = "ExplosionFX"
    root.Anchored    = true
    root.CanCollide  = false
    root.Transparency = 1
    root.Size        = Vector3.new(0.1, 0.1, 0.1)
    root.CFrame      = CFrame.new(pos)
    root.Parent      = workspace

    local function makePE(col1, col2, count, speed, life, sz, emit)
        local pe = Instance.new("ParticleEmitter")
        pe.Color        = ColorSequence.new({ ColorSequenceKeypoint.new(0, col1), ColorSequenceKeypoint.new(1, col2) })
        pe.Size         = sz
        pe.Rate         = 0
        pe.Speed        = speed
        pe.Lifetime     = life
        pe.SpreadAngle  = Vector2.new(180, 180)
        pe.LightEmission = emit or 0.6
        pe.LightInfluence = 0.5
        pe.Parent       = root
        pe:Emit(count)
    end

    makePE(p.Color1, p.Color2,
        math.floor(p.BurstCount * scaleMult),
        NumberRange.new(p.BurstSpeedMin * scaleMult, p.BurstSpeedMax * scaleMult),
        NumberRange.new(p.BurstLifeMin, p.BurstLifeMax),
        NumberSequence.new({ NumberSequenceKeypoint.new(0, p.BurstSize * scaleMult), NumberSequenceKeypoint.new(0.5, p.BurstSize * scaleMult * 0.5), NumberSequenceKeypoint.new(1, 0) }),
        p.LightEmission)

    -- Smoke secondary
    makePE(p.SmokeColor or p.Color2, Color3.fromRGB(40,40,40),
        math.floor(p.SmokeCount * scaleMult),
        NumberRange.new(3 * scaleMult, 8 * scaleMult),
        NumberRange.new(1.0, 2.5),
        NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8 * scaleMult), NumberSequenceKeypoint.new(1, 0) }),
        0.1)

    -- Point light flash
    local light = Instance.new("PointLight")
    light.Color      = p.Color1
    light.Brightness = 5 * scaleMult
    light.Range      = p.RingRadius * 3 * scaleMult
    light.Shadows    = true
    light.Parent     = root
    TweenService:Create(light, TweenInfo.new(p.BurstLifeMax, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Brightness = 0, Range = 0 }):Play()

    Debris:AddItem(root, p.BurstLifeMax + 3)

    -- ── Ground decal ───────────────────────────────────────────────────────
    if config.SpawnDecal then
        local decalPart = Instance.new("Part")
        decalPart.Anchored    = true
        decalPart.CanCollide  = false
        decalPart.Size        = Vector3.new(p.RingRadius * 2 * scaleMult, 0.05, p.RingRadius * 2 * scaleMult)
        decalPart.CFrame      = CFrame.new(pos.X, pos.Y - 0.05, pos.Z)
        decalPart.Material    = Enum.Material.SmoothPlastic
        decalPart.Color       = p.DecalColor or Color3.fromRGB(30, 30, 30)
        decalPart.Transparency = 0.2
        decalPart.Parent      = workspace

        -- Fade out over 8 seconds
        TweenService:Create(decalPart, TweenInfo.new(8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Transparency = 1 }):Play()
        Debris:AddItem(decalPart, 8.5)
    end

    -- ── Debris shards ─────────────────────────────────────────────────────
    if config.SpawnDebris then
        for i = 1, math.floor(6 * scaleMult) do
            task.defer(function()
                local shard = Instance.new("Part")
                shard.Name       = "DebrisShard"
                shard.Size       = Vector3.new(
                    math.random(3, 8) * 0.1 * scaleMult,
                    math.random(3, 8) * 0.1 * scaleMult,
                    math.random(3, 8) * 0.1 * scaleMult
                )
                shard.Material   = p.DebrisMaterial or Enum.Material.SmoothPlastic
                shard.Color      = p.DebrisColor    or Color3.fromRGB(80, 60, 40)
                shard.CFrame     = CFrame.new(pos)
                shard.Anchored   = false
                shard.CanCollide = true
                shard.Parent     = workspace

                local angle = math.random() * math.pi * 2
                local power = math.random(15, 35) * scaleMult
                shard.AssemblyLinearVelocity = Vector3.new(
                    math.cos(angle) * power, math.random(10, 25) * scaleMult, math.sin(angle) * power
                )
                shard.AssemblyAngularVelocity = Vector3.new(
                    math.random(-5, 5), math.random(-5, 5), math.random(-5, 5)
                )
                Debris:AddItem(shard, 4)
            end)
        end
    end
end

function ExplosionEffect._presets()
    return {
        Generic = {
            RingColor   = Color3.fromRGB(255, 200, 100),
            RingRadius  = 8, RingDuration = 0.4,
            Color1 = Color3.fromRGB(255, 180, 60), Color2 = Color3.fromRGB(255, 80, 20),
            BurstCount = 25, BurstSpeedMin = 15, BurstSpeedMax = 40,
            BurstLifeMin = 0.4, BurstLifeMax = 1.0, BurstSize = 1.0,
            SmokeCount = 12, LightEmission = 0.8,
            DecalColor = Color3.fromRGB(30, 20, 10),
        },
        TNTExplosion = {
            RingColor   = Color3.fromRGB(255, 120, 30),
            RingRadius  = 12, RingDuration = 0.5,
            Color1 = Color3.fromRGB(255, 160, 40), Color2 = Color3.fromRGB(255, 50, 10),
            BurstCount = 40, BurstSpeedMin = 20, BurstSpeedMax = 55,
            BurstLifeMin = 0.5, BurstLifeMax = 1.5, BurstSize = 1.8,
            SmokeCount = 20, LightEmission = 1.0,
            DecalColor = Color3.fromRGB(30, 20, 10),
            DebrisMaterial = Enum.Material.SmoothPlastic,
            DebrisColor    = Color3.fromRGB(80, 60, 40),
        },
        SteveLastBlock = {
            RingColor   = Color3.fromRGB(200, 220, 255),
            RingRadius  = 20, RingDuration = 0.7,
            Color1 = Color3.fromRGB(180, 200, 255), Color2 = Color3.fromRGB(80, 80, 80),
            BurstCount = 60, BurstSpeedMin = 25, BurstSpeedMax = 70,
            BurstLifeMin = 0.8, BurstLifeMax = 2.0, BurstSize = 2.5,
            SmokeCount = 30, LightEmission = 0.8,
            DecalColor = Color3.fromRGB(20, 20, 30),
            DebrisMaterial = Enum.Material.Concrete,
            DebrisColor    = Color3.fromRGB(100, 100, 120),
        },
        AlexDragonfall = {
            RingColor   = Color3.fromRGB(140, 0, 220),
            RingRadius  = 18, RingDuration = 0.6,
            Color1 = Color3.fromRGB(160, 40, 255), Color2 = Color3.fromRGB(80, 0, 140),
            BurstCount = 50, BurstSpeedMin = 22, BurstSpeedMax = 60,
            BurstLifeMin = 0.6, BurstLifeMax = 1.8, BurstSize = 2.2,
            SmokeCount = 25, LightEmission = 1.0,
            DecalColor = Color3.fromRGB(30, 10, 50),
            DebrisMaterial = Enum.Material.SmoothPlastic,
            DebrisColor    = Color3.fromRGB(60, 0, 100),
        },
        ZombieDecayWave = {
            RingColor   = Color3.fromRGB(50, 200, 50),
            RingRadius  = 12, RingDuration = 0.45,
            Color1 = Color3.fromRGB(60, 200, 60), Color2 = Color3.fromRGB(100, 80, 20),
            BurstCount = 30, BurstSpeedMin = 10, BurstSpeedMax = 30,
            BurstLifeMin = 0.8, BurstLifeMax = 2.0, BurstSize = 1.4,
            SmokeColor = Color3.fromRGB(60, 120, 60),
            SmokeCount = 20, LightEmission = 0.5,
            DecalColor = Color3.fromRGB(20, 50, 20),
        },
        EndermanSlam = {
            RingColor   = Color3.fromRGB(80, 0, 160),
            RingRadius  = 14, RingDuration = 0.5,
            Color1 = Color3.fromRGB(120, 0, 200), Color2 = Color3.fromRGB(200, 150, 255),
            BurstCount = 40, BurstSpeedMin = 18, BurstSpeedMax = 50,
            BurstLifeMin = 0.5, BurstLifeMax = 1.5, BurstSize = 1.8,
            SmokeCount = 20, LightEmission = 1.0,
            DecalColor = Color3.fromRGB(20, 0, 40),
            DebrisMaterial = Enum.Material.SmoothPlastic,
            DebrisColor    = Color3.fromRGB(40, 0, 80),
        },
        SkeletonBonebreaker = {
            RingColor   = Color3.fromRGB(140, 220, 255),
            RingRadius  = 10, RingDuration = 0.35,
            Color1 = Color3.fromRGB(160, 230, 255), Color2 = Color3.fromRGB(255, 255, 255),
            BurstCount = 45, BurstSpeedMin = 30, BurstSpeedMax = 80,
            BurstLifeMin = 0.3, BurstLifeMax = 0.9, BurstSize = 1.2,
            SmokeCount = 15, LightEmission = 1.0,
            DecalColor = Color3.fromRGB(20, 40, 60),
        },
    }
end

return ExplosionEffect
