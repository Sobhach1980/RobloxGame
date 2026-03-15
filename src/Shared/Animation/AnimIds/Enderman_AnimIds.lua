--[[
    Enderman_AnimIds.lua  —  Steps 10 & 14
    All animation asset IDs for Enderman (Tall Guy).
    Style: lanky, floaty, unsettling — limbs move slightly independently,
    idle has a slight sway, attacks are long-reach and deliberate.
--]]

return {
    -- ─── Locomotion ───────────────────────────────────────────────────────
    Idle          = "rbxassetid://ENDERMAN_IDLE",        -- slow sway, arms slightly raised
    Walk          = "rbxassetid://ENDERMAN_WALK",        -- long strides, slightly floating
    Sprint        = "rbxassetid://ENDERMAN_SPRINT",      -- gliding sprint with void trails
    Jump          = "rbxassetid://ENDERMAN_JUMP",
    Fall          = "rbxassetid://ENDERMAN_FALL",        -- arms spread wide
    Land          = "rbxassetid://ENDERMAN_LAND",

    -- ─── Dash ─────────────────────────────────────────────────────────────
    DashForward   = "rbxassetid://ENDERMAN_DASH_FWD",   -- teleport-style blur
    DashBackward  = "rbxassetid://ENDERMAN_DASH_BWD",
    DashLeft      = "rbxassetid://ENDERMAN_DASH_LEFT",
    DashRight     = "rbxassetid://ENDERMAN_DASH_RIGHT",

    -- ─── M1 Combo — long-arm void swipes ─────────────────────────────────
    -- Hit 1: extended left-arm horizontal sweep
    M1_1          = "rbxassetid://ENDERMAN_M1_1",
    -- Hit 2: extended right-arm counter sweep
    M1_2          = "rbxassetid://ENDERMAN_M1_2",
    -- Hit 3: dual-arm void push (medium stun)
    M1_3          = "rbxassetid://ENDERMAN_M1_3",
    -- Hit 4: overhead void slam with heavy knockback
    M1_4          = "rbxassetid://ENDERMAN_M1_4",

    -- ─── Defensive ────────────────────────────────────────────────────────
    BlockRaise    = "rbxassetid://ENDERMAN_BLOCK_RAISE",
    BlockHold     = "rbxassetid://ENDERMAN_BLOCK_HOLD",
    BlockLower    = "rbxassetid://ENDERMAN_BLOCK_LOWER",
    Parry         = "rbxassetid://ENDERMAN_PARRY",

    -- ─── Evasive ──────────────────────────────────────────────────────────
    Evasive       = "rbxassetid://ENDERMAN_EVASIVE",     -- blink vanish

    -- ─── Base Abilities ───────────────────────────────────────────────────
    -- Q: Ender Teleportation — dissolve out + materialise in
    EnderTeleport_Out = "rbxassetid://ENDERMAN_TELEPORT_OUT",
    EnderTeleport_In  = "rbxassetid://ENDERMAN_TELEPORT_IN",

    -- E: Ender Strike — warp-behind lunge + backstab
    EnderStrike_Blink = "rbxassetid://ENDERMAN_ENDERSTRIKE_BLINK",
    EnderStrike_Stab  = "rbxassetid://ENDERMAN_ENDERSTRIKE_STAB",

    -- R: Ender Cloak — slow shimmer vanish
    EnderCloak_Vanish = "rbxassetid://ENDERMAN_ENDERCLOAK_VANISH",
    EnderCloak_Appear = "rbxassetid://ENDERMAN_ENDERCLOAK_APPEAR",

    -- F: Teleportation Slam — ascend above + dive
    TeleportSlam_Ascend = "rbxassetid://ENDERMAN_TELEPORTSLAM_ASCEND",
    TeleportSlam_Dive   = "rbxassetid://ENDERMAN_TELEPORTSLAM_DIVE",
    TeleportSlam_Land   = "rbxassetid://ENDERMAN_TELEPORTSLAM_LAND",

    -- ─── Ultimate Activation ──────────────────────────────────────────────
    -- Screen distorts, void erupts, terrain floats, eyes go full purple
    UltActivate   = "rbxassetid://ENDERMAN_ULT_ACTIVATE",
    UltFormIdle   = "rbxassetid://ENDERMAN_ULT_FORM_IDLE",
    UltFormFloat  = "rbxassetid://ENDERMAN_ULT_FORM_FLOAT",   -- slight levitation during ult

    -- ─── Ultimate Abilities ───────────────────────────────────────────────
    -- Q: Voidstep Frenzy — 6 rapid blink-strike cycles
    VoidstepFrenzy_Blink  = "rbxassetid://ENDERMAN_VOIDSTEP_BLINK",
    VoidstepFrenzy_Strike = "rbxassetid://ENDERMAN_VOIDSTEP_STRIKE",

    -- E: Stolen Ground — terrain rip + hurl
    StolenGround_Rip   = "rbxassetid://ENDERMAN_STOLENGROUND_RIP",
    StolenGround_Hurl  = "rbxassetid://ENDERMAN_STOLENGROUND_HURL",

    -- R: You Shouldn't Look — cinematic void cage + phantom strikes + finale
    YouShouldntLook_Init     = "rbxassetid://ENDERMAN_YOUSHOULDNTLOOK_INIT",
    YouShouldntLook_Phantom  = "rbxassetid://ENDERMAN_YOUSHOULDNTLOOK_PHANTOM",
    YouShouldntLook_Finale   = "rbxassetid://ENDERMAN_YOUSHOULDNTLOOK_FINALE",

    -- ─── Hit reactions ────────────────────────────────────────────────────
    HitLight  = "rbxassetid://ENDERMAN_HIT_LIGHT",
    HitHeavy  = "rbxassetid://ENDERMAN_HIT_HEAVY",
    KnockBack = "rbxassetid://ENDERMAN_KNOCKBACK",
    Launched  = "rbxassetid://ENDERMAN_LAUNCHED",
}
