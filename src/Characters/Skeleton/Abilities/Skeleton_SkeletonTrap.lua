--[[
    Skeleton_SkeletonTrap.lua
    Ability: Skeleton Trap (R)
    Character: Skeleton

    Description:
      Skeleton places an invisible bone trap at a target location. When an
      enemy steps on it, the trap snaps shut, rooting them for 1.5 s and
      dealing 20 damage. During the root the Skeleton gains an "Open Shot"
      buff that increases next projectile damage by 40% for 3 seconds.
      Max 2 traps active at once.

    Values:
      Cooldown        : 9.0 s
      Trap range      : 25 studs (throw)
      Trap radius     : 3.5 studs (trigger zone)
      Root duration   : 1.5 s
      Root damage     : 20
      Open Shot buff  : +40% next projectile damage, 3 s window
      Max active traps: 2
      Trap lifetime   : 20 s (then expires)
      VFX             : bone trap flies, embeds in ground, invisible but
                        subtle glint, snap animation + icy crack on trigger
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Skeleton_SkeletonTrap = {}

local COOLDOWN       = 9.0
local TRAP_RANGE     = 25
local TRAP_RADIUS    = 3.5
local ROOT_DUR       = 1.5
local ROOT_DAMAGE    = 20
local BUFF_MULT      = 1.40
local BUFF_DUR       = 3.0
local MAX_TRAPS      = 2
local TRAP_LIFE      = 20.0

local activeTrapCounts = {}

function Skeleton_SkeletonTrap.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("SkeletonTrap") then return end

    local charId = tostring(character)
    activeTrapCounts[charId] = activeTrapCounts[charId] or 0
    if activeTrapCounts[charId] >= MAX_TRAPS then return end

    if not cooldowns:Start("SkeletonTrap", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Throw trap toward look direction
    local throwDir = rootPart.CFrame.LookVector
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {character}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local result  = workspace:Raycast(rootPart.Position, throwDir * TRAP_RANGE, rp)
    local trapPos = result and result.Position or (rootPart.Position + throwDir * TRAP_RANGE)

    activeTrapCounts[charId] = activeTrapCounts[charId] + 1

    -- AnimHelper.Play(character, "rbxassetid://SKELETON_SKELETONTRAP_THROW")
    -- VFXRemote:FireAllClients("SkeletonTrapPlaced", trapPos)

    local triggered = false
    local elapsed   = 0

    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if triggered then conn:Disconnect() return end
        elapsed = elapsed + dt
        if elapsed >= TRAP_LIFE then
            triggered = true
            conn:Disconnect()
            activeTrapCounts[charId] = math.max(0, activeTrapCounts[charId] - 1)
            -- VFXRemote:FireAllClients("SkeletonTrapExpire", trapPos)
            return
        end

        -- Check for enemy in trigger radius
        local overlapParams = OverlapParams.new()
        overlapParams.FilterDescendantsInstances = {character}
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude

        local parts = workspace:GetPartBoundsInRadius(trapPos, TRAP_RADIUS, overlapParams)
        for _, part in ipairs(parts) do
            local model = part:FindFirstAncestorOfClass("Model")
            if model and model ~= character then
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local tag = model:GetAttribute("HittableTag")
                    if tag then
                        triggered = true
                        conn:Disconnect()
                        activeTrapCounts[charId] = math.max(0, activeTrapCounts[charId] - 1)
                        Skeleton_SkeletonTrap._trigger(character, model, trapPos)
                        return
                    end
                end
            end
        end
    end)
end

function Skeleton_SkeletonTrap._trigger(character, victim, trapPos)
    -- VFX: trap snaps shut, icy crack
    -- VFXRemote:FireAllClients("SkeletonTrapTriggered", trapPos)

    local vHum = victim:FindFirstChildOfClass("Humanoid")
    if vHum then
        vHum:TakeDamage(ROOT_DAMAGE)

        -- Root: zero walk speed + jump for duration
        local prevSpeed = vHum.WalkSpeed
        local prevJump  = vHum.JumpPower
        vHum.WalkSpeed  = 0
        vHum.JumpPower  = 0
        task.delay(ROOT_DUR, function()
            if vHum.Parent then
                vHum.WalkSpeed = prevSpeed
                vHum.JumpPower = prevJump
            end
        end)
    end

    -- Apply Open Shot buff to Skeleton
    character:SetAttribute("SkeletonOpenShotReady", true)
    character:SetAttribute("SkeletonOpenShotMult", BUFF_MULT)
    task.delay(BUFF_DUR, function()
        if not character:GetAttribute("SkeletonOpenShotReady") then return end
        character:SetAttribute("SkeletonOpenShotReady", false)
        character:SetAttribute("SkeletonOpenShotMult", 1.0)
    end)

    -- VFX: Open Shot indicator on Skeleton HUD / body
    -- VFXRemote:FireAllClients("SkeletonOpenShotBuff", character)
end

-- Called by projectile abilities to consume the buff
function Skeleton_SkeletonTrap.ConsumeOpenShot(character)
    if not character:GetAttribute("SkeletonOpenShotReady") then return 1.0 end
    local mult = character:GetAttribute("SkeletonOpenShotMult") or 1.0
    character:SetAttribute("SkeletonOpenShotReady", false)
    character:SetAttribute("SkeletonOpenShotMult", 1.0)
    return mult
end

return Skeleton_SkeletonTrap
