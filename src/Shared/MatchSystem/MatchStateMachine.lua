--[[
    MatchStateMachine.lua
    Manages the overall game-flow state transitions.

    States & allowed transitions:
      Lobby      → CharSelect
      CharSelect → Countdown | Lobby
      Countdown  → Fighting  | Lobby
      Fighting   → RoundEnd  | MatchEnd
      RoundEnd   → Countdown | MatchEnd
      MatchEnd   → Rematch   | Lobby
      Rematch    → CharSelect

    Usage (server-only):
      local MSM = require(MatchStateMachine)
      MSM.Init(matchEventBus)
      MSM.Transition("CharSelect")
      MSM.GetState()  --> "Lobby"
      MSM.Is("Fighting") --> false
--]]

local MatchStateMachine = {}

local VALID_TRANSITIONS = {
    Lobby      = { "CharSelect" },
    CharSelect = { "Countdown", "Lobby" },
    Countdown  = { "Fighting",  "Lobby" },
    Fighting   = { "RoundEnd",  "MatchEnd" },
    RoundEnd   = { "Countdown", "MatchEnd" },
    MatchEnd   = { "Rematch",   "Lobby" },
    Rematch    = { "CharSelect" },
}

local state    = "Lobby"
local eventBus = nil

function MatchStateMachine.Init(bus)
    eventBus = bus
    state    = "Lobby"
end

function MatchStateMachine.GetState()
    return state
end

function MatchStateMachine.Is(s)
    return state == s
end

-- Attempt to move to newState. Returns true on success.
function MatchStateMachine.Transition(newState)
    local allowed = VALID_TRANSITIONS[state]
    if not allowed then
        warn("MatchStateMachine: no transitions defined from state:", state)
        return false
    end

    local valid = false
    for _, s in ipairs(allowed) do
        if s == newState then valid = true; break end
    end

    if not valid then
        warn(("MatchStateMachine: invalid transition  %s → %s"):format(state, newState))
        return false
    end

    local prev = state
    state = newState

    if eventBus then
        eventBus.Fire("StateChanged", prev, newState)
    end

    return true
end

return MatchStateMachine
