--[[
    Zombie_AnimIds.lua  —  Steps 10 & 14
    All animation asset IDs for Zombie (Undead Blue Shirt Guy).
    Style: slow, lurching, heavy — every hit feels impactful and rotten.
--]]

return {
    -- ─── Locomotion ───────────────────────────────────────────────────────
    Idle          = "rbxassetid://ZOMBIE_IDLE",          -- arms slightly raised, hunched
    Walk          = "rbxassetid://ZOMBIE_WALK",          -- shambling gait
    Sprint        = "rbxassetid://ZOMBIE_SPRINT",        -- frenzied lurch-run
    Jump          = "rbxassetid://ZOMBIE_JUMP",
    Fall          = "rbxassetid://ZOMBIE_FALL",
    Land          = "rbxassetid://ZOMBIE_LAND",          -- heavy thud

    -- ─── Dash ─────────────────────────────────────────────────────────────
    DashForward   = "rbxassetid://ZOMBIE_DASH_FWD",      -- lunging stumble forward
    DashBackward  = "rbxassetid://ZOMBIE_DASH_BWD",
    DashLeft      = "rbxassetid://ZOMBIE_DASH_LEFT",
    DashRight     = "rbxassetid://ZOMBIE_DASH_RIGHT",

    -- ─── M1 Combo — claw / slash attacks ─────────────────────────────────
    -- Hit 1: right claw swipe
    M1_1          = "rbxassetid://ZOMBIE_M1_1",
    -- Hit 2: left claw swipe
    M1_2          = "rbxassetid://ZOMBIE_M1_2",
    -- Hit 3: two-hand overhead claw smash (partial stun)
    M1_3          = "rbxassetid://ZOMBIE_M1_3",
    -- Hit 4: lunging dual-claw finisher with heavy knockback
    M1_4          = "rbxassetid://ZOMBIE_M1_4",

    -- ─── Defensive ────────────────────────────────────────────────────────
    BlockRaise    = "rbxassetid://ZOMBIE_BLOCK_RAISE",
    BlockHold     = "rbxassetid://ZOMBIE_BLOCK_HOLD",
    BlockLower    = "rbxassetid://ZOMBIE_BLOCK_LOWER",
    Parry         = "rbxassetid://ZOMBIE_PARRY",

    -- ─── Evasive ──────────────────────────────────────────────────────────
    Evasive       = "rbxassetid://ZOMBIE_EVASIVE",       -- lunging stumble escape

    -- ─── Base Abilities ───────────────────────────────────────────────────
    -- Q: Undead Slash — vicious claw double-swipe
    UndeadSlash_1 = "rbxassetid://ZOMBIE_UNDEADSLASH_1",
    UndeadSlash_2 = "rbxassetid://ZOMBIE_UNDEADSLASH_2",

    -- E: Zombie Plague — retching / vomit forward
    ZombiePlague_Vomit  = "rbxassetid://ZOMBIE_ZOMBIEPLAGUE_VOMIT",

    -- R: Zombie Horde — summoning gesture, arms rise upward
    ZombieHorde_Summon  = "rbxassetid://ZOMBIE_ZOMBIEHORDE_SUMMON",

    -- F: Decay Wave — fist slam into ground, shockwave ripples out
    DecayWave_Slam      = "rbxassetid://ZOMBIE_DECAYWAVE_SLAM",
    DecayWave_Rise      = "rbxassetid://ZOMBIE_DECAYWAVE_RISE",

    -- ─── Ultimate Activation ──────────────────────────────────────────────
    -- Zombie lurches, eyes glow green, arms spread, decay mist erupts
    UltActivate   = "rbxassetid://ZOMBIE_ULT_ACTIVATE",
    UltFormIdle   = "rbxassetid://ZOMBIE_ULT_FORM_IDLE",   -- hungering forward lean
    UltFormRoar   = "rbxassetid://ZOMBIE_ULT_FORM_ROAR",   -- roar at camera on activate

    -- ─── Ultimate Abilities ───────────────────────────────────────────────
    -- Q: Infection Spread — massive arms-out burst explosion
    InfectionSpread_Burst = "rbxassetid://ZOMBIE_INFECTIONSPREAD_BURST",

    -- E: Grave March — charge pose + slam finale
    GraveMarch_Charge  = "rbxassetid://ZOMBIE_GRAVEMARCH_CHARGE",
    GraveMarch_March   = "rbxassetid://ZOMBIE_GRAVEMARCH_MARCH",    -- looping during charge
    GraveMarch_Slam    = "rbxassetid://ZOMBIE_GRAVEMARCH_SLAM",

    -- R: Relentless Hunger — lunge + 3 bite animations
    RelentlessHunger_Lunge  = "rbxassetid://ZOMBIE_RELENTLESSHUNGER_LUNGE",
    RelentlessHunger_Bite1  = "rbxassetid://ZOMBIE_BITE_1",
    RelentlessHunger_Bite2  = "rbxassetid://ZOMBIE_BITE_2",
    RelentlessHunger_Bite3  = "rbxassetid://ZOMBIE_BITE_3",

    -- ─── Hit reactions ────────────────────────────────────────────────────
    HitLight  = "rbxassetid://ZOMBIE_HIT_LIGHT",
    HitHeavy  = "rbxassetid://ZOMBIE_HIT_HEAVY",
    KnockBack = "rbxassetid://ZOMBIE_KNOCKBACK",
    Launched  = "rbxassetid://ZOMBIE_LAUNCHED",
}
