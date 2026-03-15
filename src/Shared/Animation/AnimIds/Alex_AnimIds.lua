--[[
    Alex_AnimIds.lua  —  Steps 10 & 14
    All animation asset IDs for Alex (Green Shirt Gal).
    Style: agile, quick transitions, slight tech-gadget flavour.
--]]

return {
    -- ─── Locomotion ───────────────────────────────────────────────────────
    Idle          = "rbxassetid://ALEX_IDLE",
    Walk          = "rbxassetid://ALEX_WALK",
    Sprint        = "rbxassetid://ALEX_SPRINT",
    Jump          = "rbxassetid://ALEX_JUMP",
    Fall          = "rbxassetid://ALEX_FALL",
    Land          = "rbxassetid://ALEX_LAND",

    -- ─── Dash ─────────────────────────────────────────────────────────────
    DashForward   = "rbxassetid://ALEX_DASH_FWD",
    DashBackward  = "rbxassetid://ALEX_DASH_BWD",
    DashLeft      = "rbxassetid://ALEX_DASH_LEFT",
    DashRight     = "rbxassetid://ALEX_DASH_RIGHT",

    -- ─── M1 Combo — tool/weapon hybrid strikes ────────────────────────────
    -- Hit 1: horizontal pickaxe swipe
    M1_1          = "rbxassetid://ALEX_M1_1",
    -- Hit 2: reverse backhand tool strike
    M1_2          = "rbxassetid://ALEX_M1_2",
    -- Hit 3: diagonal upward cut
    M1_3          = "rbxassetid://ALEX_M1_3",
    -- Hit 4: overhead launcher smash (sends enemy airborne)
    M1_4          = "rbxassetid://ALEX_M1_4",

    -- ─── Defensive ────────────────────────────────────────────────────────
    BlockRaise    = "rbxassetid://ALEX_BLOCK_RAISE",
    BlockHold     = "rbxassetid://ALEX_BLOCK_HOLD",
    BlockLower    = "rbxassetid://ALEX_BLOCK_LOWER",
    Parry         = "rbxassetid://ALEX_PARRY",

    -- ─── Evasive ──────────────────────────────────────────────────────────
    Evasive       = "rbxassetid://ALEX_EVASIVE",

    -- ─── Base Abilities ───────────────────────────────────────────────────
    -- Q: Quarry Strike — overhead pickaxe mining arc
    QuarryStrike_Swing  = "rbxassetid://ALEX_QUARRYSTRIKE_SWING",
    QuarryStrike_Impact = "rbxassetid://ALEX_QUARRYSTRIKE_IMPACT",

    -- E: Advancement (buff activation) — arms light up with redstone circuits
    Advancement_Activate = "rbxassetid://ALEX_ADVANCEMENT_ACTIVATE",

    -- R: Redstone Pulse — arm extends forward, palm fires bolt
    RedstonePulse_Fire  = "rbxassetid://ALEX_REDSTONEPULSE_FIRE",

    -- F: Ender Shift — shimmer dissolve then rematerialise
    EnderShift_Out = "rbxassetid://ALEX_ENDERSHIFT_OUT",
    EnderShift_In  = "rbxassetid://ALEX_ENDERSHIFT_IN",

    -- ─── Ultimate Activation ──────────────────────────────────────────────
    -- Orbit cam, arms spread, dragon silhouette erupts, purple pulse
    UltActivate   = "rbxassetid://ALEX_ULT_ACTIVATE",
    UltFormIdle   = "rbxassetid://ALEX_ULT_FORM_IDLE",
    -- Dragon wing shimmer on back during ult form
    UltFormWings  = "rbxassetid://ALEX_ULT_FORM_WINGS",

    -- ─── Ultimate Abilities ───────────────────────────────────────────────
    -- Q: Enderbound Assault — rapid blink strikes
    EnderboundAssault_Blink = "rbxassetid://ALEX_ENDERBOUNDASSAULT_BLINK",
    EnderboundAssault_Strike = "rbxassetid://ALEX_ENDERBOUNDASSAULT_STRIKE",

    -- E: Redstone Overdrive — rapid-fire arm sequence
    RedstoneOverdrive_Fire  = "rbxassetid://ALEX_REDSTONEOVERDRIVE_FIRE",

    -- R: Dragonfall Execution — cinematic leap + dragon descent
    DragonFall_Ascend   = "rbxassetid://ALEX_DRAGONFALL_ASCEND",
    DragonFall_Peak     = "rbxassetid://ALEX_DRAGONFALL_PEAK",
    DragonFall_Dive     = "rbxassetid://ALEX_DRAGONFALL_DIVE",
    DragonFall_Impact   = "rbxassetid://ALEX_DRAGONFALL_IMPACT",
    DragonFall_Aftermath = "rbxassetid://ALEX_DRAGONFALL_AFTERMATH",

    -- ─── Hit reactions ────────────────────────────────────────────────────
    HitLight  = "rbxassetid://ALEX_HIT_LIGHT",
    HitHeavy  = "rbxassetid://ALEX_HIT_HEAVY",
    KnockBack = "rbxassetid://ALEX_KNOCKBACK",
    Launched  = "rbxassetid://ALEX_LAUNCHED",
}
