--[[
    Enderman_EnderStrike.lua
    Ability: Ender Strike (E)
    Character: Enderman

    Description:
      Enderman blinks behind the targeted enemy and delivers a powerful
      void-charged backstab. The attack deals bonus damage if it connects
      to the target's back (dot product check). Should be parried to punish.

    Values:
      Cooldown        : 7.0 s
      Blink range     : 18 studs
      Base damage     : 30
      Backstab bonus  : +20 damage (total 50 if behind target)
      StunType        : heavy
      KnockbackForce  : 45 (forward from Enderman's new position)
      Move lock       : 0.40 s
      VFX             : void warp behind enemy, purple backstab burst,
                        void aura crackle on hit
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Enderman_EnderStrike = {}

local COOLDOWN       = 7.0
local BLINK_RANGE    = 18
local BASE_DAMAGE    = 30
local BACKSTAB_BONUS = 20
local KB_FORCE       = 45
local MOVE_LOCK      = 0.40

function Enderman_EnderStrike.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("EnderStrike") then return end
    if not cooldowns:Start("EnderStrike", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Find nearest enemy in range to blink behind
    local target, targetRoot = Enderman_EnderStrike._findTarget(character, rootPart, BLINK_RANGE)

    if not target or not targetRoot then
        -- No target: just do a forward void strike
        movementSystem:LockMovement(MOVE_LOCK)
        local hitboxPos = rootPart.CFrame:PointToWorldSpace(Vector3.new(0, 0, -4))
        -- VFXRemote:FireAllClients("EndermanEnderStrikeMiss", hitboxPos)
        HitboxSystem.SpawnMeleeHitbox({
            Position = hitboxPos, Size = Vector3.new(6,5,6), Duration = 0.14,
            Attacker = character,
            OnHit = function(victim)
                HitStun.Apply(victim, { Damage=BASE_DAMAGE, StunType="heavy", KnockbackForce=KB_FORCE, KnockbackDir=rootPart.CFrame.LookVector })
            end,
        })
        return
    end

    movementSystem:LockMovement(MOVE_LOCK)

    -- Blink behind target
    local behindPos = targetRoot.Position + targetRoot.CFrame.LookVector * 3
    local cf = rootPart.CFrame
    rootPart.CFrame = CFrame.new(behindPos) * (cf - cf.Position)

    -- VFX: void warp to behind position
    -- VFXRemote:FireAllClients("EndermanEnderStrikeBlink", behindPos)

    -- Backstab check: is Enderman now behind the target?
    local attackDir  = (targetRoot.Position - rootPart.Position).Unit
    local targetFwd  = targetRoot.CFrame.LookVector
    local dotProduct = attackDir:Dot(targetFwd)   -- positive = behind target
    local isBackstab = dotProduct > 0.5

    local totalDamage = isBackstab and (BASE_DAMAGE + BACKSTAB_BONUS) or BASE_DAMAGE

    -- AnimHelper.Play(character, "rbxassetid://ENDERMAN_ENDERSTRIKE_STAB")

    task.delay(0.05, function()
        if not rootPart.Parent or not targetRoot.Parent then return end
        local strikeDir = (targetRoot.Position - rootPart.Position).Unit

        HitboxSystem.SpawnMeleeHitbox({
            Position    = targetRoot.Position,
            Size        = Vector3.new(5, 5, 5),
            Duration    = 0.12,
            Attacker    = character,
            PierceCount = 1,
            OnHit       = function(victim)
                HitStun.Apply(victim, {
                    Damage         = totalDamage,
                    StunType       = "heavy",
                    KnockbackForce = KB_FORCE,
                    KnockbackDir   = strikeDir,
                })
                -- VFXRemote:FireAllClients("EndermanEnderStrikeHit", targetRoot.Position, isBackstab)
            end,
        })
    end)
end

function Enderman_EnderStrike._findTarget(character, rootPart, range)
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

return Enderman_EnderStrike
