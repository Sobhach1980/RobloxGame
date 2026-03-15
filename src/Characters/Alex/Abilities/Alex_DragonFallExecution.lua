--[[
    Alex_DragonFallExecution.lua
    Ultimate Ability 3 (R): Dragonfall Execution
    Character: Alex | Form: Dragon's Awakening

    Description:
      The cinematic ult finisher. Alex leaps high into the air, manifesting
      the dragon's silhouette around her, then crashes down on the targeted
      enemy in a dragon-shaped impact. On landing, a massive shockwave
      erupts, triggering ragdoll on all enemies in range. Causes heavy
      screen shake, FOV pulse, and a terrain scar.

    Values:
      Cooldown (within ult) : 18.0 s
      Ascend height         : 30 studs
      Target lock range     : 24 studs
      Slam delay            : 2.0 s (cinematic window)
      Primary target damage : 90  |  Launcher + ground bounce
      AoE damage (12 stud)  : 50  |  Heavy KB
      AoE damage (20 stud)  : 25  |  Medium KB
      Move lock             : 2.8 s
      Ragdoll               : all targets in 12 stud AoE
      VFX                   : dragon silhouette ascent, purple flame trail,
                              dragon-shape impact crater, shockwave ring
      Camera                : strong shake + orbit cut + FOV pulse
      Terrain               : dragon shockwave scar, cracked ground decal
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Alex_DragonFallExecution = {}

local COOLDOWN     = 18.0
local ASCEND_H     = 30
local TARGET_RANGE = 24
local SLAM_DELAY   = 2.0
local INNER_RADIUS = 12
local OUTER_RADIUS = 20
local MOVE_LOCK    = 2.8

function Alex_DragonFallExecution.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("DragonFallExecution") then return end
    if not cooldowns:Start("DragonFallExecution", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    movementSystem:LockMovement(MOVE_LOCK)

    -- Phase 1: Alex soars upward, dragon silhouette appears
    -- AnimHelper.Play(character, "rbxassetid://ALEX_DRAGONFALL_ASCEND")
    rootPart.AssemblyLinearVelocity = Vector3.new(0, ASCEND_H * 5, 0)

    -- VFX: dragon silhouette materialises around Alex
    -- VFXRemote:FireAllClients("AlexDragonFallAscend", rootPart.Position)

    -- Cinematic camera
    -- CinematicRemote:FireAllClients("AlexDragonFallCinematic", character)

    -- Phase 2: Crash down
    task.delay(SLAM_DELAY, function()
        if not rootPart.Parent then return end

        -- Target lock: snap toward nearest enemy in range
        local slamPos = rootPart.Position
        -- (Production: raycast downward, snap to targeted enemy position)

        -- Slam velocity downward
        rootPart.AssemblyLinearVelocity = Vector3.new(0, -150, 0)

        -- VFX: purple flame trail during descent
        -- VFXRemote:FireAllClients("AlexDragonFallDescent", slamPos)

        task.delay(0.20, function()
            if not rootPart.Parent then return end
            local landPos = rootPart.Position

            -- Camera: strong shake + FOV pulse
            -- CameraShakeRemote:FireAllClients("strong", landPos, 35)
            -- FOVPulseRemote:FireAllClients(88, 0.5)

            -- VFX: dragon-shape impact, shockwave ring, terrain scar
            -- VFXRemote:FireAllClients("AlexDragonFallImpact", landPos)
            -- DestructionRemote:FireServer("DragonFall", landPos, INNER_RADIUS)

            -- Inner AoE: primary damage + ragdoll
            HitboxSystem.SpawnAoE({
                Position = landPos,
                Radius   = INNER_RADIUS,
                Attacker = character,
                OnHit    = function(victim)
                    local vRoot    = victim:FindFirstChild("HumanoidRootPart")
                    local blastDir = vRoot and (vRoot.Position - landPos).Unit or Vector3.new(0,1,0)
                    HitStun.Apply(victim, {
                        Damage         = 90,
                        StunType       = "launcher",
                        KnockbackForce = 85,
                        KnockbackDir   = (blastDir + Vector3.new(0, 1, 0)).Unit,
                        IsGroundBounce = true,
                    })
                    -- RagdollRemote:FireServer(victim)
                end,
            })

            -- Outer splash AoE
            HitboxSystem.SpawnAoE({
                Position = landPos,
                Radius   = OUTER_RADIUS,
                Attacker = character,
                OnHit    = function(victim)
                    local vRoot    = victim:FindFirstChild("HumanoidRootPart")
                    local blastDir = vRoot and (vRoot.Position - landPos).Unit or Vector3.new(0,1,0)
                    HitStun.Apply(victim, {
                        Damage         = 25,
                        StunType       = "medium",
                        KnockbackForce = 50,
                        KnockbackDir   = blastDir,
                    })
                end,
            })
        end)
    end)
end

return Alex_DragonFallExecution
