--[[
    Steve_AnimIds.lua  —  Steps 10 & 14
    All animation asset IDs for Steve (Blue Shirt Guy).

    Naming convention:
      Base move anims : short, punchy, sword-combat style
      Ult move anims  : heavier, slower wind-up, cinematic weight

    Replace placeholder IDs with real Roblox animation asset IDs
    once animations are authored in the Animation Editor.
--]]

return {
    -- ─── Locomotion ───────────────────────────────────────────────────────
    Idle          = "rbxassetid://STEVE_IDLE",
    Walk          = "rbxassetid://STEVE_WALK",
    Sprint        = "rbxassetid://STEVE_SPRINT",
    Jump          = "rbxassetid://STEVE_JUMP",
    Fall          = "rbxassetid://STEVE_FALL",
    Land          = "rbxassetid://STEVE_LAND",

    -- ─── Dash (Step 2) ────────────────────────────────────────────────────
    DashForward   = "rbxassetid://STEVE_DASH_FWD",
    DashBackward  = "rbxassetid://STEVE_DASH_BWD",
    DashLeft      = "rbxassetid://STEVE_DASH_LEFT",
    DashRight     = "rbxassetid://STEVE_DASH_RIGHT",

    -- ─── M1 Combo (Step 3) — sword swings ─────────────────────────────────
    -- Hit 1: diagonal left-to-right slash
    M1_1          = "rbxassetid://STEVE_M1_1",
    -- Hit 2: right-to-left counter slash
    M1_2          = "rbxassetid://STEVE_M1_2",
    -- Hit 3: upward cut (opens combo)
    M1_3          = "rbxassetid://STEVE_M1_3",
    -- Hit 4: downward finishing slam with knockback
    M1_4          = "rbxassetid://STEVE_M1_4",

    -- ─── Defensive (Step 7) ───────────────────────────────────────────────
    BlockRaise    = "rbxassetid://STEVE_BLOCK_RAISE",
    BlockHold     = "rbxassetid://STEVE_BLOCK_HOLD",
    BlockLower    = "rbxassetid://STEVE_BLOCK_LOWER",
    Parry         = "rbxassetid://STEVE_PARRY",

    -- ─── Evasive (Step 8) ─────────────────────────────────────────────────
    Evasive       = "rbxassetid://STEVE_EVASIVE",

    -- ─── Base Abilities (Step 9/10) ───────────────────────────────────────
    -- Q: Oak Shield — shield raise + brace pose
    OakShield_Raise   = "rbxassetid://STEVE_OAKSHIELD_RAISE",
    OakShield_Hold    = "rbxassetid://STEVE_OAKSHIELD_HOLD",
    OakShield_Shatter = "rbxassetid://STEVE_OAKSHIELD_SHATTER",

    -- E: Advancement — forward charge with sword levelled
    Advancement_Charge = "rbxassetid://STEVE_ADVANCEMENT_CHARGE",
    Advancement_Hit    = "rbxassetid://STEVE_ADVANCEMENT_HIT",

    -- R: Sword Slash — horizontal arc x2
    SwordSlash_1  = "rbxassetid://STEVE_SLASH_1",
    SwordSlash_2  = "rbxassetid://STEVE_SLASH_2",

    -- F: TNT Toss — overhead throw arc
    TNTToss_Throw = "rbxassetid://STEVE_TNTTOSS_THROW",

    -- ─── Ultimate Activation (Step 12) ────────────────────────────────────
    -- Full cinematic: eyes glow, black smoke rises, arms spread
    UltActivate   = "rbxassetid://STEVE_ULT_ACTIVATE",
    -- Idle inside ult form: aggressive forward stance, smoke aura
    UltFormIdle   = "rbxassetid://STEVE_ULT_FORM_IDLE",

    -- ─── Ultimate Abilities (Step 13/14) ──────────────────────────────────
    -- Q: Creative Override — flash of light, speed burst pose
    CreativeOverride_Start = "rbxassetid://STEVE_CREATIVEOVERRIDE_START",

    -- E: World Edit Cleave — two-hand sword raise to ground slam
    WorldEditCleave_Raise  = "rbxassetid://STEVE_WORLDEDITCLEAVE_RAISE",
    WorldEditCleave_Slam   = "rbxassetid://STEVE_WORLDEDITCLEAVE",

    -- R: Last Block Standing — full cinematic leap + descend + slam
    LastBlock_Ascend   = "rbxassetid://STEVE_LASTBLOCK_ASCEND",
    LastBlock_Peak     = "rbxassetid://STEVE_LASTBLOCK_PEAK",
    LastBlock_Descend  = "rbxassetid://STEVE_LASTBLOCK_DESCEND",
    LastBlock_Land     = "rbxassetid://STEVE_LASTBLOCK_LAND",
    LastBlock_Aftermath = "rbxassetid://STEVE_LASTBLOCK_AFTERMATH",

    -- ─── Hit reactions ────────────────────────────────────────────────────
    HitLight  = "rbxassetid://STEVE_HIT_LIGHT",
    HitHeavy  = "rbxassetid://STEVE_HIT_HEAVY",
    KnockBack = "rbxassetid://STEVE_KNOCKBACK",
    Launched  = "rbxassetid://STEVE_LAUNCHED",
}
