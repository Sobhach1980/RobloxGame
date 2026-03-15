--[[
    VFXHandler.lua  —  Step 15 (Client)
    Listens for VFX events fired by VFXSystem on the server and
    spawns the appropriate visual effects on the local client.

    Runs in StarterPlayerScripts.
--]]

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")

local ImpactEffect    = require(game.ReplicatedStorage.Shared.VFX.Effects.ImpactEffect)
local AuraEffect      = require(game.ReplicatedStorage.Shared.VFX.Effects.AuraEffect)
local ExplosionEffect = require(game.ReplicatedStorage.Shared.VFX.Effects.ExplosionEffect)
local ProjectileTrail = require(game.ReplicatedStorage.Shared.VFX.Effects.ProjectileTrail)

local localPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera

-- Active aura cleanup functions: character -> cleanupFn
local activeAuras = {}

local VFXHandler = {}

-- ─── Registered handlers ──────────────────────────────────────────────────
-- Map eventName -> handler function(...)

local handlers = {}

-- ─── Utility ──────────────────────────────────────────────────────────────
local function spawnMovingVFXPart(origin, direction, speed, gravity, lifetime, onArrive, presetName)
    local part = Instance.new("Part")
    part.Name        = "VFXProjectile"
    part.Anchored    = true
    part.CanCollide  = false
    part.Transparency = 1
    part.Size        = Vector3.new(0.3, 0.3, 0.3)
    part.CFrame      = CFrame.new(origin, origin + direction)
    part.Parent      = workspace

    local cleanupTrail = presetName and ProjectileTrail.Attach(part, presetName)
    local pos     = origin
    local vel     = direction.Unit * speed
    local elapsed = 0
    local conn

    conn = RunService.RenderStepped:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed >= lifetime then
            conn:Disconnect()
            if cleanupTrail then cleanupTrail() end
            if onArrive then onArrive(pos) end
            task.defer(function() if part.Parent then part:Destroy() end end)
            return
        end
        vel = vel + Vector3.new(0, -(gravity or 0) * dt, 0)
        pos = pos + vel * dt
        part.CFrame = CFrame.new(pos, pos + vel)
    end)

    return part, function()
        conn:Disconnect()
        if cleanupTrail then cleanupTrail() end
        if part.Parent then part:Destroy() end
    end
end

local function attachAndClearAura(character, presetName)
    local id = tostring(character) .. presetName
    -- Clear any existing aura of same type
    if activeAuras[id] then activeAuras[id]() end
    local cleanup = AuraEffect.AttachPreset(presetName, character)
    activeAuras[id] = cleanup
    return cleanup
end

local function clearAura(character, presetName)
    local id = tostring(character) .. presetName
    if activeAuras[id] then
        activeAuras[id]()
        activeAuras[id] = nil
    end
end

-- ─── Generic combat handlers ──────────────────────────────────────────────

handlers["MeleeHit"] = function(position, presetName)
    ImpactEffect.SpawnPreset(presetName or "SteveSlash", position)
end

handlers["ParryClash"] = function(position)
    ImpactEffect.SpawnPreset("ParryClash", position)
end

handlers["GuardBreak"] = function(position)
    ImpactEffect.SpawnPreset("GuardBreak", position)
end

-- ─── Steve handlers ───────────────────────────────────────────────────────

handlers["SteveOakShieldUp"] = function(character)
    -- Shield raise: brief white glow on front of character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    ImpactEffect.Spawn({ Position = root.Position + root.CFrame.LookVector * 2,
        Color = Color3.fromRGB(200, 200, 180), Style = "glow", Size = 1.5, Count = 8,
        Speed = NumberRange.new(2, 5) })
end

handlers["SteveOakShieldShatter"] = function(position)
    ImpactEffect.Spawn({ Position = position,
        Color = Color3.fromRGB(180, 160, 120), SecondColor = Color3.fromRGB(255,255,200),
        Size = 1.2, Count = 20, Speed = NumberRange.new(10, 25), Style = "shard",
        Lifetime = NumberRange.new(0.2, 0.5) })
