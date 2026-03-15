--[[
    ArenaManager.lua
    Manages arena spawn points, blast-zone detection, and per-round
    spawn rotation.

    Setup expected in Workspace:
      Workspace
        └── Arena                   [Folder]
              ├── SpawnPoint1       [SpawnLocation or BasePart]
              ├── SpawnPoint2
              └── …

    Blast zone:
      Any character whose HumanoidRootPart.Y drops below BLAST_ZONE_Y
      is instantly killed by DeathHandler.CheckBlastZone.

    Usage (MatchServer):
      ArenaManager.Init(deathHandler)
      ArenaManager.StartBlastZoneCheck()   -- begins Heartbeat loop
      ArenaManager.RegisterPlayer(player)
      ArenaManager.GetSpawnPoint(player)   --> CFrame or nil
      ArenaManager.RotateSpawns()          -- call between rounds
--]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local ArenaManager = {}

local BLAST_ZONE_Y = -100   -- studs below origin → instant KO
local ARENA_NAME   = "Arena"

local spawnPoints   = {}    -- ordered list of CFrames
local playerSpawnIdx = {}   -- [Player] = index into spawnPoints
local deathHandler  = nil
local blastConn     = nil

-- ── Init ───────────────────────────────────────────────────────────────────

function ArenaManager.Init(dh)
    deathHandler  = dh
    playerSpawnIdx = {}
    ArenaManager._LoadSpawnPoints()
end

function ArenaManager._LoadSpawnPoints()
    spawnPoints = {}
    local arena = workspace:FindFirstChild(ARENA_NAME)
    if not arena then
        warn("ArenaManager: no 'Arena' folder found in Workspace — no spawn points loaded.")
        return
    end

    -- Sort by name so SpawnPoint1, SpawnPoint2, … are in order
    local parts = {}
    for _, child in ipairs(arena:GetChildren()) do
        if child.Name:match("^SpawnPoint") then
            if child:IsA("SpawnLocation") or child:IsA("BasePart") then
                table.insert(parts, child)
            end
        end
    end
    table.sort(parts, function(a, b) return a.Name < b.Name end)

    for _, part in ipairs(parts) do
        -- Offset upward so the character spawns on top of the part
        table.insert(spawnPoints, part.CFrame + Vector3.new(0, 4, 0))
    end
end

-- ── Player registration ────────────────────────────────────────────────────

function ArenaManager.RegisterPlayer(player)
    if #spawnPoints == 0 then
        playerSpawnIdx[player] = 1
        return
    end
    -- Assign the next available spawn slot (round-robin)
    local count = 0
    for _ in pairs(playerSpawnIdx) do count = count + 1 end
    playerSpawnIdx[player] = (count % #spawnPoints) + 1
end

function ArenaManager.UnregisterPlayer(player)
    playerSpawnIdx[player] = nil
end

-- ── Spawn points ───────────────────────────────────────────────────────────

-- Returns the CFrame assigned to this player this round, or nil.
function ArenaManager.GetSpawnPoint(player)
    if #spawnPoints == 0 then return nil end
    local idx = playerSpawnIdx[player]
    if not idx then return nil end
    return spawnPoints[idx]
end

-- Rotate each player's spawn index for the next round.
function ArenaManager.RotateSpawns()
    if #spawnPoints == 0 then return end
    for player in pairs(playerSpawnIdx) do
        playerSpawnIdx[player] = (playerSpawnIdx[player] % #spawnPoints) + 1
    end
end

function ArenaManager.GetBlastZoneY()
    return BLAST_ZONE_Y
end

-- ── Blast-zone Heartbeat loop ──────────────────────────────────────────────

function ArenaManager.StartBlastZoneCheck()
    if blastConn then blastConn:Disconnect() end
    blastConn = RunService.Heartbeat:Connect(function()
        if not deathHandler then return end
        for _, player in ipairs(Players:GetPlayers()) do
            deathHandler.CheckBlastZone(player, BLAST_ZONE_Y)
        end
    end)
end

function ArenaManager.StopBlastZoneCheck()
    if blastConn then
        blastConn:Disconnect()
        blastConn = nil
    end
end

return ArenaManager
