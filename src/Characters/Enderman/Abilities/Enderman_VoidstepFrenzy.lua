--[[
    Enderman_VoidstepFrenzy.lua
    Ultimate Ability 1 (Q): Voidstep Frenzy
    Character: Enderman | Form: Void Dominion

    Description:
      Enderman enters a frenzied blink state, performing 6 rapid teleport
      strikes in quick succession, each leaving an afterimage. Each strike
      deals damage and the afterimages persist as decoys that confuse enemy
      targeting. The final strike deals massively increased damage.

    Values:
      Cooldown (within ult) : 9.0 s
      Strikes               : 6
      Strike interval       : 0.18 s
      Per-strike damage     : 16 (strike 6: 40)
      Teleport range/strike : 8 studs
      Afterimage count      : 1 per strike (6 total, 3 s duration each)
      Final hit StunType    : launcher  |  KB: 72
      Move lock             : 6 * 0.18 + 0.3 = 1.38 s
      VFX                   : purple void blinks, glowing afterimage decoys,
                              frenzy speed lines, final void burst
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Enderman_VoidstepFrenzy = {}

local COOLDOWN      = 9.0
local NUM_STRIKES   = 6
local STRIKE_INT    = 0.18
local STRIKE_DMG    = 16
local FINAL_DMG     = 40
local FINAL_KB      = 72
local BLINK_RANGE   = 8
local AFTERIMG_DUR  = 3.0

function Enderman_VoidstepFrenzy.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("VoidstepFrenzy") then return end
    if not cooldowns:Start("VoidstepFrenzy", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    movementSystem:LockMovement(NUM_STRIKES * STRIKE_INT + 0.3)

    -- VFXRemote:FireAllClients("EndermanVoidstepFrenzyStart", character)

    for i = 1, NUM_STRIKES do
        task.delay((i - 1) * STRIKE_INT, function()
            if not rootPart.Parent then return end

            local isFinal  = (i == NUM_STRIKES)
            local damage   = isFinal and FINAL_DMG or STRIKE_DMG
            local prevPos  = rootPart.Position

            -- Blink in random arc around a forward cone
            local angle    = math.rad(math.random(-30, 30))
            local blinkDir = CFrame.Angles(0, angle, 0) * rootPart.CFrame.LookVector
            blinkDir       = Vector3.new(blinkDir.X, 0, blinkDir.Z).Unit
            local dest     = rootPart.Position + blinkDir * BLINK_RANGE
            local cf       = rootPart.CFrame
            rootPart.CFrame = CFrame.new(dest) * (cf - cf.Position)

            -- Spawn afterimage decoy at previous position
            Enderman_VoidstepFrenzy._spawnAfterimage(prevPos, AFTERIMG_DUR)

            -- VFXRemote:FireAllClients("EndermanVoidstepBlink", dest, i, isFinal)

            -- Strike hitbox
            HitboxSystem.SpawnMeleeHitbox({
                Position    = dest,
                Size        = Vector3.new(6, 5, 6),
                Duration    = 0.10,
                Attacker    = character,
                PierceCount = 1,
                OnHit       = function(victim)
                    HitStun.Apply(victim, {
                        Damage         = damage,
                        StunType       = isFinal and "launcher" or "light",
                        KnockbackForce = isFinal and FINAL_KB or 12,
                        KnockbackDir   = blinkDir,
                    })
                end,
            })
        end)
    end
end

function Enderman_VoidstepFrenzy._spawnAfterimage(position, duration)
    -- In production: spawn a faded copy of Enderman model at position
    -- that fades out over the duration.
    -- AfterimageRemote:FireAllClients("EndermanAfterimage", position, duration)
end

return Enderman_VoidstepFrenzy
