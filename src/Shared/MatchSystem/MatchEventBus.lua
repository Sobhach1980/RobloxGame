--[[
    MatchEventBus.lua
    Simple synchronous event bus used by all match systems to
    communicate without hard-wiring references to each other.

    Usage:
      local bus = require(MatchEventBus)
      bus.On("RoundEnd", function(winner) ... end)
      bus.Fire("RoundEnd", winner)

    Events fired in this project:
      StateChanged(prevState, newState)
      RoundStart(roundNumber)
      RoundEnd(winnerPlayerOrNil)
      MatchEnd(winnerPlayerOrNil)
      StockLost(player, stocksRemaining)
      PlayerDied(player, character)
      PlayerRespawned(player)
      TimerTick(secondsRemaining)
      TimerExpired()
--]]

local MatchEventBus = {}

local listeners = {}   -- [eventName] = { callback, ... }

-- Subscribe to an event. Returns a handle with :Disconnect().
function MatchEventBus.On(event, callback)
    if not listeners[event] then
        listeners[event] = {}
    end
    table.insert(listeners[event], callback)

    return {
        Disconnect = function()
            local list = listeners[event]
            if not list then return end
            for i, cb in ipairs(list) do
                if cb == callback then
                    table.remove(list, i)
                    break
                end
            end
        end,
    }
end

-- Fire an event, calling all subscribed callbacks in insertion order.
function MatchEventBus.Fire(event, ...)
    local list = listeners[event]
    if not list then return end
    -- Iterate over a shallow copy so disconnects inside callbacks are safe.
    for _, cb in ipairs(table.clone(list)) do
        local ok, err = pcall(cb, ...)
        if not ok then
            warn(("MatchEventBus [%s] callback error: %s"):format(event, tostring(err)))
        end
    end
end

-- Remove all listeners for one event.
function MatchEventBus.Clear(event)
    listeners[event] = nil
end

-- Remove every listener.
function MatchEventBus.ClearAll()
    listeners = {}
end

return MatchEventBus
