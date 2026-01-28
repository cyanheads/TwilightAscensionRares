local addonName, ns = ...

-- Localize frequently used functions
local GetGameTime = GetGameTime
local SendChatMessage = SendChatMessage
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local floor = math.floor

ns.Core = {}

-- Get current realm time as minutes since midnight
function ns.Core:GetRealmMinutes()
    local hour, minute = GetGameTime()
    return hour * 60 + minute
end

-- Calculate the current rare index (1-based) and time remaining in minutes
function ns.Core:GetCurrentRare()
    local minuteOfDay = self:GetRealmMinutes()

    -- Calculate position in 3-hour cycle
    -- Anchor at 02:50 (minute 170) when Redeye spawns
    local minutesSinceAnchor = minuteOfDay - ns.CYCLE_ANCHOR_MINUTE
    if minutesSinceAnchor < 0 then
        minutesSinceAnchor = minutesSinceAnchor + 1440  -- Wrap around midnight
    end

    local cycleMinute = minutesSinceAnchor % ns.CYCLE_DURATION_MINUTES
    local currentIndex = floor(cycleMinute / ns.SPAWN_INTERVAL_MINUTES) + 1
    local minuteIntoCurrentSpawn = cycleMinute % ns.SPAWN_INTERVAL_MINUTES
    local minutesRemaining = ns.SPAWN_INTERVAL_MINUTES - minuteIntoCurrentSpawn

    return currentIndex, minutesRemaining, minuteIntoCurrentSpawn
end

-- Check if bonus rare (Voice of the Eclipse) can spawn this hour
function ns.Core:IsBonusRareTime()
    local hour, minute = GetGameTime()
    -- Bonus rare spawns at top of every hour (minute 0-9)
    return minute < 10
end

-- Get rare data by index (wraps around)
function ns.Core:GetRare(index)
    local wrappedIndex = ((index - 1) % ns.TOTAL_RARES) + 1
    return ns.RARES[wrappedIndex], wrappedIndex
end

-- Get the next N rares starting from current
function ns.Core:GetUpcomingRares(count)
    local currentIndex, minutesRemaining = self:GetCurrentRare()
    local upcoming = {}

    for i = 0, count - 1 do
        local rare, index = self:GetRare(currentIndex + i)
        local minutesUntil
        if i == 0 then
            minutesUntil = minutesRemaining
        else
            minutesUntil = minutesRemaining + (i * ns.SPAWN_INTERVAL_MINUTES)
        end

        table.insert(upcoming, {
            rare = rare,
            index = index,
            minutesUntil = minutesUntil,
            isCurrent = (i == 0)
        })
    end

    return upcoming
end

-- Format time as M:SS
function ns.Core:FormatTime(minutes)
    local mins = floor(minutes)
    local secs = floor((minutes - mins) * 60)
    return string.format("%d:%02d", mins, secs)
end

-- Format time as MM:SS from seconds
function ns.Core:FormatTimeSeconds(seconds)
    local mins = floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%d:%02d", mins, secs)
end

-- Create TomTom waypoint if TomTom is available
function ns.Core:SetWaypoint(rare)
    if TomTom then
        -- Clear previous waypoints from this addon
        if ns.currentWaypoint then
            TomTom:RemoveWaypoint(ns.currentWaypoint)
        end
        ns.currentWaypoint = TomTom:AddWaypoint(ns.MAP_ID, rare.x / 100, rare.y / 100, {
            title = rare.name,
            persistent = false,
            minimap = true,
            world = true,
        })
        print("|cff00ff00[Twilight Ascension Rares]|r Waypoint set for " .. rare.name)
    else
        -- Fallback: print /way command for manual use
        print(string.format("|cff00ff00[Twilight Ascension Rares]|r /way #%d %.1f, %.1f %s",
            ns.MAP_ID, rare.x, rare.y, rare.name))
    end
end

-- Create a clickable map pin link for chat
function ns.Core:GetMapPinLink(rare)
    -- Format: |cffffff00|Hworldmap:mapID:x:y|h[Location]|h|r
    local x = rare.x / 100
    local y = rare.y / 100
    return string.format("|cffffff00|Hworldmap:%d:%.4f:%.4f|h[%.1f, %.1f]|h|r",
        ns.MAP_ID, x, y, rare.x, rare.y)
end

-- Share rare to chat
function ns.Core:ShareToChat(rare, channel)
    local mapLink = self:GetMapPinLink(rare)
    local message = string.format("%s is up! %s", rare.name, mapLink)

    if channel == "RAID" then
        if IsInRaid() then
            SendChatMessage(message, "RAID")
        elseif IsInGroup() then
            SendChatMessage(message, "PARTY")
        else
            print("|cffff0000[Twilight Ascension Rares]|r You're not in a group!")
        end
    elseif channel == "GENERAL" then
        -- Channel 1 is typically General
        SendChatMessage(message, "CHANNEL", nil, 1)
    end
end

-- Slash commands
SLASH_TWILIGHTASCENSION1 = "/ta"
SLASH_TWILIGHTASCENSION2 = "/twilight"
SlashCmdList["TWILIGHTASCENSION"] = function(msg)
    local cmd = msg:lower():match("^(%S+)") or ""

    if cmd == "show" then
        if ns.UI and ns.UI.frame then
            ns.UI.frame:Show()
            TwilightAscensionRaresDB.hidden = false
        end
    elseif cmd == "hide" then
        if ns.UI and ns.UI.frame then
            ns.UI.frame:Hide()
            TwilightAscensionRaresDB.hidden = true
        end
    elseif cmd == "way" or cmd == "waypoint" then
        local currentIndex = ns.Core:GetCurrentRare()
        local rare = ns.Core:GetRare(currentIndex)
        ns.Core:SetWaypoint(rare)
    elseif cmd == "debug" then
        local hour, minute = GetGameTime()
        local currentIndex, minutesRemaining = ns.Core:GetCurrentRare()
        local rare = ns.Core:GetRare(currentIndex)
        print("|cff00ff00[Twilight Ascension Rares]|r Debug info:")
        print(string.format("  Realm time: %02d:%02d", hour, minute))
        print(string.format("  Current rare: %s (index %d)", rare.name, currentIndex))
        print(string.format("  Time remaining: %d minutes", minutesRemaining))
        if ns.Core:IsBonusRareTime() then
            print("  Bonus rare (Voice of the Eclipse) can spawn!")
        end
    else
        print("|cff00ff00[Twilight Ascension Rares]|r Commands:")
        print("  /ta show - Show the tracker window")
        print("  /ta hide - Hide the tracker window")
        print("  /ta way - Set waypoint for current rare")
        print("  /ta debug - Show debug timing info")
    end
end
