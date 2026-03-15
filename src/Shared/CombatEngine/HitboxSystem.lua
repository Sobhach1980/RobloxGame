--[[
    HitboxSystem.lua
    Unified hit detection for all attack types:
      - Melee hitboxes (cones / boxes)
      - Projectile hitboxes
      - AoE circles / spheres
      - Lingering hazard zones
      - Raycast / hitscan

    Works against: live players, NPC enemies, training dummy,
    NPC summons, and environment destructibles.
--]]

local HitboxSystem = {}

-- Tags that mark valid hittable targets
local HITTABLE_TAGS = {
    Player      = true,
    NPC         = true,
    Dummy       = true,
    Summon      = true,
    Destructible= true,
}

-- Internal: collect all models containing a BasePart at position
local function getHumanoidRootFromPart(part)
    local model = part:FindFirstAncestorOfClass("Model")
    if model then
        return model:FindFirstChildOfClass("Humanoid"), model
    end
    return nil, nil
end

-- Prevent hitting the same target twice per hitbox instance
local function makeHitSet()
    return {}
end

local function alreadyHit(hitSet, model)
    return hitSet[model] == true
end

local function markHit(hitSet, model)
    hitSet[model] = true
end

--[[
    SpawnMeleeHitbox(config)
    config = {
        Position    : Vector3
        Size        : Vector3
        Duration    : number         -- seconds hitbox is active
        Attacker    : Model          -- ignored from self-hit
        OnHit       : function(victimModel)
        PierceCount : number|nil     -- max targets; nil = unlimited
    }
--]]
function HitboxSystem.SpawnMeleeHitbox(config)
    local hitSet     = makeHitSet()
    local pierceMax  = config.PierceCount or math.huge
    local hitCount   = 0
    local startTime  = tick()

    -- Create invisible part as hitbox visualizer / overlap source
    local box = Instance.new("Part")
    box.Name          = "MeleeHitbox"
    box.Size          = config.Size
    box.CFrame        = CFrame.new(config.Position)
    box.Transparency  = 1
    box.CanCollide    = false
    box.Anchored      = true
    box.Parent        = workspace

    -- Poll overlapping parts each frame for the duration
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        if tick() - startTime >= config.Duration then
            connection:Disconnect()
            box:Destroy()
            return
        end
        if hitCount >= pierceMax then
            connection:Disconnect()
            box:Destroy()
            return
        end

        local overlapParams = OverlapParams.new()
        overlapParams.FilterDescendantsInstances = {config.Attacker}
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude

        local parts = workspace:GetPartsInPart(box, overlapParams)
        for _, part in ipairs(parts) do
            local hum, model = getHumanoidRootFromPart(part)
            if hum and model and not alreadyHit(hitSet, model) then
                -- Validate tag
                local tag = model:GetAttribute("HittableTag")
                if tag and HITTABLE_TAGS[tag] then
                    markHit(hitSet, model)
                    hitCount = hitCount + 1
                    config.OnHit(model)
                    if hitCount >= pierceMax then break end
                end
            end
        end
    end)
end

--[[
    SpawnProjectile(config)
    config = {
        Origin      : Vector3
        Direction   : Vector3 (unit)
        Speed       : number
        MaxRange    : number
        HitboxRadius: number
        Attacker    : Model
        OnHit       : function(victimModel, hitPosition)
        OnExpire    : function()|nil
        Gravity     : number|nil    -- 0 = flat trajectory
    }
    Returns a cleanup function to destroy the projectile early.
--]]
function HitboxSystem.SpawnProjectile(config)
    local gravity   = config.Gravity or 0
    local pos       = config.Origin
    local dir       = config.Direction.Unit
    local speed     = config.Speed
    local maxRange  = config.MaxRange
    local travelled = 0
    local hitSet    = makeHitSet()
    local alive     = true

    local sphereParams = OverlapParams.new()
    sphereParams.FilterDescendantsInstances = {config.Attacker}
    sphereParams.FilterType = Enum.RaycastFilterType.Exclude

    -- Optional visual part
    local visual -- caller may attach their own visual via a RemoteEvent

    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not alive then return end

        -- Update position
        local step   = speed * dt
        travelled    = travelled + step
        pos          = pos + dir * step
        dir          = Vector3.new(dir.X, dir.Y - gravity * dt, dir.Z)

        if travelled >= maxRange then
            alive = false
            connection:Disconnect()
            if config.OnExpire then config.OnExpire() end
            return
        end

        -- Overlap check
        local parts = workspace:GetPartBoundsInRadius(pos, config.HitboxRadius, sphereParams)
        for _, part in ipairs(parts) do
            local hum, model = getHumanoidRootFromPart(part)
            if hum and model and not alreadyHit(hitSet, model) then
                local tag = model:GetAttribute("HittableTag")
                if tag and HITTABLE_TAGS[tag] then
                    alive = false
                    connection:Disconnect()
                    markHit(hitSet, model)
                    config.OnHit(model, pos)
                    return
                end
            end
        end
    end)

    return function()
        alive = false
        if connection then connection:Disconnect() end
    end
