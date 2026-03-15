--[[
    Steve_WorldEditCleave.lua
    Ultimate Ability 2 (E): World Edit Cleave
    Character: Steve | Form: Undying Resurgence

    Description:
      Steve slams his sword into the ground, sending a massive shockwave
      in front of him that tears the terrain and launches all enemies in
      a wide frontal cone into the air. Terrain destructibles in the path
      are destroyed. Causes hit-stop on contact.

    Values:
      Cooldown (within ult) : 10.0 s
      Shockwave range       : 18 studs forward, 10 wide
      Damage                : 45
      StunType              : launcher
      KnockbackForce        : 70 (upward + forward)
      Hit-stop              : 0.15 s (attacker and victim)
      Move lock             : 0.70 s
      VFX                   : sword slam, earth crack line, flying debris, dust column
      Camera                : strong screen shake + FOV pulse on activation
      Ragdoll               : triggered on victims
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Steve_WorldEditCleave = {}

local COOLDOWN     = 10.0
local DAMAGE       = 45
local KB_FORCE     = 70
local MOVE_LOCK    = 0.70
local HITBOX_SIZE  = Vector3.new(10, 6, 18)   -- wide frontal cone approximated as box
local HITSTOP_DUR  = 0.15

function Steve_WorldEditCleave.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("WorldEditCleave") then return end
    if not cooldowns:Start("WorldEditCleave", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    movementSystem:LockMovement(MOVE_LOCK)

    -- Play slam animation
    -- AnimHelper.Play(character, "rbxassetid://STEVE_WORLDEDITCLEAVE")

    -- Camera: strong screen shake + FOV pulse
    -- CameraShakeRemote:FireAllClients("strong", rootPart.Position, 25)
    -- FOVPulseRemote:FireAllClients(85, 0.3)

    -- VFX: sword raised then slams, earth crack propagates
    -- VFXRemote:FireAllClients("SteveWorldEditCleave", rootPart.Position, rootPart.CFrame.LookVector)

    -- Terrain destruction along the path
    -- DestructionRemote:FireServer("WorldEditCleave", rootPart.Position, rootPart.CFrame.LookVector, 18)

    task.delay(0.30, function()   -- slight delay for animation wind-up
        if not rootPart.Parent then return end

        local hitboxPos = rootPart.CFrame:PointToWorldSpace(Vector3.new(0, 0, -9))
        local slamDir   = rootPart.CFrame.LookVector

        -- Hit-stop: freeze attacker briefly
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local prevSpeed = humanoid and humanoid.WalkSpeed or 16
        if humanoid then humanoid.WalkSpeed = 0 end
        task.delay(HITSTOP_DUR, function()
            if humanoid and humanoid.Parent then humanoid.WalkSpeed = prevSpeed end
        end)

        HitboxSystem.SpawnMeleeHitbox({
            Position = hitboxPos,
            Size     = HITBOX_SIZE,
            Duration = 0.18,
            Attacker = character,
            OnHit    = function(victim)
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
                    KnockbackDir   = (slamDir + Vector3.new(0, 0.5, 0)).Unit,
                    IsGroundBounce = true,
                })

                -- VFX: impact burst on victim
                -- VFXRemote:FireAllClients("WorldEditCleaveHit", victim.HumanoidRootPart.Position)
            end,
        })
    end)
end

return Steve_WorldEditCleave
