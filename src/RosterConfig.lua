--[[
    RosterConfig.lua
    Central configuration for all 5 characters.
    Used by character select, HUD, matchmaking, and the controller factory.
--]]

local RosterConfig = {}

RosterConfig.Characters = {
    {
        Id          = "Steve",
        DisplayName = "Steve",
        Subtitle    = "Blue Shirt Guy",
        Role        = "Balanced",
        Description = "A sturdy, grounded sword fighter. Iron-strong offense with an impenetrable last stand ultimate.",
        Strengths   = { "High damage combo potential", "Strong defensive kit", "Powerful arena ult" },
        Ultimate    = {
            Name        = "Undying Resurgence",
            Duration    = 30,
            Description = "Steve enters his final form, swapping to Creative Override, World Edit Cleave, and Last Block Standing.",
            Abilities   = { "Creative Override", "World Edit Cleave", "Last Block Standing" },
        },
        BaseAbilities = {
            { Slot="Q", Name="Oak Shield",   Cooldown=10.0 },
            { Slot="E", Name="Advancement",  Cooldown=8.0  },
            { Slot="R", Name="Sword Slash",  Cooldown=5.0  },
            { Slot="F", Name="TNT Toss",     Cooldown=12.0 },
        },
        ControllerModule = "Characters.Steve.SteveController",
    },
    {
        Id          = "Alex",
        DisplayName = "Alex",
        Subtitle    = "Green Shirt Gal",
        Role        = "Agile Utility",
        Description = "A fast, technical fighter who synergises redstone tech with ender energy and a devastating dragon ult.",
        Strengths   = { "High mobility", "Advancement buff synergy", "Cinematic finisher" },
        Ultimate    = {
            Name        = "Dragon's Awakening",
            Duration    = 28,
            Description = "Alex channels the dragon, swapping to Enderbound Assault, Redstone Overdrive, and Dragonfall Execution.",
            Abilities   = { "Enderbound Assault", "Redstone Overdrive", "Dragonfall Execution" },
        },
        BaseAbilities = {
            { Slot="Q", Name="Quarry Strike",   Cooldown=7.0  },
            { Slot="E", Name="Advancement",     Cooldown=9.0  },
            { Slot="R", Name="Redstone Pulse",  Cooldown=6.0  },
            { Slot="F", Name="Ender Shift",     Cooldown=8.5  },
        },
        ControllerModule = "Characters.Alex.AlexController",
    },
    {
        Id          = "Zombie",
        DisplayName = "Zombie",
        Subtitle    = "Undead Blue Shirt Guy",
        Role        = "Heavy Brawler",
        Description = "Slow and relentless. Infects enemies, summons minions, and ends fights with an unstoppable hunger.",
        Strengths   = { "High damage per hit", "Infection DOT pressure", "Minion zone control" },
        Ultimate    = {
            Name        = "Relentless Hunger",
            Duration    = 25,
            Description = "Zombie embraces undying hunger, swapping to Infection Spread, Grave March, and Relentless Hunger.",
            Abilities   = { "Infection Spread", "Grave March", "Relentless Hunger" },
        },
        BaseAbilities = {
            { Slot="Q", Name="Undead Slash",  Cooldown=6.0  },
            { Slot="E", Name="Zombie Plague", Cooldown=11.0 },
            { Slot="R", Name="Zombie Horde",  Cooldown=14.0 },
            { Slot="F", Name="Decay Wave",    Cooldown=13.0 },
        },
        ControllerModule = "Characters.Zombie.ZombieController",
    },
    {
        Id          = "Enderman",
        DisplayName = "Enderman",
        Subtitle    = "Tall Guy",
        Role        = "Elusive Assassin",
        Description = "Floaty, disorienting, and terrifying. Teleports constantly, dominates space, and pulls enemies into the void.",
        Strengths   = { "Best reposition in roster", "Disorient / cloak utility", "Void Dominion terrain control" },
        Ultimate    = {
            Name        = "Void Dominion",
            Duration    = 22,
            Description = "Enderman ascends to Void Dominion, swapping to Voidstep Frenzy, Stolen Ground, and You Shouldn't Look.",
            Abilities   = { "Voidstep Frenzy", "Stolen Ground", "You Shouldn't Look" },
        },
        BaseAbilities = {
            { Slot="Q", Name="Ender Teleportation", Cooldown=5.0  },
            { Slot="E", Name="Ender Strike",        Cooldown=7.0  },
            { Slot="R", Name="Ender Cloak",         Cooldown=10.0 },
            { Slot="F", Name="Teleportation Slam",  Cooldown=12.0 },
        },
        ControllerModule = "Characters.Enderman.EndermanController",
    },
    {
        Id          = "Skeleton",
        DisplayName = "Skeleton",
        Subtitle    = "Boney Sniper",
        Role        = "Precision Ranged",
        Description = "A calculating long-range specialist. Traps, tracking arrows, and a charged shot that can end any match.",
        Strengths   = { "Longest range in roster", "Area denial traps", "Bonebreaker finisher" },
        Ultimate    = {
            Name        = "Perfect Aim",
            Duration    = 20,
            Description = "Skeleton achieves Perfect Aim, swapping to Perfect Aim Protocol, Arrowstorm Barrage, and Bonebreaker Shot.",
            Abilities   = { "Perfect Aim Protocol", "Arrowstorm Barrage", "Bonebreaker Shot" },
        },
        BaseAbilities = {
            { Slot="Q", Name="Bone Barrage",   Cooldown=7.0  },
            { Slot="E", Name="Arrow Storm",    Cooldown=10.0 },
            { Slot="R", Name="Skeleton Trap",  Cooldown=9.0  },
            { Slot="F", Name="Aimbot",         Cooldown=11.0 },
        },
        ControllerModule = "Characters.Skeleton.SkeletonController",
    },
}

-- Fast lookup by ID
RosterConfig.ById = {}
for _, char in ipairs(RosterConfig.Characters) do
    RosterConfig.ById[char.Id] = char
end

-- Returns the config entry for the given character ID, or nil
function RosterConfig.Get(characterId)
    return RosterConfig.ById[characterId]
end

-- Returns the display order index (1–5)
function RosterConfig.GetIndex(characterId)
    for i, char in ipairs(RosterConfig.Characters) do
        if char.Id == characterId then return i end
    end
    return nil
end

return RosterConfig
