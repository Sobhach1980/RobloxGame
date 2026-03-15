--[[
    CinematicCamera.lua  —  Step 12
    Client-side camera controller for cinematic sequences.
    Temporarily overrides the player camera with scripted shots.

    Sequence types:
      "orbit"   — smoothly orbit around a subject
      "dolly"   — push toward / pull back from a point
      "cut"     — instant cut to a CFrame
      "pan"     — sweep across a horizontal arc
      "shake"   — additive camera shake (overlaid on any other shot)
      "restore" — smoothly return control to the player

    Usage (client script):
      local cam = CinematicCamera.new()
      cam:Play("orbit", { subject = char.HumanoidRootPart, duration = 2.5, radius = 12 })
      cam:Play("restore", { duration = 0.5 })
--]]

local CinematicCamera = {}
CinematicCamera.__index = CinematicCamera

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local camera       = workspace.CurrentCamera

-- Shake parameters
local SHAKE_DECAY = 8   -- speed at which shake fades

function CinematicCamera.new()
    local self        = setmetatable({}, CinematicCamera)
    self._active      = false
    self._conn        = nil
    self._shakeOffset = CFrame.new()
    self._shakeAmt    = 0
    self._prevCamType = camera.CameraType
    self._prevCamCF   = camera.CFrame
    return self
end

--[[
    Play(sequenceType, config)
    Blocks camera control and runs the specified shot.

    Shared config fields:
      duration : number   (seconds for the shot)
      onDone   : function (called when sequence ends)
--]]
function CinematicCamera:Play(sequenceType, config)
    config = config or {}
    self:_stop()

    -- Scriptable camera
    camera.CameraType = Enum.CameraType.Scriptable

    if sequenceType == "orbit" then
        self:_orbit(config)
    elseif sequenceType == "dolly" then
        self:_dolly(config)
    elseif sequenceType == "cut" then
        self:_cut(config)
    elseif sequenceType == "pan" then
        self:_pan(config)
    elseif sequenceType == "shake" then
        self:_addShake(config.amount or 1.0)
    elseif sequenceType == "restore" then
        self:_restore(config)
    end
end

-- ─── Orbit ────────────────────────────────────────────────────────────────
-- Smoothly circles around a subject part.
-- config: { subject, duration, radius, height, speed, startAngle }
function CinematicCamera:_orbit(config)
    local subject  = config.subject
    if not subject then return end
    local duration = config.duration or 2.0
    local radius   = config.radius   or 10
    local height   = config.height   or 4
    local speed    = config.speed    or 1.0   -- rotations per second
    local angle    = config.startAngle or 0

    local elapsed  = 0
    self._active   = true

    self._conn = RunService.RenderStepped:Connect(function(dt)
        if not self._active then return end
        elapsed = elapsed + dt
        angle   = angle + (math.pi * 2 * speed * dt)

        local subjectPos = subject.Position
        local camPos = subjectPos + Vector3.new(
            math.cos(angle) * radius,
            height,
            math.sin(angle) * radius
        )

        camera.CFrame = CFrame.lookAt(camPos, subjectPos) * self._shakeOffset

        if elapsed >= duration then
            self:_stop()
            if config.onDone then config.onDone() end
        end
    end)
end

