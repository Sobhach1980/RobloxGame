--[[
    ProjectileTrail.lua  —  Step 15
    Attaches a Trail + ParticleEmitter to a moving part to create
    visible projectile VFX. Used for arrows, redstone bolts, bone shards,
    TNT arcs, and void blinks.

    Usage:
      local cleanup = ProjectileTrail.Attach(part, "SkeletonArrow")
      -- when projectile hits / expires:
      cleanup()
--]]

local Debris = game:GetService("Debris")

local ProjectileTrail = {}

local PRESETS = {
    -- Steve
    SteveCharge = {
        TrailColor  = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(80,80,80)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200,220,255)) }),
        TrailWidth  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) }),
        TrailLife   = 0.20,
        ParticleColor = Color3.fromRGB(150, 160, 220),
        ParticleRate  = 30,
        ParticleSize  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) }),
        ParticleLife  = NumberRange.new(0.1, 0.25),
        ParticleSpeed = NumberRange.new(1, 4),
    },
    TNTArc = {
        TrailColor  = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255,120,30)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,50,0)) }),
        TrailWidth  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }),
        TrailLife   = 0.3,
        ParticleColor = Color3.fromRGB(255, 200, 60),
        ParticleRate  = 40,
        ParticleSize  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(1, 0) }),
        ParticleLife  = NumberRange.new(0.15, 0.35),
        ParticleSpeed = NumberRange.new(2, 6),
        LightEmission = 1.0,
    },
    -- Alex
    RedstoneBolt = {
        TrailColor  = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255,50,50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,150,150)) }),
        TrailWidth  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }),
        TrailLife   = 0.12,
        ParticleColor = Color3.fromRGB(255, 80, 80),
        ParticleRate  = 60,
        ParticleSize  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) }),
        ParticleLife  = NumberRange.new(0.05, 0.15),
        ParticleSpeed = NumberRange.new(2, 8),
        LightEmission = 0.9,
    },
    -- Zombie
    PlagueCloud = {
        TrailColor  = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(50,200,50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(100,80,20)) }),
        TrailWidth  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0) }),
        TrailLife   = 0.5,
        ParticleColor = Color3.fromRGB(80, 200, 80),
        ParticleRate  = 20,
        ParticleSize  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) }),
        ParticleLife  = NumberRange.new(0.4, 0.8),
        ParticleSpeed = NumberRange.new(0.5, 2),
        LightEmission = 0.3,
    },
    -- Enderman
    VoidBlink = {
        TrailColor  = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(80,0,160)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200,150,255)) }),
        TrailWidth  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) }),
        TrailLife   = 0.15,
        ParticleColor = Color3.fromRGB(160, 80, 255),
        ParticleRate  = 80,
        ParticleSize  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) }),
        ParticleLife  = NumberRange.new(0.08, 0.2),
        ParticleSpeed = NumberRange.new(3, 10),
        LightEmission = 1.0,
    },
    TerrainChunk = {
        TrailColor  = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(100,80,60)), ColorSequenceKeypoint.new(1, Color3.fromRGB(80,0,140)) }),
        TrailWidth  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.0), NumberSequenceKeypoint.new(1, 0) }),
        TrailLife   = 0.4,
        ParticleColor = Color3.fromRGB(120, 100, 80),
        ParticleRate  = 30,
        ParticleSize  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }),
        ParticleLife  = NumberRange.new(0.3, 0.6),
        ParticleSpeed = NumberRange.new(2, 6),
        LightEmission = 0.1,
    },
    -- Skeleton
    SkeletonArrow = {
        TrailColor  = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(140,220,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200,240,255)) }),
        TrailWidth  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) }),
        TrailLife   = 0.12,
        ParticleColor = Color3.fromRGB(180, 230, 255),
        ParticleRate  = 40,
        ParticleSize  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0) }),
        ParticleLife  = NumberRange.new(0.08, 0.18),
        ParticleSpeed = NumberRange.new(3, 8),
        LightEmission = 0.8,
    },
    BoneShard = {
        TrailColor  = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(200,200,200)), ColorSequenceKeypoint.new(1, Color3.fromRGB(140,210,255)) }),
        TrailWidth  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) }),
        TrailLife   = 0.15,
        ParticleColor = Color3.fromRGB(180, 220, 255),
        ParticleRate  = 25,
        ParticleSize  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 0) }),
        ParticleLife  = NumberRange.new(0.06, 0.14),
        ParticleSpeed = NumberRange.new(2, 5),
        LightEmission = 0.6,
    },
    BonebreakerSpear = {
        TrailColor  = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(80,180,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)) }),
        TrailWidth  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.0), NumberSequenceKeypoint.new(1, 0) }),
        TrailLife   = 0.08,
        ParticleColor = Color3.fromRGB(150, 220, 255),
        ParticleRate  = 120,
        ParticleSize  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }),
        ParticleLife  = NumberRange.new(0.04, 0.10),
        ParticleSpeed = NumberRange.new(5, 15),
        LightEmission = 1.0,
    },
    HomingArrow = {
        TrailColor  = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(50,150,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200,240,255)) }),
        TrailWidth  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }),
        TrailLife   = 0.20,
        ParticleColor = Color3.fromRGB(100,200,255),
        ParticleRate  = 60,
        ParticleSize  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) }),
        ParticleLife  = NumberRange.new(0.1, 0.25),
        ParticleSpeed = NumberRange.new(3, 10),
        LightEmission = 0.9,
    },
}

