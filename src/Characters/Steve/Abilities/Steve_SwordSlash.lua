--[[
    Steve_SwordSlash.lua
    Ability: Sword Slash (R)
    Character: Steve

    Description:
      A powerful two-hit horizontal sword arc. The first hit deals moderate
      damage and a small combo-extender stun. The second hit (auto-follows
      0.2 s later) deals heavier damage with knockback. Excellent for ending
      M1 combos or opening gaps with the second hit.

    Values:
      Cooldown        : 5.0 s
      Hit 1 Damage    : 18  |  StunType: medium
      Hit 2 Damage    : 26  |  StunType: heavy  |  KB: 45
      Hitbox Size     : 8 x 5 x 6 (wide frontal arc)
      Move lock       : 0.55 s total
      VFX             : horizontal sword arc swipe x2, spark clash
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Steve_SwordSlash = {}

local COOLDOWN    = 5.0
local HITBOX_SIZE = Vector3.new(8, 5, 6)

local HITS = {
    { delay=0.0,  damage=18, stunType="medium", kbForce=0,  animId="rbxassetid://STEVE_SLASH_1" },
    { delay=0.22, damage=26, stunType="heavy",  kbForce=45, animId="rbxassetid://STEVE_SLASH_2" },
}

function Steve_SwordSlash.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("SwordSlash") then return end
    if not cooldowns:Start("SwordSlash", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    movementSystem:LockMovement(0.55)

    for _, hit in ipairs(HITS) do
        task.delay(hit.delay, function()
            if not rootPart.Parent then return end

            -- Play per-hit animation
            -- AnimHelper.Play(character, hit.animId)

            local hitboxPos = rootPart.CFrame:PointToWorldSpace(Vector3.new(0, 0, -3.5))
            local slashDir  = rootPart.CFrame.LookVector

            -- VFX: arc slash
            -- VFXRemote:FireAllClients("SteveSwordSlash", hitboxPos, hit.delay == 0)

            HitboxSystem.SpawnMeleeHitbox({
                Position    = hitboxPos,
                Size        = HITBOX_SIZE,
                Duration    = 0.14,
                Attacker    = character,
                OnHit       = function(victim)
                    HitStun.Apply(victim, {
                        Damage         = hit.damage,
                        StunType       = hit.stunType,
                        KnockbackForce = hit.kbForce,
                        KnockbackDir   = slashDir,
                    })
                end,
            })
        end)
    end
end

return Steve_SwordSlash