-- ─── Dolly ────────────────────────────────────────────────────────────────
-- Pushes camera from startPos toward endPos over duration.
-- config: { startCF, endCF, duration, easingStyle }
function CinematicCamera:_dolly(config)
    local startCF = config.startCF or camera.CFrame
    local endCF   = config.endCF   or camera.CFrame
    local duration = config.duration or 1.0
    local style   = Enum.EasingStyle[config.easingStyle or "Sine"]

    camera.CFrame = startCF
    self._active  = true

    local info  = TweenInfo.new(duration, style, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(camera, info, { CFrame = endCF })
    tween:Play()

    tween.Completed:Connect(function()
        self:_stop()
        if config.onDone then config.onDone() end
    end)
end

-- ─── Cut ──────────────────────────────────────────────────────────────────
-- Instant camera cut to a CFrame, holds for duration.
function CinematicCamera:_cut(config)
    camera.CFrame = config.targetCF or camera.CFrame
    self._active  = true

    task.delay(config.duration or 0.5, function()
        self:_stop()
        if config.onDone then config.onDone() end
    end)
end

-- ─── Pan ──────────────────────────────────────────────────────────────────
-- Sweeps camera horizontally across an arc.
-- config: { centerPos, radius, height, startAngle, endAngle, lookAt, duration }
function CinematicCamera:_pan(config)
    local center    = config.centerPos or Vector3.new(0,0,0)
    local radius    = config.radius    or 12
    local height    = config.height    or 5
    local startAng  = config.startAngle or 0
    local endAng    = config.endAngle  or math.pi
    local lookAt    = config.lookAt    or center
    local duration  = config.duration  or 2.0
    local elapsed   = 0
    self._active    = true

    self._conn = RunService.RenderStepped:Connect(function(dt)
        if not self._active then return end
        elapsed = elapsed + dt
        local t   = math.min(1, elapsed / duration)
        local ang = startAng + (endAng - startAng) * t

        local camPos = center + Vector3.new(
            math.cos(ang) * radius, height, math.sin(ang) * radius
        )
        camera.CFrame = CFrame.lookAt(camPos, lookAt) * self._shakeOffset

        if elapsed >= duration then
            self:_stop()
            if config.onDone then config.onDone() end
        end
    end)
end

-- ─── Shake (additive, overlaid) ───────────────────────────────────────────
function CinematicCamera:_addShake(amount)
    self._shakeAmt = self._shakeAmt + amount

    if self._shakeConn then return end -- already decaying

    self._shakeConn = RunService.RenderStepped:Connect(function(dt)
        self._shakeAmt = math.max(0, self._shakeAmt - SHAKE_DECAY * dt)

        local rx = (math.random() - 0.5) * 2 * self._shakeAmt * 0.05
        local ry = (math.random() - 0.5) * 2 * self._shakeAmt * 0.05
        local rz = (math.random() - 0.5) * 2 * self._shakeAmt * 0.02
        self._shakeOffset = CFrame.Angles(rx, ry, rz)

        if self._shakeAmt <= 0 then
            self._shakeOffset = CFrame.new()
            self._shakeConn:Disconnect()
            self._shakeConn = nil
        end
    end)
end

-- ─── Restore ──────────────────────────────────────────────────────────────
-- Smoothly hand back camera control to the player.
function CinematicCamera:_restore(config)
    local duration = config.duration or 0.4
    local info     = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    -- Tween FOV back to default just in case
    TweenService:Create(camera, info, { FieldOfView = 70 }):Play()

    task.delay(duration, function()
        camera.CameraType = Enum.CameraType.Custom
        if config.onDone then config.onDone() end
    end)
end

-- ─── FOV pulse ────────────────────────────────────────────────────────────
-- Quick FOV zoom-out + return for impact emphasis.
function CinematicCamera:PulseFOV(targetFOV, duration)
    targetFOV = targetFOV or 85
    duration  = duration  or 0.25
    local baseFOV = camera.FieldOfView

    local outInfo = TweenInfo.new(duration * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local inInfo  = TweenInfo.new(duration * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    local outTween = TweenService:Create(camera, outInfo, { FieldOfView = targetFOV })
    outTween:Play()
    outTween.Completed:Once(function()
        TweenService:Create(camera, inInfo, { FieldOfView = baseFOV }):Play()
    end)
end

-- ─── Internal stop ────────────────────────────────────────────────────────
function CinematicCamera:_stop()
    self._active = false
    if self._conn then
        self._conn:Disconnect()
        self._conn = nil
    end
end

function CinematicCamera:Destroy()
    self:_stop()
    if self._shakeConn then
        self._shakeConn:Disconnect()
    end
    camera.CameraType = Enum.CameraType.Custom
end

return CinematicCamera
