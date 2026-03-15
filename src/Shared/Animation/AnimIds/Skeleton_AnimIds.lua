--[[
    Skeleton_AnimIds.lua  —  Steps 10 & 14
    All animation asset IDs for Skeleton (Boney Sniper).
    Style: calculated, precise, ranged-specialist feel.
    Bow is always present; melee backup animations are short and reluctant.
--]]

return {
    -- ─── Locomotion ───────────────────────────────────────────────────────
    Idle          = "rbxassetid://SKELETON_IDLE",        -- bow held, scanning pose
    Walk          = "rbxassetid://SKELETON_WALK",        -- cautious backward steps
    Sprint        = "rbxassetid://SKELETON_SPRINT",      -- forward bow-carry run
    Jump          = "rbxassetid://SKELETON_JUMP",
    Fall          = "rbxassetid://SKELETON_FALL",
    Land          = "rbxassetid://SKELETON_LAND",

    -- ─── Dash ─────────────────────────────────────────────────────────────
    DashForward   = "rbxassetid://SKELETON_DASH_FWD",
    DashBackward  = "rbxassetid://SKELETON_DASH_BWD",   -- backstep hop focus
    DashLeft      = "rbxassetid://SKELETON_DASH_LEFT",
    DashRight     = "rbxassetid://SKELETON_DASH_RIGHT",

    -- ─── M1 Combo — bow bash / bone jab / short-range backup ─────────────
    -- Hit 1: bow stock horizontal bash
    M1_1          = "rbxassetid://SKELETON_M1_1",
    -- Hit 2: forward bone jab
    M1_2          = "rbxassetid://SKELETON_M1_2",
    -- Hit 3: spinning bow bash
    M1_3          = "rbxassetid://SKELETON_M1_3",
    -- Hit 4: heavy overhead bow smash with knockback
    M1_4          = "rbxassetid://SKELETON_M1_4",

    -- ─── Defensive ────────────────────────────────────────────────────────
    BlockRaise    = "rbxassetid://SKELETON_BLOCK_RAISE",
    BlockHold     = "rbxassetid://SKELETON_BLOCK_HOLD",
    BlockLower    = "rbxassetid://SKELETON_BLOCK_LOWER",
    Parry         = "rbxassetid://SKELETON_PARRY",

    -- ─── Evasive ──────────────────────────────────────────────────────────
    Evasive       = "rbxassetid://SKELETON_EVASIVE",     -- smoke/back-hop disengage

    -- ─── Base Abilities ───────────────────────────────────────────────────
    -- Q: Bone Barrage — rapid fan-fire from bow
    BoneBarrage_Fire = "rbxassetid://SKELETON_BONEBARRAGE_FIRE",

    -- E: Arrow Storm — arcing sky-volley gesture
    ArrowStorm_Fire  = "rbxassetid://SKELETON_ARROWSTORM_FIRE",

    -- R: Skeleton Trap — overhand throw of trap
    SkeletonTrap_Throw = "rbxassetid://SKELETON_SKELETONTRAP_THROW",

    -- F: Aimbot — lock-on aiming pose channel
    Aimbot_Channel   = "rbxassetid://SKELETON_AIMBOT_CHANNEL",
    Aimbot_Fire      = "rbxassetid://SKELETON_AIMBOT_FIRE",

    -- ─── Ultimate Activation ──────────────────────────────────────────────
    -- Eyes glow icy blue, bow crackles with bone energy, targeting lines appear
    UltActivate   = "rbxassetid://SKELETON_ULT_ACTIVATE",
    UltFormIdle   = "rbxassetid://SKELETON_ULT_FORM_IDLE",

    -- ─── Ultimate Abilities ───────────────────────────────────────────────
    -- Q: Perfect Aim Protocol — arms raise, targeting algorithm activates
    PerfectAimProtocol_Activate = "rbxassetid://SKELETON_PERFECTAIMPROTOCOL_ACTIVATE",

    -- E: Arrowstorm Barrage — sustained rapid-fire sequence
    ArrowstormBarrage_Fire = "rbxassetid://SKELETON_ARROWSTORM_BARRAGE",

    -- R: Bonebreaker Shot — full draw charge + powerful release
    BonebreakerShot_Charge  = "rbxassetid://SKELETON_BONEBREAKERSHOT_CHARGE",
    BonebreakerShot_Peak    = "rbxassetid://SKELETON_BONEBREAKERSHOT_PEAK",
    BonebreakerShot_Release = "rbxassetid://SKELETON_BONEBREAKERSHOT_RELEASE",
    BonebreakerShot_Follow  = "rbxassetid://SKELETON_BONEBREAKERSHOT_FOLLOW",

    -- ─── Hit reactions ────────────────────────────────────────────────────
    HitLight  = "rbxassetid://SKELETON_HIT_LIGHT",
    HitHeavy  = "rbxassetid://SKELETON_HIT_HEAVY",
    KnockBack = "rbxassetid://SKELETON_KNOCKBACK",
    Launched  = "rbxassetid://SKELETON_LAUNCHED",
}
