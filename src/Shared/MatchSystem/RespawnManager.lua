--[[
    RespawnManager.lua
    Handles delayed respawn for players who die mid-round.

    Respawn only happens if:
      • The match state is still "Fighting"
      • The player still has stocks remaining (checked just before load)

    If either condition fails the respawn is silently cancelled, because
    RoundManager will have already ended the round.

    Usage (MatchServer):
      RespawnManager.Init(stateMachine, roundManager, arenaManager, eventBus)
      RespawnManager.QueueRespawn(player)
--]]

local RespawnManager = {}

local RESPAWN_DELAY = 3   -- seconds before LoadCharacter is called

local stateMachine = nil
local roundManager = nil
local arenaManager = nil
local eventBus     = nil

-- ── Init ───────────────────────────────────────────────────────────────────

function RespawnManager.Init(sm, rm, am, bus)
    stateMachine = sm
    roundManager = rm
    arenaManager = am
    eventBus     = bus
end

-- ── Public ─────────────────────────────────────────────────────────────────

function RespawnManager.QueueRespawn(player)
    task.delay(RESPAWN_DELAY, function()
        RespawnManager._TryRespawn(player)
    end)
end

-- ── Internal ───────────────────────────────────────────────────────────────

function RespawnManager._TryRespawn(player)
    -- Safety: player must still be in-game
    if not player or not player.Parent then return end

    -- Only respawn during an active round
    if stateMachine and not stateMachine.Is("Fighting") then return end

    -- Only respawn if the player still has stocks left
    if roundManager and roundManager.GetStocks(player) <= 0 then return end

    -- Re-load the character (triggers CharacterAdded → GameServer.onCharacterAdded)
    player:LoadCharacter()

    -- Teleport to assigned spawn point once the character is ready
    local character = player.CharacterAdded:Wait()
    if not character then return end

    local root = character:WaitForChild("HumanoidRootPart", 5)
    if root and arenaManager then
        local spawnCFrame = arenaManager.GetSpawnPoint(player)
        if spawnCFrame then
            root.CFrame = spawnCFrame
        end
    end

    if eventBus then
        eventBus.Fire("PlayerRespawned", player)
    end
end

return RespawnManager
