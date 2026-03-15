--[[
    Alex_QuarryStrike.lua
    Ability: Quarry Strike (Q)
    Character: Alex

    Description:
      Alex swings her pickaxe in a powerful overhead mining arc, dealing
      high single-target damage and briefly grounding the opponent (prevents
      jumping for 1.2 s). On hit against a wall-adjacent enemy, the wall
      takes structural damage (destructible props). Distinct from all of
      Steve's melee abilities in arc direction, tool type, and crowd control.

    Values:
      Cooldown        : 7.0 s
      Damage          : 32
      StunType        : heavy
      KnockbackForce  : 20 (downward spike, not horizontal)
      Ground lock     : 1.2 s (JumpPower = 0)
      Move lock       : 0.55 s
      Hitbox          : 7 x 5 x 6 (overhead arc, slightly above center)
      VFX             : pickaxe swing arc, mining spark burst, dust plume
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Alex_QuarryStrike = {}

local COOLDOWN     = 7.0
local DAMAGE       = 32
local KB_FORCE     = 20
local GROUND_LOCK  = 1.2
local MOVE_LOCK    = 0.55
local HITBOX_SIZE  = Vector3.new(7, 6, 6)

function Alex_QuarryStrike.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("QuarryStrike") then return end
    if not cooldowns:Start("QuarryStrike", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    movementSystem:LockMovement(MOVE_LOCK)

    -- Play overhead pickaxe swing
    -- AnimHelper.Play(character, "rbxassetid://ALEX_QUARRYSTRIKE_SWING")

    -- VFX: pickaxe arc, mining sparks
    -- VFXRemote:FireAllClients("AlexQuarryStrike", rootPart.Position, rootPart.CFrame.LookVector)

    task.delay(0.22, function()   -- wind-up delay
        if not rootPart.Parent then return end

        local hitboxPos = rootPart.CFrame:PointToWorldSpace(Vector3.new(0, 1, -3.5))
        local strikeDir = (rootPart.CFrame.LookVector + Vector3.new(0, -0.5, 0)).Unit

        HitboxSystem.SpawnMeleeHitbox({
            Position    = hitboxPos,
            Size        = HITBOX_SIZE,
            Duration    = 0.14,
            Attacker    = character,
            PierceCount = 1,
            OnHit       = function(victim)
                -- Ground lock: remove jump power temporarily
                local vHum = victim:FindFirstChildOfClass("Humanoid")
                if vHum then
                    local prevJump = vHum.JumpPower
                    vHum.JumpPower = 0
                    task.delay(GROUND_LOCK, function()
                        if vHum.Parent then vHum.JumpPower = prevJump end
                    end)
                end

                HitStun.Apply(victim, {
                    Damage         = DAMAGE,
                    StunType       = "heavy",
                    KnockbackForce = KB_FORCE,
                    KnockbackDir   = strikeDir,
                })

                -- Check for nearby destructibles
                -- DestructionRemote:FireServer("QuarryStrike", rootPart.Position, 5)

                -- VFX: impact dust + spark
                -- VFXRemote:FireAllClients("QuarryStrikeHit", victim.HumanoidRootPart.Position)
            end,
        })
    end)
end

return Alex_QuarryStrike
