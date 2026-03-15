--[[
    Steve_LastBlockStanding.lua
    Ultimate Ability 3 (R): Last Block Standing
    Character: Steve | Form: Undying Resurgence

    Description:
      The cinematic finale move. Steve leaps into the air and calls down
      a massive descending block of bedrock that crashes into the arena.
      On impact it creates a giant AoE shockwave, deals massive damage,
      triggers a full arena-collapse cinematic, and launches all enemies
      caught in the blast into the sky before slamming them down for a
      ground-bounce ragdoll. This is the definitive match-ending move.

    Values:
      Cooldown (within ult) : 20.0 s  (single use encouraged by high CD)
      Ascend height         : 25 studs
      Slam delay            : 1.8 s after ascent
      AoE radius            : 16 studs
      Damage                : 80
      StunType              : launcher + ground bounce
      KnockbackForce        : 90
      Move lock             : 2.5 s total sequence
      Ragdoll               : triggered on all victims
      VFX                   : ascent glow, bedrock block descends, arena shake,
                              collapse particles, flying debris, finisher burst
      Camera                : cinematic heavy shake + orbit cut + FOV pulse
      Audio                 : signature "Last Block Standing" SFX + arena rumble
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Steve_LastBlockStanding = {}

local COOLDOWN    = 20.0
local ASCEND_H    = 25
local SLAM_DELAY  = 1.8
local AOE_RADIUS  = 16
local DAMAGE      = 80
local KB_FORCE    = 90
local MOVE_LOCK   = 2.5

function Steve_LastBlockStanding.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("LastBlockStanding") then return end
    if not cooldowns:Start("LastBlockStanding", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    movementSystem:LockMovement(MOVE_LOCK)

    -- Phase 1: Steve ascends into the air
    -- AnimHelper.Play(character, "rbxassetid://STEVE_LASTBLOCK_ASCEND")
    rootPart.AssemblyLinearVelocity = Vector3.new(0, ASCEND_H * 5, 0)

    -- VFX: ascent glow begins, bedrock block appears above arena
    -- VFXRemote:FireAllClients("SteveLastBlockAscend", rootPart.Position)

    -- Camera: orbit cut / cinematic sequence begins
    -- CinematicRemote:FireAllClients("SteveLastBlockCinematic", character)

    -- Phase 2: slam down after delay
    task.delay(SLAM_DELAY, function()
        if not rootPart.Parent then return end

        local slamPos = rootPart.Position

        -- Slam velocity downward
        rootPart.AssemblyLinearVelocity = Vector3.new(0, -120, 0)

        -- VFX: bedrock block crashes down, shockwave ring expands
        -- VFXRemote:FireAllClients("SteveLastBlockSlam", slamPos)

        -- Camera: heavy shake + FOV pulse
        -- CameraShakeRemote:FireAllClients("cinematic", slamPos, 40)
        -- FOVPulseRemote:FireAllClients(90, 0.6)

        -- SFX: arena rumble + signature Last Block Standing sound
        -- SFXRemote:FireAllClients("LastBlockStanding", slamPos)

        -- Arena collapse environmental VFX
        -- EnvironmentRemote:FireAllClients("ArenaCollapse", slamPos, AOE_RADIUS)

        task.delay(0.25, function()   -- slight delay for landing impact
            if not rootPart.Parent then return end

            local finalPos = rootPart.Position

            HitboxSystem.SpawnAoE({
                Position   = finalPos,
                Radius     = AOE_RADIUS,
                Attacker   = character,
                OnHit      = function(victim)
                    local vRoot   = victim:FindFirstChild("HumanoidRootPart")
                    local blastDir = vRoot and (vRoot.Position - finalPos).Unit
                        or Vector3.new(0, 1, 0)

                    HitStun.Apply(victim, {
                        Damage         = DAMAGE,
                        StunType       = "launcher",
                        KnockbackForce = KB_FORCE,
                        KnockbackDir   = (blastDir + Vector3.new(0, 1.2, 0)).Unit,
                        IsGroundBounce = true,
                    })

                    -- VFX: individual victim launch burst
                    -- VFXRemote:FireAllClients("LastBlockVictimLaunch", vRoot and vRoot.Position)
                end,
            })

            -- Terrain destruction
            -- DestructionRemote:FireServer("LastBlockStanding", finalPos, AOE_RADIUS)
        end)
    end)
end

return Steve_LastBlockStanding
