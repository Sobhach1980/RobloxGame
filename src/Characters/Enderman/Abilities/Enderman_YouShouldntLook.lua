--[[
    Enderman_YouShouldntLook.lua
    Ultimate Ability 3 (R): You Shouldn't Look
    Character: Enderman | Form: Void Dominion

    Description:
      The cinematic finisher. Enderman traps an enemy in a void-space
      pocket dimension for 2 s (enemy is frozen and cannot be hit by
      others). Inside the void Enderman appears from every direction in
      a rapid series of phantom strikes. The sequence ends with a teleport
      pull into a final devastating strike that sends the victim flying.

    Values:
      Cooldown (within ult) : 20.0 s
      Target lock range     : 22 studs
      Void pocket duration  : 2.0 s (cinematic phase)
      Phantom strikes       : 5 rapid hits inside void
      Per-phantom damage    : 12
      Final strike damage   : 65  |  launcher  |  KB: 95
      Bypass block          : true (teleport pull, cannot be blocked)
      Move lock             : 2.5 s
      VFX                   : target encased in void sphere, Enderman flickers
                              from all angles, void fragments spiral,
                              final void shatter burst
      Camera                : orbit cut for victim + finale screen shake
      Ragdoll               : triggered on final hit
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Enderman_YouShouldntLook = {}

local COOLDOWN      = 20.0
local LOCK_RANGE    = 22
local VOID_DUR      = 2.0
local PHANTOM_COUNT = 5
local PHANTOM_DMG   = 12
local FINAL_DMG     = 65
local FINAL_KB      = 95
local MOVE_LOCK     = 2.5

function Enderman_YouShouldntLook.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("YouShouldntLook") then return end
    if not cooldowns:Start("YouShouldntLook", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Find target
    local target, targetRoot = Enderman_YouShouldntLook._findTarget(character, rootPart, LOCK_RANGE)
    if not target or not targetRoot then return end

    movementSystem:LockMovement(MOVE_LOCK)

    -- AnimHelper.Play(character, "rbxassetid://ENDERMAN_YOUSHOULDNTLOOK_INIT")

    -- Teleport pull: snap target to in front of Enderman
    local pullPos = rootPart.Position + rootPart.CFrame.LookVector * 4
    targetRoot.CFrame = CFrame.new(pullPos)

    -- Freeze target in void pocket
    local targetHum = target:FindFirstChildOfClass("Humanoid")
    local prevSpeed = targetHum and targetHum.WalkSpeed or 16
    if targetHum then targetHum.WalkSpeed = 0 end

    -- VFX: void sphere encloses target, arena dims
    -- VFXRemote:FireAllClients("EndermanYouShouldntLookCage", targetRoot.Position)
    -- CinematicRemote:FireAllClients("EndermanVoidPocket", character, target)

    -- Phantom strike sequence inside void
    local phantomInterval = VOID_DUR / (PHANTOM_COUNT + 1)

    for i = 1, PHANTOM_COUNT do
        task.delay(i * phantomInterval, function()
            if not targetRoot.Parent then return end

            -- VFX: Enderman flickers from a different angle each time
            -- VFXRemote:FireAllClients("EndermanPhantomStrike", targetRoot.Position, i)

            local tHum = target:FindFirstChildOfClass("Humanoid")
            if tHum then tHum:TakeDamage(PHANTOM_DMG) end
        end)
    end

    -- Final strike after void duration
    task.delay(VOID_DUR, function()
        if targetHum and targetHum.Parent then
            targetHum.WalkSpeed = prevSpeed
        end

        if not rootPart.Parent or not targetRoot.Parent then return end

        -- Camera: finale shake + orbit cut
        -- CameraShakeRemote:FireAllClients("cinematic", targetRoot.Position, 40)
        -- CinematicRemote:FireAllClients("EndermanVoidPocketEnd", character, target)

        -- VFX: void shatters, Enderman drives through target
        -- VFXRemote:FireAllClients("EndermanYouShouldntLookFinale", targetRoot.Position)

        local finalDir = rootPart.CFrame.LookVector

        HitboxSystem.SpawnMeleeHitbox({
            Position    = targetRoot.Position,
            Size        = Vector3.new(5, 5, 5),
            Duration    = 0.12,
            Attacker    = character,
            PierceCount = 1,
            OnHit       = function(victim)
                HitStun.Apply(victim, {
                    Damage         = FINAL_DMG,
                    StunType       = "launcher",
                    KnockbackForce = FINAL_KB,
                    KnockbackDir   = (finalDir + Vector3.new(0, 0.5, 0)).Unit,
                    IsGroundBounce = true,
                })
                -- RagdollRemote:FireServer(victim)
            end,
        })
    end)
end

function Enderman_YouShouldntLook._findTarget(character, rootPart, range)
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

return Enderman_YouShouldntLook