--[[
    Attach(part, presetName) -> cleanupFn
    Attaches trail + particle emitter to the given part.
    Returns a function that stops and cleans up the effects.
--]]
function ProjectileTrail.Attach(part, presetName)
    local p = PRESETS[presetName]
    if not p then
        p = PRESETS.SkeletonArrow   -- fallback
    end

    local instances = {}

    -- Trail needs two attachments
    local att0 = Instance.new("Attachment")
    att0.Position = Vector3.new(0, 0, -0.5)
    att0.Parent   = part
    local att1 = Instance.new("Attachment")
    att1.Position = Vector3.new(0, 0, 0.5)
    att1.Parent   = part
    table.insert(instances, att0)
    table.insert(instances, att1)

    local trail = Instance.new("Trail")
    trail.Attachment0    = att0
    trail.Attachment1    = att1
    trail.Color          = p.TrailColor
    trail.WidthScale     = p.TrailWidth
    trail.Lifetime       = p.TrailLife
    trail.LightEmission  = p.LightEmission or 0.5
    trail.LightInfluence = 0.4
    trail.FaceCamera     = true
    trail.Parent         = part
    table.insert(instances, trail)

    -- Particle emitter
    local pe = Instance.new("ParticleEmitter")
    pe.Color         = ColorSequence.new(p.ParticleColor)
    pe.Size          = p.ParticleSize
    pe.Rate          = p.ParticleRate
    pe.Speed         = p.ParticleSpeed
    pe.Lifetime      = p.ParticleLife
    pe.SpreadAngle   = Vector2.new(15, 15)
    pe.LightEmission = p.LightEmission or 0.5
    pe.LightInfluence = 0.4
    pe.Parent        = part
    table.insert(instances, pe)

    -- Optional point light for bright projectiles
    if (p.LightEmission or 0) >= 0.6 then
        local light = Instance.new("PointLight")
        light.Color      = typeof(p.ParticleColor) == "Color3" and p.ParticleColor
                           or Color3.fromRGB(255, 255, 255)
        light.Brightness = 2
        light.Range      = 12
        light.Shadows    = false
        light.Parent     = part
        table.insert(instances, light)
    end

    return function()
        -- Stop emitting but let existing particles die
        if pe.Parent then pe.Rate = 0 end
        if trail.Parent then trail.Enabled = false end

        task.delay(p.TrailLife + (p.ParticleLife.Max or 0.3), function()
            for _, inst in ipairs(instances) do
                if inst and inst.Parent then inst:Destroy() end
            end
        end)
    end
end

return ProjectileTrail