end

handlers["SteveSwordSlash"] = function(position, isFirstHit)
    ImpactEffect.SpawnPreset("SteveSlash", position)
end

handlers["SteveTNTExplosion"] = function(position)
    ExplosionEffect.Spawn({ Position = position, Preset = "TNTExplosion",
        SpawnDebris = true, SpawnDecal = true })
end

handlers["SteveCreativeOverride"] = function(character, active)
    if active then
        attachAndClearAura(character, "SteveUltAura")
    else
        clearAura(character, "SteveUltAura")
    end
end

handlers["SteveWorldEditCleave"] = function(position, direction)
    -- Earth crack line VFX — series of impact effects along direction
    for i = 1, 5 do
        task.delay(i * 0.06, function()
            local pos = position + direction * (i * 3)
            ImpactEffect.Spawn({ Position = pos,
                Color = Color3.fromRGB(180, 160, 100), SecondColor = Color3.fromRGB(80,60,40),
                Size = 0.8 + i * 0.15, Count = 8, Speed = NumberRange.new(5, 15),
                Style = "smoke" })
        end)
    end
end

handlers["SteveLastBlockSlam"] = function(position)
    ExplosionEffect.Spawn({ Position = position, Preset = "SteveLastBlock",
        SpawnDebris = true, SpawnDecal = true, ScaleMult = 1.4 })
end

-- ─── Alex handlers ────────────────────────────────────────────────────────

handlers["AlexRedstonePulse"] = function(origin, direction, advancementActive)
    spawnMovingVFXPart(origin, direction, 55, 0,
        (advancementActive and 0.55 or 0.40), nil, "RedstoneBolt")
end

handlers["AlexRedstonePulseHit"] = function(position)
    ImpactEffect.SpawnPreset("AlexRedstone", position)
end

handlers["AlexEnderShiftIn"] = function(position, advancementActive)
    ImpactEffect.Spawn({ Position = position,
        Color = Color3.fromRGB(140, 0, 220), SecondColor = Color3.fromRGB(200, 150, 255),
        Size  = advancementActive and 2.0 or 1.2,
        Count = advancementActive and 30 or 18,
        Speed = NumberRange.new(8, 20), Style = "glow",
        Lifetime = NumberRange.new(0.2, 0.5) })
end

handlers["AlexAdvancement"] = function(character, active)
    if active then
        attachAndClearAura(character, "AlexAdvancement")
    else
        clearAura(character, "AlexAdvancement")
    end
end

handlers["AlexDragonFallImpact"] = function(position)
    ExplosionEffect.Spawn({ Position = position, Preset = "AlexDragonfall",
        SpawnDebris = true, SpawnDecal = true, ScaleMult = 1.3 })
end

-- ─── Zombie handlers ──────────────────────────────────────────────────────

handlers["ZombieBleedStart"] = function(character)
    attachAndClearAura(character, "ZombieBleed")
end

handlers["ZombieBleedEnd"] = function(character)
    clearAura(character, "ZombieBleed")
end

handlers["ZombiePlagueCloud"] = function(origin, direction)
    spawnMovingVFXPart(origin, direction, 18, 5,
        0.78, function(pos)
            ImpactEffect.Spawn({ Position = pos,
                Color = Color3.fromRGB(60,200,60), SecondColor = Color3.fromRGB(100,80,20),
                Size=2, Count=20, Speed=NumberRange.new(3,8), Style="smoke" })
        end, "PlagueCloud")
end

handlers["ZombiePlagueInfect"] = function(character, depth)
    if not character then return end
    attachAndClearAura(character, "ZombieBleed")
end

handlers["ZombieDecayWave"] = function(position)
    ExplosionEffect.Spawn({ Position = position, Preset = "ZombieDecayWave",
        SpawnDecal = true })
end