end

--[[
    SpawnAoE(config)
    Instant AoE explosion / zone check.
    config = {
        Position    : Vector3
        Radius      : number
        Attacker    : Model
        OnHit       : function(victimModel)
        MaxTargets  : number|nil
    }
--]]
function HitboxSystem.SpawnAoE(config)
    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = {config.Attacker}
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude

    local parts      = workspace:GetPartBoundsInRadius(config.Position, config.Radius, overlapParams)
    local hitSet     = makeHitSet()
    local hitCount   = 0
    local maxTargets = config.MaxTargets or math.huge

    for _, part in ipairs(parts) do
        if hitCount >= maxTargets then break end
        local hum, model = getHumanoidRootFromPart(part)
        if hum and model and not alreadyHit(hitSet, model) then
            local tag = model:GetAttribute("HittableTag")
            if tag and HITTABLE_TAGS[tag] then
                markHit(hitSet, model)
                hitCount = hitCount + 1
                config.OnHit(model)
            end
        end
    end
end

--[[
    SpawnLingeringZone(config)
    A zone that ticks damage / effects over time.
    config = {
        Position    : Vector3
        Size        : Vector3
        Duration    : number
        TickInterval: number
        Attacker    : Model
        OnTick      : function(victimModel)   -- called each interval per target
    }
    Returns cleanup function.
--]]
function HitboxSystem.SpawnLingeringZone(config)
    local alive     = true
    local elapsed   = 0
    local nextTick  = 0

    local box = Instance.new("Part")
    box.Name         = "LingeringZone"
    box.Size         = config.Size
    box.CFrame       = CFrame.new(config.Position)
    box.Transparency = 1
    box.CanCollide   = false
    box.Anchored     = true
    box.Parent       = workspace

    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = {config.Attacker}
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude

    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not alive then return end
        elapsed  = elapsed  + dt
        nextTick = nextTick + dt

        if elapsed >= config.Duration then
            alive = false
            connection:Disconnect()
            box:Destroy()
            return
        end

        if nextTick >= config.TickInterval then
            nextTick = 0
            local parts = workspace:GetPartsInPart(box, overlapParams)
            local seen  = {}
            for _, part in ipairs(parts) do
                local hum, model = getHumanoidRootFromPart(part)
                if hum and model and not seen[model] then
                    local tag = model:GetAttribute("HittableTag")
                    if tag and HITTABLE_TAGS[tag] then
                        seen[model] = true
                        config.OnTick(model)
                    end
                end
            end
        end
    end)

    return function()
        alive = false
        if connection then connection:Disconnect() end
        if box and box.Parent then box:Destroy() end
    end
end

--[[
    Raycast(config)
    Hitscan line check (e.g. Skeleton arrows in close-range mode).
    config = {
        Origin      : Vector3
        Direction   : Vector3 (unit)
        MaxRange    : number
        Attacker    : Model
        OnHit       : function(victimModel, hitPosition)
        OnMiss      : function()|nil
    }
--]]
function HitboxSystem.Raycast(config)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {config.Attacker}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(
        config.Origin,
        config.Direction.Unit * config.MaxRange,
        rayParams
    )

    if result then
        local hum, model = getHumanoidRootFromPart(result.Instance)
        if hum and model then
            local tag = model:GetAttribute("HittableTag")
            if tag and HITTABLE_TAGS[tag] then
                config.OnHit(model, result.Position)
                return
            end
        end
    end

    if config.OnMiss then config.OnMiss() end
end

return HitboxSystem
