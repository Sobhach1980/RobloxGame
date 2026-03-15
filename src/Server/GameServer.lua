--[[
    GameServer.lua  —  Server entry point
    Runs in ServerScriptService.

    Responsibilities:
      1. Create all RemoteEvents in ReplicatedStorage
      2. Initialise shared server-side systems (VFXSystem, HitStunKnockback, etc.)
      3. Spawn a character controller for each player on character load
      4. Wire player input RemoteEvents to the correct controller methods
      5. Route the damage pipeline through each character's controller
--]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ── Shared systems ─────────────────────────────────────────────────────────

local VFXSystem          = require(game.ReplicatedStorage.Shared.VFX.VFXSystem)
local HitStunKnockback   = require(game.ReplicatedStorage.Shared.CombatEngine.HitStunKnockback)
local RagdollEngine      = require(game.ReplicatedStorage.Shared.CombatEngine.RagdollEngine)
local RosterConfig       = require(game.ReplicatedStorage.RosterConfig)

-- ── Character controllers ──────────────────────────────────────────────────

local Controllers = {
    Steve    = require(game.ReplicatedStorage.Characters.Steve.SteveController),
    Alex     = require(game.ReplicatedStorage.Characters.Alex.AlexController),
    Zombie   = require(game.ReplicatedStorage.Characters.Zombie.ZombieController),
    Enderman = require(game.ReplicatedStorage.Characters.Enderman.EndermanController),
    Skeleton = require(game.ReplicatedStorage.Characters.Skeleton.SkeletonController),
}

-- ── RemoteEvent folder ─────────────────────────────────────────────────────

local remotesFolder = Instance.new("Folder")
remotesFolder.Name  = "GameRemotes"
remotesFolder.Parent = ReplicatedStorage

local function makeRemote(name)
    local re = Instance.new("RemoteEvent")
    re.Name   = name
    re.Parent = remotesFolder
    return re
end

local Remotes = {
    -- VFX
    VFXRemote          = makeRemote("VFXRemote"),
    -- Cinematics
    UltCinematic       = makeRemote("UltCinematic"),
    UltRevert          = makeRemote("UltRevert"),
    -- Camera shake / hit-stop / slow-mo
    CameraShake        = makeRemote("CameraShake"),
    HitStop            = makeRemote("HitStop"),
    SlowMo             = makeRemote("SlowMo"),
    -- Ragdoll
    RagdollRemote      = makeRemote("RagdollRemote"),
    -- HUD
    HUDRemote          = makeRemote("HUDRemote"),
    -- Input (client → server)
    InputRemote        = makeRemote("InputRemote"),
    -- Character selection (client → server)
    SelectCharacter    = makeRemote("SelectCharacter"),
}

-- ── Initialise server-side systems with the remotes they need ──────────────

VFXSystem.Init(Remotes.VFXRemote)

-- ── Active controller registry  player → controller instance ──────────────

local playerControllers = {}   -- [Player] = controllerInstance

-- ── Character creation helper ──────────────────────────────────────────────

local function createController(player, characterId, character)
    local CtrlClass = Controllers[characterId]
    if not CtrlClass then
        warn("GameServer: unknown character id:", characterId)
        return nil
    end

    -- Pass remotes and player reference so the controller can fire HUD/cinematic events
    local ctrl = CtrlClass.new(character, player, Remotes)
    playerControllers[player] = ctrl

    -- Tag the character model so other systems can identify it
    character:SetAttribute("CharacterId", characterId)
    character:SetAttribute("PlayerId", player.UserId)

    return ctrl
end

-- ── Input routing (client → server) ───────────────────────────────────────

--[[
    Clients fire InputRemote with (actionName, ...) where actionName is one of:
      "M1", "Dash", "BlockDown", "BlockUp", "Evasive", "Ability", "Ultimate"
    This is the authoritative server action handler.
]]
Remotes.InputRemote.OnServerEvent:Connect(function(player, actionName, ...)
    local ctrl = playerControllers[player]
    if not ctrl then return end

    if actionName == "M1" then
        ctrl:OnM1()
    elseif actionName == "Dash" then
        ctrl:OnDash(...)
    elseif actionName == "BlockDown" then
        ctrl:OnBlockDown()
    elseif actionName == "BlockUp" then
        ctrl:OnBlockUp()
    elseif actionName == "Evasive" then
        ctrl:OnEvasive(...)
    elseif actionName == "Ability" then
        ctrl:OnAbility(...)
    elseif actionName == "Ultimate" then
        ctrl:OnUltimate()
    end
end)

-- ── Character selection ────────────────────────────────────────────────────

Remotes.SelectCharacter.OnServerEvent:Connect(function(player, characterId)
    -- Validate the requested character exists in the roster
    if not RosterConfig.Get(characterId) then
        warn("GameServer: invalid character selection:", characterId, "from", player.Name)
        return
    end

    -- Clean up any existing controller for this player
    local existing = playerControllers[player]
    if existing and existing.Destroy then
        existing:Destroy()
    end

    -- Store selection; controller is created on next character load
    player:SetAttribute("SelectedCharacter", characterId)

    -- Respawn so the character model is fresh
    if player.Character then
        player.Character:BreakJoints()   -- triggers CharacterAdded
    end
end)

-- ── Player lifecycle ───────────────────────────────────────────────────────

local function onCharacterAdded(player, character)
    -- Wait for HumanoidRootPart to be present
    character:WaitForChild("HumanoidRootPart", 10)
    character:WaitForChild("Humanoid", 10)

    local characterId = player:GetAttribute("SelectedCharacter") or "Steve"

    -- Destroy old controller if one exists
    local old = playerControllers[player]
    if old and old.Destroy then old:Destroy() end

    local ctrl = createController(player, characterId, character)
    if not ctrl then return end

    -- Notify HUD of character + initial state
    Remotes.HUDRemote:FireClient(player, "CharacterSet", characterId)

    -- Cleanup when the character is removed
    character.AncestryChanged:Connect(function()
        if not character.Parent then
            local c = playerControllers[player]
            if c == ctrl then
                if c.Destroy then c:Destroy() end
                playerControllers[player] = nil
            end
        end
    end)
end

local function onPlayerAdded(player)
    -- Default character selection
    player:SetAttribute("SelectedCharacter", "Steve")

    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)

    -- Handle character that already exists (e.g. Studio Play mode)
    if player.Character then
        task.spawn(onCharacterAdded, player, player.Character)
    end
