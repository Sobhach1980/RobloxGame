--[[
    DeathHandler.lua
    Watches in-match characters for Humanoid.Died and blast-zone falls.

    On death:
      1. Fires VFX death burst at the character's root position
      2. Notifies RoundManager (stock deducted)
      3. Fires PlayerDied on the event bus (for UI/sound)
      4. Queues a respawn via RespawnManager

    Blast-zone check:
      ArenaManager calls DeathHandler.CheckBlastZone(player, blastY)
      every Heartbeat. If the character's root is below blastY, they are
      instantly killed with TakeDamage(MaxHealth).

    Usage (MatchServer):
      DeathHandler.Init(roundManager, respawnManager, vfxSystem, eventBus)
      DeathHandler.WatchPlayer(player)
      DeathHandler.UnwatchPlayer(player)
--]]

local Players    = game:GetService("Players")

local DeathHandler = {}

local roundManager  = nil
local respawnMgr    = nil
local vfxSystem     = nil
local eventBus      = nil
local connections   = {}   -- [Player] = RBXScriptConnection

-- ── Init ───────────────────────────────────────────────────────────────────

function DeathHandler.Init(rm, rsm, vfx, bus)
    roundManager = rm
    respawnMgr   = rsm
    vfxSystem    = vfx
    eventBus     = bus
    connections  = {}
end

-- ── Watch / unwatch ────────────────────────────────────────────────────────

function DeathHandler.WatchPlayer(player)
    DeathHandler.UnwatchPlayer(player)   -- clear stale connection first

    local character = player.Character
    if not character then return end

    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end

    local conn = humanoid.Died:Connect(function()
        DeathHandler._OnDied(player, character)
    end)

    connections[player] = conn
end

function DeathHandler.UnwatchPlayer(player)
    local c = connections[player]
    if c then
        c:Disconnect()
        connections[player] = nil
    end
end

-- ── Internal death handler ─────────────────────────────────────────────────

function DeathHandler._OnDied(player, character)
    -- VFX death burst
    if vfxSystem then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            vfxSystem.PlayAt("DeathBurst", root.Position)
        end
    end

    -- Deduct a stock
    if roundManager then
        roundManager.OnPlayerDied(player)
    end

    -- Broadcast for UI / sound
    if eventBus then
        eventBus.Fire("PlayerDied", player, character)
    end

    -- Queue respawn (RespawnManager checks state before loading)
    if respawnMgr then
        respawnMgr.QueueRespawn(player)
    end
end

-- ── Blast-zone check ───────────────────────────────────────────────────────

-- Called from ArenaManager's Heartbeat loop.
-- If the character's root is below blastZoneY → instant-kill.
function DeathHandler.CheckBlastZone(player, blastZoneY)
    local char = player.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if root.Position.Y < blastZoneY then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            humanoid:TakeDamage(humanoid.MaxHealth)
        end
    end
end

return DeathHandler
