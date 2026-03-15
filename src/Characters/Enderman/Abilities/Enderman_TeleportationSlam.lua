--[[
    Enderman_TeleportationSlam.lua
    Ability: Teleportation Slam (F)
    Character: Enderman

    Description:
      Enderman teleports high above the targeted enemy then slams down
      in a void-powered dive, creating a landing AoE that lifts all
      nearby enemies and deals heavy damage. The slam disrupts terrain
      into floating fragments. Hit-stop on landing.

    Values:
      Cooldown        : 12.0 s
      Ascend height   : 20 studs
      Slam delay      : 1.0 s
      AoE radius      : 9 studs
      Damage          : 45
      StunType        : launcher
      KnockbackForce  : 65
      Hit-stop        : 0.20 s
      Terrain disruption: void fragment lift effect in radius
      Move lock       : 1.4 s
      VFX             : void teleport above, slam trail, landing impact ring,
                        floating terrain fragments
      Camera          : medium shake + FOV pulse on landing
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Enderman_TeleportationSlam = {}

local COOLDOWN    = 12.0
local ASCEND_H    = 20
local SLAM_DELAY  = 1.0
local AOE_RADIUS  = 9
local DAMAGE      = 45
local KB_FORCE    = 65
local HITSTOP_DUR = 0.20
local MOVE_LOCK   = 1.4

function Enderman_TeleportationSlam.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("TeleportationSlam") then return end
    if not cooldowns:Start("TeleportationSlam", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    movementSystem:LockMovement(MOVE_LOCK)

    -- Find nearest target or use look direction
    local target, targetRoot = Enderman_TeleportationSlam._findTarget(character, rootPart, 20)
    local slamTarget = targetRoot and targetRoot.Position or (rootPart.Position + rootPart.CFrame.LookVector * 12)

    -- Teleport above target
    local abovePos = slamTarget + Vector3.new(0, ASCEND_H, 0)
    local cf = rootPart.CFrame
    rootPart.CFrame = CFrame.new(abovePos) * (cf - cf.Position)

    -- AnimHelper.Play(character, "rbxassetid://ENDERMAN_TELEPORTSLAM_ASCEND")
    -- VFXRemote:FireAllClients("EndermanTeleportSlamAbove", abovePos)

    -- Slam down after delay
    task.delay(SLAM_DELAY, function()
        if not rootPart.Parent then return end

        -- AnimHelper.Play(character, "rbxassetid://ENDERMAN_TELEPORTSLAM_DIVE")
        rootPart.AssemblyLinearVelocity = Vector3.new(0, -120, 0)

        -- VFX: void dive trail
        -- VFXRemote:FireAllClients("EndermanTeleportSlamDive", rootPart.Position)

        task.delay(0.20, function()
            if not rootPart.Parent then return end

            local landPos = rootPart.Position

            -- Camera: shake + FOV pulse
            -- CameraShakeRemote:FireAllClients("medium", landPos, 22)
            -- FOVPulseRemote:FireAllClients(86, 0.3)

            -- VFX: landing impact ring, terrain fragments
            -- VFXRemote:FireAllClients("EndermanTeleportSlamLand", landPos)
            -- DestructionRemote:FireServer("TeleportSlam", landPos, AOE_RADIUS)

            -- Hit-stop: attacker
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local ps = humanoid.WalkSpeed
                humanoid.WalkSpeed = 0
                task.delay(HITSTOP_DUR, function()
                    if humanoid.Parent then humanoid.WalkSpeed = ps end
                end)
            end

            HitboxSystem.SpawnAoE({
                Position = landPos,
                Radius   = AOE_RADIUS,
                Attacker = character,
                OnHit    = function(victim)
                    local vRoot    = victim:FindFirstChild("HumanoidRootPart")
                    local blastDir = vRoot and (vRoot.Position - landPos).Unit or Vector3.new(0,1,0)

                    -- Hit-stop on victim
                    local vHum = victim:FindFirstChildOfClass("Humanoid")
                    if vHum then
                        local vs = vHum.WalkSpeed
                        vHum.WalkSpeed = 0
                        task.delay(HITSTOP_DUR, function()
                            if vHum.Parent then vHum.WalkSpeed = vs end
                        end)
                    end

                    HitStun.Apply(victim, {
                        Damage         = DAMAGE,
                        StunType       = "launcher",
                        KnockbackForce = KB_FORCE,
                        KnockbackDir   = (blastDir + Vector3.new(0, 0.8, 0)).Unit,
                    })
                end,
            })
        end)
    end)
end

function Enderman_TeleportationSlam._findTarget(character, rootPart, range)
    local best, bestRoot, bestDist = nil, nil, range + 1
    for _, model in ipairs(workspace:GetChildren()) do
        if model ~= character and model:IsA("Model") then
            local hum  = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                local d = (root.Position - rootPart.Position).Magnitude
                if d < bestDist then bestDist = d; best = model; bestRoot = root end
            end
        end
    end
    return best, bestRoot
end

return Enderman_TeleportationSlam
