--[[
    MatchTimer.lua
    Per-round countdown timer. Fires events on the MatchEventBus.

    Events fired:
      TimerTick(secondsRemaining)   — every second while running
      TimerExpired()                — when it reaches 0

    Usage:
      MatchTimer.Init(eventBus)
      MatchTimer.Start(180)    -- start 3-minute round timer
      MatchTimer.Stop()        -- cancel (e.g. round ended early)
      MatchTimer.GetRemaining() --> number
--]]

local MatchTimer = {}

local eventBus = nil
local running  = false
local remaining = 0

-- ── Init ───────────────────────────────────────────────────────────────────

function MatchTimer.Init(bus)
    eventBus  = bus
    running   = false
    remaining = 0
end

-- ── Public ─────────────────────────────────────────────────────────────────

function MatchTimer.Start(durationSec)
    MatchTimer.Stop()
    if durationSec <= 0 then return end

    remaining = durationSec
    running   = true

    task.spawn(function()
        while running and remaining > 0 do
            task.wait(1)
            if not running then break end

            remaining = remaining - 1

            if eventBus then
                eventBus.Fire("TimerTick", remaining)
            end

            if remaining <= 0 then
                running = false
                if eventBus then
                    eventBus.Fire("TimerExpired")
                end
            end
        end
    end)
end

function MatchTimer.Stop()
    running   = false
    remaining = 0
end

function MatchTimer.Pause()
    running = false
end

-- Resume after Pause (does NOT restart from full duration).
function MatchTimer.Resume()
    if remaining > 0 and not running then
        running = true
        task.spawn(function()
            while running and remaining > 0 do
                task.wait(1)
                if not running then break end

                remaining = remaining - 1

                if eventBus then
                    eventBus.Fire("TimerTick", remaining)
                end

                if remaining <= 0 then
                    running = false
                    if eventBus then
                        eventBus.Fire("TimerExpired")
                    end
                end
            end
        end)
    end
end

function MatchTimer.GetRemaining()
    return remaining
end

function MatchTimer.IsRunning()
    return running
end

return MatchTimer
