--[[
    Zombie_DecayWave.lua
    Ability: Decay Wave (F)
    Character: Zombie

    Description:
      Zombie releases a rippling wave of decay energy from his body outward.
      All enemies in range take heavy damage and have their armor/guard
      broken (guard health set to 0, guard break stun applied). The wave
      also degrades the terrain, leaving decay patches that tick 5 dmg/s
      for 5 seconds.

    Values:
      Cooldown        : 13.0 s
      Wave radius     : 10 studs
      Damage          : 40
      StunType        : heavy  (heavy hit-stop, guard break)
      Guard break     : forces guard to 0 if target is blocking
      KB Force        : 35 radial
      Hit-stop        : 0.18 s
      Decay patch     : 10 stud radius, 5 s, 5 dmg/s
      VFX             : decay mist ring burst, toxic green pulse outward,
                        ground decays and turns brown/black, pulsing patches
      Camera          : medium shake on wave
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Zombie_DecayWave = {}

local COOLDOWN      = 13.0
local WAVE_RADIUS   = 10
local DAMAGE        = 40
local KB_FORCE      = 35
local HITSTOP_DUR   = 0.18
local PATCH_RADIUS  = 10
local PATCH_DUR     = 5.0
local PATCH_DPS     = 5

function Zombie_DecayWave.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("DecayWave") then return end
    if not cooldowns:Start("DecayWave", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Zombie slams fists to ground
    -- AnimHelper.Play(character, "rbxassetid://ZOMBIE_DECAYWAVE_SLAM")

    -- Camera: medium shake
    -- CameraShakeRemote:FireAllClients("medium", rootPart.Position, 20)

    -- VFX: decay ring burst outward
    -- VFXRemote:FireAllClients("ZombieDecayWave", rootPart.Position)

    local waveCenter = rootPart.Position

    -- Hit-stop: attacker briefly freezes
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local prevSpeed = humanoid and humanoid.WalkSpeed or 14
    if humanoid then humanoid.WalkSpeed = 0 end
    task.delay(HITSTOP_DUR, function()
        if humanoid and humanoid.Parent then humanoid.WalkSpeed = prevSpeed end
    end)

    HitboxSystem.SpawnAoE({
        Position = waveCenter,
        Radius   = WAVE_RADIUS,
        Attacker = character,
        OnHit    = function(victim)
            local vRoot    = victim:FindFirstChild("HumanoidRootPart")
            local blastDir = vRoot and (vRoot.Position - waveCenter).Unit or Vector3.new(0,1,0)

            -- Guard break: signal to victim's BlockParrySystem
            victim:SetAttribute("DecayWaveGuardBreak", true)
            task.defer(function()
                victim:SetAttribute("DecayWaveGuardBreak", false)
            end)

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
                StunType       = "heavy",
                KnockbackForce = KB_FORCE,
                KnockbackDir   = blastDir,
            })
        end,
    })

    -- Leave decay patch lingering zone on ground
    HitboxSystem.SpawnLingeringZone({
        Position     = waveCenter,
        Size         = Vector3.new(PATCH_RADIUS * 2, 3, PATCH_RADIUS * 2),
        Duration     = PATCH_DUR,
        TickInterval = 1.0,
        Attacker     = character,
        OnTick       = function(victim)
            HitStun.Apply(victim, {
                Damage         = PATCH_DPS,
                StunType       = "light",
                KnockbackForce = 0,
                KnockbackDir   = Vector3.new(0, 1, 0),
            })
        end,
    })

    -- Terrain decay decal
    -- DestructionRemote:FireServer("DecayWave", waveCenter, PATCH_RADIUS)
end

return Zombie_DecayWave
