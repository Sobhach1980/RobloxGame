--[[
    SoundIds.lua
    Central registry of every sound asset ID used in the game.
    Replace each 0 with the real Roblox asset ID once sounds are uploaded.

    Access:
      local SoundIds = require(SoundIds)
      SoundIds.Combat_M1Hit  --> number (asset id)
--]]

return {
    -- ── UI / Match flow ──────────────────────────────────────────────────
    UI_CharHover    = 0,   -- character card hovered on select screen
    UI_CharConfirm  = 0,   -- character locked in
    UI_Countdown    = 0,   -- 3-2-1 beep
    UI_Fight        = 0,   -- "FIGHT!" announcement sting
    UI_RoundEnd     = 0,   -- round end sting
    UI_Victory      = 0,   -- match winner jingle
    UI_Defeat       = 0,   -- match loss jingle
    UI_Draw         = 0,   -- draw jingle
    UI_TimeLow      = 0,   -- timer ticking when ≤10s remain

    -- ── Combat shared ────────────────────────────────────────────────────
    Combat_M1Hit    = 0,   -- light punch / hit
    Combat_M1Block  = 0,   -- blocked hit (thud)
    Combat_Parry    = 0,   -- successful parry (ring)
    Combat_Dash     = 0,   -- dash whoosh
    Combat_Evasive  = 0,   -- evasive roll
    Combat_Launch   = 0,   -- launcher hit (heavy)
    Combat_Land     = 0,   -- heavy landing
    Combat_Death    = 0,   -- death burst

    -- ── Steve ────────────────────────────────────────────────────────────
    Steve_OakShield      = 0,
    Steve_Advancement    = 0,
    Steve_SwordSlash     = 0,
    Steve_TNTToss        = 0,
    Steve_TNTExplode     = 0,
    Steve_UltActivate    = 0,
    Steve_CreativeOvrd   = 0,
    Steve_WorldEdit      = 0,
    Steve_LastBlock      = 0,

    -- ── Alex ─────────────────────────────────────────────────────────────
    Alex_QuarryStrike    = 0,
    Alex_Advancement     = 0,
    Alex_RedstonePulse   = 0,
    Alex_EnderShift      = 0,
    Alex_UltActivate     = 0,
    Alex_EnderboundAss   = 0,
    Alex_RedstoneOvrd    = 0,
    Alex_DragonFall      = 0,

    -- ── Zombie ───────────────────────────────────────────────────────────
    Zombie_UndeadSlash   = 0,
    Zombie_ZombiePlague  = 0,
    Zombie_ZombieHorde   = 0,
    Zombie_DecayWave     = 0,
    Zombie_UltActivate   = 0,
    Zombie_Infection     = 0,
    Zombie_GraveMarch    = 0,
    Zombie_Relentless    = 0,

    -- ── Enderman ─────────────────────────────────────────────────────────
    End_Teleport          = 0,
    End_Strike            = 0,
    End_Cloak             = 0,
    End_TeleSlam          = 0,
    End_UltActivate       = 0,
    End_VoidstepFrenzy    = 0,
    End_StolenGround      = 0,
    End_YouShouldntLook   = 0,

    -- ── Skeleton ─────────────────────────────────────────────────────────
    Skel_BoneBarrage      = 0,
    Skel_ArrowStorm       = 0,
    Skel_SkeletonTrap     = 0,
    Skel_Aimbot           = 0,
    Skel_UltActivate      = 0,
    Skel_PerfectAim       = 0,
    Skel_ArrowstormBar    = 0,
    Skel_Bonebreaker      = 0,

    -- ── Arena / Environment ───────────────────────────────────────────────
    Arena_Ambience        = 0,
    Arena_RoundBell       = 0,
}
