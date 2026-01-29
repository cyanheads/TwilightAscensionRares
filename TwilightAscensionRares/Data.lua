local addonName, ns = ...

-- Map ID for Twilight Highlands (confirmed from /way #241)
ns.MAP_ID = 241

-- Rares in spawn rotation order (every 5 minutes, 90-minute full cycle)
-- Uses realm time via GetGameTime() - works across all regions
ns.RARES = {
    { name = "Redeye the Skullchewer",         x = 65.2, y = 52.2 },
    { name = "T'aavihan the Unbound",          x = 57.6, y = 75.6 },
    { name = "Ray of Putrescence",             x = 71.0, y = 30.6 },
    { name = "Ix the Bloodfallen",             x = 46.7, y = 25.2 },
    { name = "Commander Ix'vaarha",            x = 45.2, y = 48.8 },
    { name = "Sharfadi, Bulwark of the Night", x = 41.8, y = 16.5 },
    { name = "Ez'Haadosh the Liminality",      x = 65.2, y = 52.2 },
    { name = "Berg the Spellfist",             x = 57.6, y = 75.6 },
    { name = "Corla, Herald of Twilight",      x = 71.2, y = 29.9 },
    { name = "Void Zealot Devinda",            x = 46.7, y = 25.2 },
    { name = "Asira Dawnslayer",               x = 45.2, y = 49.2 },
    { name = "Archbishop Benedictus",          x = 41.8, y = 16.5 },
    { name = "Nedrand the Eyegorger",          x = 65.2, y = 52.2 },
    { name = "Executioner Lynthelma",          x = 57.6, y = 75.6 },
    { name = "Gustavan, Herald of the End",    x = 71.2, y = 29.9 },
    { name = "Voidclaw Hexathor",              x = 46.7, y = 25.2 },
    { name = "Mirrorvise",                     x = 45.2, y = 49.2 },
    { name = "Saligrum the Observer",          x = 41.8, y = 16.5 },
}

ns.TOTAL_RARES = #ns.RARES
ns.SPAWN_INTERVAL_MINUTES = 5
ns.CYCLE_DURATION_MINUTES = ns.TOTAL_RARES * ns.SPAWN_INTERVAL_MINUTES  -- 90 minutes (1.5 hours)

-- Cycle anchor: minute of day when Redeye spawns (region-specific)
-- GetCurrentRegion(): 1=US, 2=KR, 3=EU, 4=TW, 5=CN
ns.CYCLE_ANCHORS = {
    [1] = 25,   -- NA: Redeye at 00:25 realm time
    [3] = 85,   -- EU: Redeye at 01:25 realm time
}
ns.CYCLE_ANCHORS[2] = ns.CYCLE_ANCHORS[1]  -- KR: assume NA timing
ns.CYCLE_ANCHORS[4] = ns.CYCLE_ANCHORS[1]  -- TW: assume NA timing
ns.CYCLE_ANCHORS[5] = ns.CYCLE_ANCHORS[1]  -- CN: assume NA timing

ns.CYCLE_ANCHOR_MINUTE = ns.CYCLE_ANCHORS[GetCurrentRegion()] or 25

-- Bonus rare: Voice of the Eclipse spawns at top of every hour
-- Requires destroying nearby "Disparate Ephemera" to summon
ns.BONUS_RARE = {
    name = "Voice of the Eclipse",
    spawnMinute = 0,  -- Top of every hour
    note = "Destroy Disparate Ephemera to summon"
}