end

local function onPlayerRemoving(player)
    local ctrl = playerControllers[player]
    if ctrl and ctrl.Destroy then ctrl:Destroy() end
    playerControllers[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players who joined before this script ran
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end

-- ── Damage pipeline (called by HitboxSystem hit callbacks) ─────────────────

--[[
    ApplyDamage(victim, attacker, damage, config) -> actualDamage
    Central damage function used by all ability scripts.

    config may include:
      StunType       : string  (light/medium/heavy/launcher)
      KnockbackForce : number
      KnockbackDir   : Vector3
      IsProjectile   : boolean
      HitStop        : number  -- seconds
      SlowMo         : boolean
      Ragdoll        : boolean
      RagdollDur     : number
      GuardBreak     : boolean
--]]
local function ApplyDamage(victim, attacker, damage, config)
    config = config or {}

    local victimChar = victim
    if typeof(victim) == "Instance" and victim:IsA("Player") then
        victimChar = victim.Character
    end
    if not victimChar then return 0 end

    local humanoid = victimChar:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return 0 end

    -- Route through victim's controller for block/parry/iframes/ult reduction
    local attackerPlayer = attacker
    local attackerChar   = attacker
    if typeof(attacker) == "Instance" and attacker:IsA("Player") then
        attackerChar = attacker.Character
    end

    local victimPlayer = Players:GetPlayerFromCharacter(victimChar)
    local victimCtrl   = victimPlayer and playerControllers[victimPlayer]

    local finalDamage = damage
    if victimCtrl and victimCtrl.OnHitReceived then
        finalDamage = victimCtrl:OnHitReceived(attackerChar, damage, config)
    end

    if finalDamage <= 0 then return 0 end

    -- Apply health loss
    humanoid:TakeDamage(finalDamage)

    -- Update attacker gauge
    local attackerPlayerObj = Players:GetPlayerFromCharacter(attackerChar)
    local attackerCtrl = attackerPlayerObj and playerControllers[attackerPlayerObj]
    if attackerCtrl and attackerCtrl.OnDamageDealt then
        attackerCtrl:OnDamageDealt(finalDamage)
    end

    -- Hit-stop
    if config.HitStop and config.HitStop > 0 then
        Remotes.HitStop:FireAllClients(config.HitStop)
    end

    -- Slow-mo flash
    if config.SlowMo then
        Remotes.SlowMo:FireAllClients(config.SlowMoDuration or 0.08)
    end

    -- Stun + knockback
    if config.StunType then
        HitStunKnockback.Apply(victimChar, {
            StunType       = config.StunType,
            KnockbackForce = config.KnockbackForce or 0,
            KnockbackDir   = config.KnockbackDir,
            Launcher       = config.StunType == "launcher",
        })
    end

    -- Ragdoll
    if config.Ragdoll then
        local root = victimChar:FindFirstChild("HumanoidRootPart")
        RagdollEngine.Activate(victimChar, {
            Duration    = config.RagdollDur or 1.5,
            BlastOrigin = root and root.Position,
            BlastForce  = config.KnockbackForce,
        })
    end

    -- Camera shake for nearby players
    if config.CameraShake then
        local root = victimChar:FindFirstChild("HumanoidRootPart")
        if root then
            Remotes.CameraShake:FireAllClients(config.CameraShake, root.Position, config.ShakeRadius or 30)
        end
    end

    return finalDamage
end

-- Expose globally so ability scripts can require this module and call it
local GameServer = {}
GameServer.Remotes       = Remotes
GameServer.ApplyDamage   = ApplyDamage
GameServer.GetController = function(player) return playerControllers[player] end

-- Make accessible to server-side ability scripts via a BindableFunction or
-- simply by requiring this ModuleScript (server-only).
return GameServer
