local addonName, ns = ...

-- Map ID for Twilight Highlands (confirmed from /way #241)
ns.MAP_ID = 241

-- Rares in spawn rotation order (every 10 minutes, 3-hour full cycle)
-- Uses realm time via GetGameTime() - works across all regions
ns.RARES = {
    { name = "Redeye the Skullchewer",         x = 65.2, y = 52.2 },  -- :50
    { name = "T'aavihan the Unbound",          x = 57.6, y = 75.6 },  -- :00
    { name = "Ray of Putrescence",             x = 71.2, y = 29.9 },  -- :10
    { name = "Ix the Bloodfallen",             x = 46.7, y = 25.2 },  -- :20
    { name = "Commander Ix'vaarha",            x = 45.2, y = 48.8 },  -- :30
    { name = "Sharfadi, Bulwark of the Night", x = 41.8, y = 16.5 },  -- :40
    { name = "Ez'Haadosh the Liminality",      x = 65.2, y = 52.2 },  -- :50
    { name = "Berg the Spellfist",             x = 57.6, y = 75.6 },  -- :00
    { name = "Corla, Herald of Twilight",      x = 71.2, y = 29.9 },  -- :10
    { name = "Void Zealot Devinda",            x = 46.7, y = 25.2 },  -- :20
    { name = "Asira Dawnslayer",               x = 45.2, y = 49.2 },  -- :30
    { name = "Archbishop Benedictus",          x = 41.8, y = 16.5 },  -- :40
    { name = "Nedrand the Eyegorger",          x = 65.2, y = 52.2 },  -- :50
    { name = "Executioner Lynthelma",          x = 57.6, y = 75.6 },  -- :00
    { name = "Gustavan, Herald of the End",    x = 71.2, y = 29.9 },  -- :10
    { name = "Voidclaw Hexathor",              x = 46.7, y = 25.2 },  -- :20
    { name = "Mirrorvise",                     x = 45.2, y = 49.2 },  -- :30
    { name = "Saligrum the Observer",          x = 41.8, y = 16.5 },  -- :40
}

ns.TOTAL_RARES = #ns.RARES
ns.SPAWN_INTERVAL_MINUTES = 10
ns.CYCLE_DURATION_MINUTES = ns.TOTAL_RARES * ns.SPAWN_INTERVAL_MINUTES  -- 180 minutes (3 hours)

-- Cycle anchor: Redeye spawns at :50 when (hour % 3 == 2)
-- Using 02:50 as reference anchor (minute 170 of day)
ns.CYCLE_ANCHOR_MINUTE = 170  -- 02:50 in minutes since midnight

-- Bonus rare: Voice of the Eclipse spawns at top of every hour
-- Requires destroying nearby "Disparate Ephemera" to summon
ns.BONUS_RARE = {
    name = "Voice of the Eclipse",
    spawnMinute = 0,  -- Top of every hour
    note = "Destroy Disparate Ephemera to summon"
}