handlers["ZombieGraveMarch"] = function(character, active)
    if active then
        attachAndClearAura(character, "ZombieUltAura")
    else
        clearAura(character, "ZombieUltAura")
    end
end

handlers["ZombieInfectionSpread"] = function(position, radius)
    ExplosionEffect.Spawn({ Position = position, Preset = "ZombieDecayWave",
        SpawnDecal = true, ScaleMult = (radius or 10) / 8 })
end

-- ─── Enderman handlers ────────────────────────────────────────────────────

handlers["EndermanTeleportOut"] = function(position)
    ImpactEffect.Spawn({ Position = position,
        Color = Color3.fromRGB(80,0,160), SecondColor = Color3.fromRGB(0,0,0),
        Size=1.0, Count=14, Speed=NumberRange.new(8,20), Style="glow",
        Lifetime=NumberRange.new(0.1, 0.3) })
end

handlers["EndermanTeleportIn"] = function(position)
    ImpactEffect.SpawnPreset("EndermanVoid", position)
end

handlers["EndermanEnderStrikeHit"] = function(position, wasBackstab)
    ImpactEffect.SpawnPreset("EndermanVoid", position)
    if wasBackstab then
        -- Extra large burst for backstab confirmation
        ImpactEffect.Spawn({ Position = position,
            Color = Color3.fromRGB(200, 150, 255), Size=2.0, Count=25,
            Speed=NumberRange.new(15,35), Style="glow", Lifetime=NumberRange.new(0.2,0.5) })
    end
end

handlers["EndermanEnderCloakStart"] = function(character)
    -- Subtle shimmer — low-rate void particles
    attachAndClearAura(character, "EndermanUltAura")
end

handlers["EndermanEnderCloakEnd"] = function(character)
    clearAura(character, "EndermanUltAura")
end

handlers["EndermanTeleportSlamLand"] = function(position)
    ExplosionEffect.Spawn({ Position = position, Preset = "EndermanSlam",
        SpawnDebris = true, SpawnDecal = true })
end

handlers["EndermanVoidstepBlink"] = function(position, strikeIndex, isFinal)
    local size = isFinal and 1.8 or 1.0
    ImpactEffect.SpawnPreset("EndermanVoid", position)
    if isFinal then
        ExplosionEffect.Spawn({ Position = position, Preset = "EndermanSlam",
            ScaleMult = 0.6, SpawnDecal = true })
    end
end

handlers["EndermanStolenGroundImpact"] = function(position)
    ExplosionEffect.Spawn({ Position = position, Preset = "EndermanSlam",
        SpawnDebris = true, SpawnDecal = true, ScaleMult = 1.2 })
end

handlers["EndermanYouShouldntLookFinale"] = function(position)
    ExplosionEffect.Spawn({ Position = position, Preset = "EndermanSlam",
        SpawnDebris = true, SpawnDecal = true, ScaleMult = 1.6 })
end

-- ─── Skeleton handlers ────────────────────────────────────────────────────

handlers["SkeletonBoneShard"] = function(origin, direction, index)
    spawnMovingVFXPart(origin, direction, 65, 8,
        (35 / 65) + 0.05, function(pos)
            ImpactEffect.SpawnPreset("SkeletonArrow", pos)
        end, "BoneShard")
end

handlers["SkeletonBoneShardHit"] = function(position)
    ImpactEffect.SpawnPreset("SkeletonArrow", position)
end

handlers["SkeletonBoneShardEmbedded"] = function(position, direction)
    -- Small embedded shard indicator
    local shard = Instance.new("Part")
    shard.Size        = Vector3.new(0.1, 0.5, 0.1)
    shard.Anchored    = true
    shard.CanCollide  = false
    shard.Material    = Enum.Material.SmoothPlastic
    shard.Color       = Color3.fromRGB(180, 200, 200)
    shard.CFrame      = CFrame.new(position, position + direction) * CFrame.Angles(math.pi/2, 0, 0)
    shard.Parent      = workspace
    game:GetService("Debris"):AddItem(shard, 3)
