--[[
    Steve_TNTToss.lua
    Ability: TNT Toss (F)
    Character: Steve

    Description:
      Steve hurls a primed TNT block in an arc. After a 1.5 s fuse it
      detonates in an AoE explosion, dealing high damage and explosive
      knockback in a radius. Enemies in the outer ring take splash damage.
      Terrain destructibles in range are broken.

    Values:
      Cooldown        : 12.0 s
      Projectile speed: 40 (arced trajectory, gravity = 35)
      Fuse time       : 1.5 s
      Inner AoE radius: 7  studs  |  Damage: 50
      Outer AoE radius: 12 studs  |  Damage: 25
      Knockback       : 75 inner, 40 outer (explosive radial)
      VFX             : TNT block flies, flashes on fuse, explosion + debris
      Camera          : medium screen shake on explosion
      Ragdoll         : inner-zone hits trigger ragdoll on heavy
--]]

local HitboxSystem = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitboxSystem)
local HitStun      = require(script.Parent.Parent.Parent.Parent.Shared.CombatEngine.HitStunKnockback)

local Steve_TNTToss = {}

local COOLDOWN     = 12.0
local PROJ_SPEED   = 40
local PROJ_GRAVITY = 35
local FUSE_TIME    = 1.5
local INNER_RADIUS = 7
local OUTER_RADIUS = 12

function Steve_TNTToss.Use(character, cooldowns, movementSystem)
    if cooldowns:IsOnCooldown("TNTToss") then return end
    if not cooldowns:Start("TNTToss", COOLDOWN) then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Play throw animation
    -- AnimHelper.Play(character, "rbxassetid://STEVE_TNTTOSS_THROW")

    local throwDir = rootPart.CFrame.LookVector + Vector3.new(0, 0.4, 0)
    throwDir = throwDir.Unit

    -- Spawn TNT visual part (client-side visual, server tracks position)
    local tntPosition = rootPart.Position + Vector3.new(0, 1, 0)

    -- Fire spawn event to client for visual TNT prop
    -- ProjVisualRemote:FireAllClients("TNTBlock", tntPosition, throwDir, PROJ_SPEED, PROJ_GRAVITY, FUSE_TIME)

    -- Simulate projectile on server for hit detection
    local pos       = tntPosition
    local vel       = throwDir * PROJ_SPEED
    local elapsed   = 0
    local detonated = false
    local conn

    conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if detonated then return end
        elapsed = elapsed + dt

        -- Update position with gravity
        vel     = vel + Vector3.new(0, -PROJ_GRAVITY * dt, 0)
        pos     = pos + vel * dt

        -- Fuse check
        if elapsed >= FUSE_TIME then
            detonated = true
            conn:Disconnect()
            Steve_TNTToss._explode(character, pos)
            return
        end

        -- Ground/terrain collision
        local rp = RaycastParams.new()
        rp.FilterDescendantsInstances = {character}
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local hit = workspace:Raycast(pos, vel.Unit * 2, rp)
        if hit then
            detonated = true
            conn:Disconnect()
            Steve_TNTToss._explode(character, pos)
        end
    end)
end

function Steve_TNTToss._explode(character, position)
    -- VFX: explosion, debris, screen shake
    -- VFXRemote:FireAllClients("TNTExplosion", position)
    -- CameraShakeRemote:FireAllClients("medium", position, 20)

    -- Damage environment destructibles
    -- DestructionRemote:FireServer("TNTExplosion", position, OUTER_RADIUS)

    -- Inner AoE
    HitboxSystem.SpawnAoE({
        Position   = position,
        Radius     = INNER_RADIUS,
        Attacker   = character,
        OnHit      = function(victim)
            local rootPart  = victim:FindFirstChild("HumanoidRootPart")
            local blastDir  = rootPart and (rootPart.Position - position).Unit or Vector3.new(0,1,0)
            HitStun.Apply(victim, {
                Damage         = 50,
                StunType       = "heavy",
                KnockbackForce = 75,
                KnockbackDir   = blastDir,
                IsGroundBounce = true,
            })
        end,
    })

    -- Outer splash AoE (different instance so inner targets not double-hit)
    -- NOTE: inner targets already in HitboxSystem hitSet so won't re-trigger
    HitboxSystem.SpawnAoE({
        Position   = position,
        Radius     = OUTER_RADIUS,
        Attacker   = character,
        OnHit      = function(victim)
            local rootPart = victim:FindFirstChild("HumanoidRootPart")
            local blastDir = rootPart and (rootPart.Position - position).Unit or Vector3.new(0,1,0)
            -- Only hit targets NOT already hit by inner (server should de-dup by player ID)
            HitStun.Apply(victim, {
                Damage         = 25,
                StunType       = "medium",
                KnockbackForce = 40,
                KnockbackDir   = blastDir,
            })
        end,
    })
end

return Steve_TNTToss
