--[[
    VFXSystem.lua  —  Step 15
    Server-side VFX event dispatcher.
    All ability/combat scripts call VFXSystem.Fire(...) instead of
    directly calling RemoteEvents. VFXSystem handles:
      - Choosing which clients to notify (all / local / proximity)
      - Packaging the event payload
      - Rate-limiting / deduplication if needed

    The actual visual work happens in Client/VFXHandler.lua which
    receives these events and uses ImpactEffect, AuraEffect,
    ExplosionEffect, and ProjectileTrail.

    VFX Event Names (used as the first argument to Fire):
    ─────────────────────────────────────────────────────
    -- Combat
    "MeleeHit"         position, presetName
    "ParryClash"       position
    "GuardBreak"       position
    "Ragdoll"          character

    -- Steve
    "SteveOakShieldUp"        character
    "SteveOakShieldShatter"   position
    "SteveAdvancement"        character, direction
    "SteveSwordSlash"         position, isFirstHit
    "SteveTNTFly"             origin, direction, speed, gravity, fuseTime
    "SteveTNTExplosion"       position
    "SteveCreativeOverride"   character, active
    "SteveWorldEditCleave"    position, direction
    "SteveLastBlockAscend"    character
    "SteveLastBlockSlam"      position

    -- Alex
    "AlexQuarryStrike"        position, direction
    "AlexAdvancement"         character, active
    "AlexRedstonePulse"       origin, direction, advancementActive
    "AlexRedstonePulseHit"    position
    "AlexEnderShiftOut"       position
    "AlexEnderShiftIn"        position, advancementActive
    "AlexEnderboundBlink"     position, strikeIndex
    "AlexRedstoneOverdrive"   character
    "AlexRedstoneOverdriveHit" position
    "AlexDragonFallAscend"    character
    "AlexDragonFallImpact"    position

    -- Zombie
    "ZombieUndeadSlash"       position, isSecondHit
    "ZombieBleedStart"        character
    "ZombieBleedEnd"          character
    "ZombiePlagueCloud"       origin, direction
    "ZombiePlagueInfect"      character, depth
    "ZombiePlagueChain"       pos1, pos2
    "ZombieHordeMinionSpawn"  position, index
    "ZombieMinionDeath"       position
    "ZombieDecayWave"         position
    "ZombieGraveMarch"        character, active
    "ZombieInfectionSpread"   position, radius
    "ZombieRelentlessHungerLunge" position, direction
    "ZombieLifesteal"         position, amount

    -- Enderman
    "EndermanTeleportOut"     position
    "EndermanTeleportIn"      position
    "EndermanEnderStrikeBlink" position
    "EndermanEnderStrikeHit"  position, wasBackstab
    "EndermanEnderCloakStart" character
    "EndermanEnderCloakEnd"   character
    "EndermanTeleportSlamAbove" position
    "EndermanTeleportSlamLand" position
    "EndermanVoidstepBlink"   position, strikeIndex, isFinal
    "EndermanStolenGroundRip" position, radius
    "EndermanStolenGroundImpact" position
    "EndermanYouShouldntLookCage" position
    "EndermanPhantomStrike"   position, index
    "EndermanYouShouldntLookFinale" position

    -- Skeleton
    "SkeletonBoneBarrageStart" origin, direction
    "SkeletonBoneShard"       origin, direction, index
    "SkeletonBoneShardHit"    position
    "SkeletonBoneShardEmbedded" position, direction
    "SkeletonArrowStormZone"  position, radius
    "SkeletonArrowStormArrow" origin, target
    "SkeletonArrowStormImpact" position
    "SkeletonTrapPlaced"      position
    "SkeletonTrapTriggered"   position
    "SkeletonOpenShotBuff"    character
    "SkeletonAimbotChannel"   character
    "SkeletonAimbotLock"      position
    "SkeletonAimbotArrow"     origin, direction
    "SkeletonAimbotHit"       position
    "SkeletonArrowstormBarrageStart" character
    "SkeletonArrowstormBarrageArrow" origin, direction, index
    "SkeletonArrowstormBarrageHit"   position
    "SkeletonBonebreakerCharge" character, chargeTime
    "SkeletonBonebreakerFire" origin, direction
    "SkeletonBonebreakerHit"  position
    "SkeletonBonebreakerShardCone" position, direction, angle
    "SkeletonMarkApplied"     position
    "SkeletonPerfectAimProtocol" character, active

    -- Ultimates
    "UltGaugeReady"     character
--]]

local VFXSystem = {}

-- Will be set by GameServer after RemoteEvents are created
local _vfxRemote = nil

function VFXSystem.Init(vfxRemoteEvent)
    _vfxRemote = vfxRemoteEvent
end

--[[
    Fire(eventName, ...)
    Fires to all clients. Additional varargs are forwarded as-is.
--]]
function VFXSystem.Fire(eventName, ...)
    if not _vfxRemote then return end
    _vfxRemote:FireAllClients(eventName, ...)
end

--[[
    FireToPlayer(player, eventName, ...)
    Fires only to a specific player's client (e.g. local screen effects).
--]]
function VFXSystem.FireToPlayer(player, eventName, ...)
    if not _vfxRemote then return end
    _vfxRemote:FireClient(player, eventName, ...)
end

--[[
    FireNearby(position, radius, eventName, ...)
    Fires only to players whose characters are within radius of position.
    Reduces bandwidth for localised effects.
--]]
function VFXSystem.FireNearby(position, radius, eventName, ...)
    if not _vfxRemote then return end
    local Players = game:GetService("Players")
    local args    = { eventName, ... }
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - position).Magnitude <= radius then
            _vfxRemote:FireClient(player, table.unpack(args))
        end
    end
end

return VFXSystem
