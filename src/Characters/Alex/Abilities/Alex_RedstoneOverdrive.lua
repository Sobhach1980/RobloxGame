--[[
    Alex_RedstoneOverdrive.lua
    Ultimate Ability 2 (E): Redstone Overdrive
    Character: Alex | Form: Dragon's Awakening

    Description:
      Alex overloads her redstone network, firing a rapid volley of
      5 redstone bolts in a spread pattern. Each bolt applies the Shocked
      debuff. Enemies hit by 3 or more bolts are also stunned briefly.
      Leaves crackling redstone nodes on the ground for 3 s that zap
      enemies who walk over them.

    Values:
      Cooldown (within ult) : 8.0 s
      Volley count          : 5 bolts
      Fire interval         : 0.08 s (rapid-fire)
      Per-bolt damage       : 20
      Spread angle          : 25 degrees total (5 bolts evenly spread)
      Bolt speed            : 60
      Bolt range            : 28
      Shocked debuff        : 1.5 s per bolt (stacks refresh)
      3-hit stun            : 0.5 s extra stun on victim
      Ground node           : 4 stud radius, 3 s, 8 dmg on entry
      VFX                   : mechanical hum surge, 5 red bolts in spread,
                              ground node crackle
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Alex_RedstoneOverdrive = {}

local COOLDOWN      = 8.0
local NUM_BOLTS     = 5
local FIRE_INTERVAL = 0.08
local BOLT_DAMAGE   = 20
local BOLT_SPEED    = 60
local BOLT_RANGE    = 28
local SPREAD_DEG    = 25
local SHOCK_DUR     = 1.5
local TRIPLE_STUN   = 0.5
local NODE_RADIUS   = 4
local NODE_DURATION = 3.0
local NODE_DMG      = 8

function Alex_RedstoneOverdrive.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("RedstoneOverdrive") then return end
    if not cooldowns:Start("RedstoneOverdrive", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- AnimHelper.Play(character, "rbxassetid://ALEX_REDSTONEOVERDRIVE_FIRE")
    -- VFXRemote:FireAllClients("AlexRedstoneOverdriveStart", rootPart.Position)

    -- Track hit counts per victim for triple-hit stun
    local hitCounts = {}

    local halfSpread = SPREAD_DEG / 2
    local spreadStep = (NUM_BOLTS > 1) and (SPREAD_DEG / (NUM_BOLTS - 1)) or 0

    for i = 1, NUM_BOLTS do
        task.delay((i - 1) * FIRE_INTERVAL, function()
            if not rootPart.Parent then return end

            local angleOffset = -halfSpread + (i - 1) * spreadStep
            local baseDir     = rootPart.CFrame.LookVector
            local rotated     = CFrame.Angles(0, math.rad(angleOffset), 0) * baseDir
            local boltDir     = Vector3.new(rotated.X, baseDir.Y, rotated.Z).Unit
            local origin      = rootPart.Position + Vector3.new(0, 0.5, 0)

            -- VFX: individual bolt
            -- VFXRemote:FireAllClients("RedstoneOverdriveBolt", origin, boltDir)

            HitboxSystem.SpawnProjectile({
                Origin       = origin,
                Direction    = boltDir,
                Speed        = BOLT_SPEED,
                MaxRange     = BOLT_RANGE,
                HitboxRadius = 2.0,
                Attacker     = character,
                Gravity      = 0,
                OnHit        = function(victim, hitPos)
                    -- Shocked debuff
                    local vHum = victim:FindFirstChildOfClass("Humanoid")
                    if vHum then
                        local prev = vHum.WalkSpeed
                        vHum.WalkSpeed = prev * 0.5
                        task.delay(SHOCK_DUR, function()
                            if vHum.Parent then vHum.WalkSpeed = prev end
                        end)
                    end

                    HitStun.Apply(victim, {
                        Damage         = BOLT_DAMAGE,
                        StunType       = "light",
                        KnockbackForce = 10,
                        KnockbackDir   = boltDir,
                    })

                    -- Count hits per target
                    local id = tostring(victim)
                    hitCounts[id] = (hitCounts[id] or 0) + 1
                    if hitCounts[id] == 3 then
                        if vHum then
                            local prev = vHum.WalkSpeed
                            vHum.WalkSpeed = 0
                            task.delay(TRIPLE_STUN, function()
                                if vHum.Parent then vHum.WalkSpeed = prev end
                            end)
                        end
                    end

                    -- Spawn ground node at impact
                    HitboxSystem.SpawnLingeringZone({
                        Position     = hitPos,
                        Size         = Vector3.new(NODE_RADIUS*2, 3, NODE_RADIUS*2),
                        Duration     = NODE_DURATION,
                        TickInterval = 0.5,
                        Attacker     = character,
                        OnTick       = function(v)
                            HitStun.Apply(v, { Damage=NODE_DMG, StunType="light", KnockbackForce=0, KnockbackDir=Vector3.new(0,1,0) })
                        end,
                    })

                    -- VFX: hit crackle
                    -- VFXRemote:FireAllClients("RedstoneOverdriveHit", hitPos)
                end,
            })
        end)
    end
end

return Alex_RedstoneOverdrive