end

handlers["SkeletonArrowStormArrow"] = function(origin, target)
    local dir = (target - origin).Unit
    spawnMovingVFXPart(origin, dir, 50, 0,
        (target - origin).Magnitude / 50 + 0.05,
        function(pos)
            ImpactEffect.SpawnPreset("SkeletonArrow", pos)
        end, "SkeletonArrow")
end

handlers["SkeletonArrowStormImpact"] = function(position)
    ImpactEffect.SpawnPreset("SkeletonArrow", position)
end

handlers["SkeletonTrapTriggered"] = function(position)
    ImpactEffect.Spawn({ Position = position,
        Color = Color3.fromRGB(180, 220, 255), SecondColor = Color3.fromRGB(200, 240, 255),
        Size=1.0, Count=16, Speed=NumberRange.new(8,20), Style="spark",
        Lifetime=NumberRange.new(0.2, 0.4) })
end

handlers["SkeletonAimbotArrow"] = function(origin, direction)
    spawnMovingVFXPart(origin, direction, 50, 0, 0.8,
        function(pos)
            ImpactEffect.SpawnPreset("SkeletonArrow", pos)
        end, "HomingArrow")
end

handlers["SkeletonAimbotHit"] = function(position)
    ImpactEffect.SpawnPreset("SkeletonArrow", position)
end

handlers["SkeletonBonebreakerFire"] = function(origin, direction)
    spawnMovingVFXPart(origin, direction, 200, 0,
        (80 / 200) + 0.01,
        function(pos)
            -- impact handled by BonebreakerHit event
        end, "BonebreakerSpear")
end

handlers["SkeletonBonebreakerHit"] = function(position)
    ExplosionEffect.Spawn({ Position = position, Preset = "SkeletonBonebreaker",
        SpawnDecal = true, SpawnDebris = true })
end

handlers["SkeletonBonebreakerShardCone"] = function(position, direction, angle)
    ImpactEffect.Spawn({ Position = position,
        Color = Color3.fromRGB(160, 230, 255), SecondColor = Color3.fromRGB(255,255,255),
        Size=1.4, Count=25, Speed=NumberRange.new(15, 40), Style="spark",
        Lifetime=NumberRange.new(0.15, 0.4) })
end

handlers["SkeletonPerfectAimProtocol"] = function(character, active)
    if active then
        attachAndClearAura(character, "SkeletonUltAura")
    else
        clearAura(character, "SkeletonUltAura")
    end
end

-- ─── Ultimate form aura handlers ──────────────────────────────────────────

handlers["SteveUltForm"] = function(character, active)
    if active then attachAndClearAura(character, "SteveUltAura")
    else           clearAura(character, "SteveUltAura") end
end

handlers["AlexUltForm"] = function(character, active)
    if active then attachAndClearAura(character, "AlexUltAura")
    else           clearAura(character, "AlexUltAura") end
end

handlers["ZombieUltForm"] = function(character, active)
    if active then attachAndClearAura(character, "ZombieUltAura")
    else           clearAura(character, "ZombieUltAura") end
end

handlers["EndermanUltForm"] = function(character, active)
    if active then attachAndClearAura(character, "EndermanUltAura")
    else           clearAura(character, "EndermanUltAura") end
end

handlers["SkeletonUltForm"] = function(character, active)
    if active then attachAndClearAura(character, "SkeletonUltAura")
    else           clearAura(character, "SkeletonUltAura") end
end

-- ─── Bind to RemoteEvent ──────────────────────────────────────────────────

function VFXHandler.Init(vfxRemoteEvent)
    vfxRemoteEvent.OnClientEvent:Connect(function(eventName, ...)
        local handler = handlers[eventName]
        if handler then
            local ok, err = pcall(handler, ...)
            if not ok then
                warn("VFXHandler [" .. eventName .. "] error: " .. tostring(err))
            end
        end
    end)
end

return VFXHandler
