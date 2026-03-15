--[[
    AnimationManager.lua  —  Steps 10 & 14
    Central animation controller. Handles:
      - Loading Animation objects from ID strings
      - Playing with priority, fade, and speed
      - Stopping individual tracks or all tracks
      - Track caching per character to avoid reload overhead
      - Blend weight management (idle, move, ability layers)

    Priorities used:
      Idle/Move  = Enum.AnimationPriority.Core
      Ability    = Enum.AnimationPriority.Action
      Ult Cinematic = Enum.AnimationPriority.Action4  (highest)

    Usage:
      local AnimationManager = require(...)
      local mgr = AnimationManager.new(character)
      mgr:Play("OakShield")           -- plays by ability name
      mgr:PlayId("rbxassetid://123")  -- plays by raw asset ID
      mgr:Stop("OakShield")
      mgr:StopAll()
--]]

local AnimationManager = {}
AnimationManager.__index = AnimationManager

local PRIORITY = {
    core    = Enum.AnimationPriority.Core,
    action  = Enum.AnimationPriority.Action,
    action2 = Enum.AnimationPriority.Action2,
    action3 = Enum.AnimationPriority.Action3,
    action4 = Enum.AnimationPriority.Action4,
}

function AnimationManager.new(character, characterName)
    local self       = setmetatable({}, AnimationManager)
    self.Character   = character
    self.Name        = characterName
    self._cache      = {}   -- animId -> Animation instance
    self._tracks     = {}   -- animId -> AnimationTrack
    self._namedTracks = {}  -- abilityName -> animId (populated from AnimIds module)
    self._animator   = nil

    -- Find or wait for animator
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        self._animator = humanoid:FindFirstChildOfClass("Animator")
        if not self._animator then
            self._animator = Instance.new("Animator")
            self._animator.Parent = humanoid
        end
    end

    -- Load character-specific anim ID table
    if characterName then
        local ok, animIds = pcall(function()
            return require(script.Parent.AnimIds[characterName .. "_AnimIds"])
        end)
        if ok and animIds then
            self._namedTracks = animIds
        else
            warn("AnimationManager: Could not load AnimIds for " .. tostring(characterName))
        end
    end

    return self
end

-- Play by ability name (looks up ID from the character's AnimIds table)
function AnimationManager:Play(abilityName, options)
    local animId = self._namedTracks[abilityName]
    if not animId then
        -- warn("AnimationManager: No anim ID for ability '" .. tostring(abilityName) .. "'")
        return nil
    end
    return self:PlayId(animId, abilityName, options)
end

--[[
    PlayId(animId, trackName, options)
    options = {
        priority  : string   -- "core"|"action"|"action2"|"action3"|"action4"
        fadeTime  : number   -- blend in time (default 0.1)
        speed     : number   -- playback speed multiplier (default 1.0)
        weight    : number   -- blend weight (default 1.0)
        looped    : boolean  -- override looping
        onStop    : function -- callback when track ends naturally
    }
    Returns the AnimationTrack.
--]]
function AnimationManager:PlayId(animId, trackName, options)
    if not self._animator then return nil end
    options   = options or {}
    trackName = trackName or animId

    -- Stop existing track for this name if any
    self:Stop(trackName)

    -- Load (or retrieve cached) Animation object
    local anim = self._cache[animId]
    if not anim then
        anim = Instance.new("Animation")
        anim.AnimationId = animId
        anim.Parent      = self._animator
        self._cache[animId] = anim
    end

    local track = self._animator:LoadAnimation(anim)

    -- Apply options
    track.Priority  = PRIORITY[options.priority or "action"] or PRIORITY.action
    if options.looped ~= nil then track.Looped = options.looped end

    local fadeTime = options.fadeTime or 0.1
    local speed    = options.speed    or 1.0
    local weight   = options.weight   or 1.0

    track:Play(fadeTime, weight, speed)

    self._tracks[trackName] = track

    -- Auto-cleanup when track ends
    track.Stopped:Connect(function()
        if self._tracks[trackName] == track then
            self._tracks[trackName] = nil
        end
    end)

    -- Optional callback
    if options.onStop then
        track.Stopped:Once(options.onStop)
    end

    return track
end

-- Stop a named track
function AnimationManager:Stop(trackName, fadeTime)
    local track = self._tracks[trackName]
    if track and track.IsPlaying then
        track:Stop(fadeTime or 0.1)
    end
    self._tracks[trackName] = nil
end

-- Stop all currently playing tracks
function AnimationManager:StopAll(fadeTime)
    for name, track in pairs(self._tracks) do
        if track and track.IsPlaying then
            track:Stop(fadeTime or 0.15)
        end
    end
    self._tracks = {}
end

-- Check if a named anim is currently playing
function AnimationManager:IsPlaying(trackName)
    local track = self._tracks[trackName]
    return track ~= nil and track.IsPlaying
end

-- Get the raw track (for Marker events, etc.)
function AnimationManager:GetTrack(trackName)
    return self._tracks[trackName]
end

-- Get time position of a playing track
function AnimationManager:GetTimePosition(trackName)
    local track = self._tracks[trackName]
    return track and track.TimePosition or 0
end

function AnimationManager:Destroy()
    self:StopAll(0)
    -- Clear cache
    for _, anim in pairs(self._cache) do
        if anim and anim.Parent then anim:Destroy() end
    end
    self._cache  = {}
    self._tracks = {}
end

return AnimationManager
