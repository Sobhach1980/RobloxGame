--[[
    Enderman_StolenGround.lua
    Ultimate Ability 2 (E): Stolen Ground
    Character: Enderman | Form: Void Dominion

    Description:
      Enderman rips a section of the terrain from beneath enemies and
      hurls it at them. The terrain chunk deals damage and creates a
      hazard pit where it was torn from (enemies fall in for 10 damage).
      The flung chunk hits a large AoE on impact.

    Values:
      Cooldown (within ult) : 11.0 s
      Rip radius            : 10 studs (terrain chunk grabbed)
      Pit duration          : 6 s
      Pit damage on fall    : 10 (lingering zone below pit)
      Chunk projectile speed: 35
      Chunk range           : 30 studs
      Chunk AoE on impact   : 11 stud radius
      Chunk damage          : 55
      StunType              : heavy
      KnockbackForce        : 60 radial
      Hit-stop              : 0.18 s
      Move lock             : 0.80 s
      VFX                   : ground tears up, void energy lifts chunk,
                              hurled chunk flies, slam shockwave
      Camera                : medium-strong shake on terrain rip + on impact
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Enderman_StolenGround = {}

local COOLDOWN      = 11.0
local RIP_RADIUS    = 10
local PIT_DURATION  = 6.0
local PIT_DAMAGE    = 10
local PROJ_SPEED    = 35
local PROJ_RANGE    = 30
local IMPACT_RADIUS = 11
local IMPACT_DAMAGE = 55
local KB_FORCE      = 60
local HITSTOP_DUR   = 0.18
local MOVE_LOCK     = 0.80

function Enderman_StolenGround.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("StolenGround") then return end
    if not cooldowns:Start("StolenGround", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    movementSystem:LockMovement(MOVE_LOCK)

    -- AnimHelper.Play(character, "rbxassetid://ENDERMAN_STOLENGROUND_RIP")

    -- Camera: initial terrain rip shake
    -- CameraShakeRemote:FireAllClients("medium", rootPart.Position, 22)

    -- VFX: ground tears up at rip position
    local ripPos = rootPart.Position + rootPart.CFrame.LookVector * 8
    -- VFXRemote:FireAllClients("EndermanStolenGroundRip", ripPos, RIP_RADIUS)
    -- DestructionRemote:FireServer("StolenGroundRip", ripPos, RIP_RADIUS)

    -- Create pit hazard where chunk was removed
    HitboxSystem.SpawnLingeringZone({
        Position     = ripPos,
        Size         = Vector3.new(RIP_RADIUS * 2, 6, RIP_RADIUS * 2),
        Duration     = PIT_DURATION,
        TickInterval = 1.0,
        Attacker     = character,
        OnTick       = function(victim)
            HitStun.Apply(victim, { Damage=PIT_DAMAGE, StunType="light", KnockbackForce=0, KnockbackDir=Vector3.new(0,1,0) })
        end,
    })

    -- Fling chunk as projectile toward look direction
    task.delay(0.30, function()
        if not rootPart.Parent then return end

        local throwDir = rootPart.CFrame.LookVector
        local origin   = ripPos + Vector3.new(0, 4, 0)

        -- VFX: chunk flies through air
        -- ProjVisualRemote:FireAllClients("TerrainChunk", origin, throwDir, PROJ_SPEED, RIP_RADIUS, PROJ_RANGE)

        HitboxSystem.SpawnProjectile({
            Origin       = origin,
            Direction    = throwDir,
            Speed        = PROJ_SPEED,
            MaxRange     = PROJ_RANGE,
            HitboxRadius = 5,
            Attacker     = character,
            Gravity      = 15,
            OnHit        = function(victim, hitPos)
                Enderman_StolenGround._impact(character, hitPos or victim.HumanoidRootPart.Position)
            end,
            OnExpire = function()
                local finalPos = origin + throwDir * PROJ_RANGE
                Enderman_StolenGround._impact(character, finalPos)
            end,
        })
    end)
end

function Enderman_StolenGround._impact(character, pos)
    -- Camera: strong shake on impact
    -- CameraShakeRemote:FireAllClients("strong", pos, 30)
    -- VFXRemote:FireAllClients("EndermanStolenGroundImpact", pos, IMPACT_RADIUS)

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local ps = humanoid.WalkSpeed
        humanoid.WalkSpeed = 0
        task.delay(HITSTOP_DUR, function()
            if humanoid.Parent then humanoid.WalkSpeed = ps end
        end)
    end

    HitboxSystem.SpawnAoE({
        Position = pos,
        Radius   = IMPACT_RADIUS,
        Attacker = character,
        OnHit    = function(victim)
            local vRoot    = victim:FindFirstChild("HumanoidRootPart")
            local blastDir = vRoot and (vRoot.Position - pos).Unit or Vector3.new(0,1,0)
            HitStun.Apply(victim, {
                Damage         = IMPACT_DAMAGE,
                StunType       = "heavy",
                KnockbackForce = KB_FORCE,
                KnockbackDir   = blastDir,
            })
        end,
    })
end

return Enderman_StolenGround
