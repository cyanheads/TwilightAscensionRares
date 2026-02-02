local addonName, ns = ...

ns.UI = {}

local DISPLAY_COUNT = 4  -- Current + next 3

-- Achievement indicator helper: adds a clickable "!" to a row
local function AddAchievementIndicator(row)
    local btn = CreateFrame("Button", nil, row)
    btn:SetSize(12, 16)
    btn:SetPoint("LEFT", 2, 0)

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetAllPoints()
    btn.text:SetText("|cffffd100!|r")

    btn:SetScript("OnClick", function()
        ns.Core:OpenAchievement()
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Not yet defeated — click to view achievement", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    btn:Hide()
    row.achieveBtn = btn
    return btn
end

-- Color palette (Twilight/Void theme)
local COLORS = {
    background = { 0.05, 0.03, 0.09, 0.92 },      -- Deep void purple
    border = { 0.6, 0.3, 0.9, 1 },                 -- Glowing purple
    borderGlow = { 0.5, 0.2, 0.8, 0.4 },           -- Outer glow
    title = { 0.8, 0.6, 1.0 },                     -- Light purple
    gold = { 1.0, 0.82, 0.0 },                     -- Twilight gold accent
    currentRare = { 1.0, 0.9, 0.7 },               -- Warm highlight
    upcomingRare = { 0.55, 0.45, 0.65 },           -- Muted purple
    timerActive = { 0.4, 1.0, 0.4 },               -- Green for next
    timerUpcoming = { 0.6, 0.5, 0.7 },             -- Purple-gray
    divider = { 0.4, 0.2, 0.6, 0.5 },              -- Subtle purple line
}

-- Create mini button for inline use (using UIPanelButtonTemplate for proper hardware events)
local function CreateMiniButton(parent, text, tooltip)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(22, 20)
    btn:SetText(text)
    btn:GetFontString():SetFont(GameFontNormalSmall:GetFont())

    -- Restyle to match our theme
    btn:SetNormalFontObject(GameFontNormalSmall)
    btn:SetHighlightFontObject(GameFontHighlightSmall)

    btn.tooltipText = tooltip

    btn:SetScript("OnEnter", function(self)
        if self.tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(self.tooltipText, 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return btn
end

-- Create the main frame with layered glow effect
local function CreateMainFrame()
    -- Main frame (wider to accommodate inline buttons)
    local frame = CreateFrame("Frame", "TwilightAscensionRaresFrame", UIParent, "BackdropTemplate")
    frame:SetSize(320, 152)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(unpack(COLORS.background))
    frame:SetBackdropBorderColor(unpack(COLORS.border))

    -- Outer glow frame (parented to main frame so it moves with it)
    local glowFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    glowFrame:SetSize(336, 168)
    glowFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
    glowFrame:SetFrameLevel(frame:GetFrameLevel() - 1)
    glowFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    glowFrame:SetBackdropColor(0, 0, 0, 0)
    glowFrame:SetBackdropBorderColor(unpack(COLORS.borderGlow))

    frame.glowFrame = glowFrame

    -- Make draggable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, xOfs, yOfs = self:GetPoint()
        TwilightAscensionRaresDB.position = { point = point, relPoint = relPoint, x = xOfs, y = yOfs }
    end)

    -- Title with twilight styling
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    local fontFile, _, fontFlags = title:GetFont()
    title:SetFont(fontFile, 14, fontFlags)
    title:SetPoint("TOP", 0, -8)
    title:SetText("|cffcc99ffTwilight|r|cff9966ffAscension|r|cffcc99ffRares|r")

    -- Subtle divider line under title
    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetSize(240, 1)
    divider:SetPoint("TOP", title, "BOTTOM", 0, -3)
    divider:SetColorTexture(unpack(COLORS.divider))

    -- Close button (custom styled)
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", -6, -6)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
    closeBtn:GetNormalTexture():SetVertexColor(0.7, 0.5, 0.9)
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-StopButton")
    closeBtn:GetHighlightTexture():SetVertexColor(1, 0.8, 1)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
        TwilightAscensionRaresDB.hidden = true
    end)

    -- Rare list container
    frame.rareRows = {}
    local listStartY = -32
    local rowHeight = 24

    for i = 1, DISPLAY_COUNT do
        local row = CreateFrame("Frame", nil, frame)
        row:SetSize(300, rowHeight)
        row:SetPoint("TOPLEFT", 10, listStartY - ((i - 1) * (rowHeight + 1)))

        -- Row highlight on hover
        row.highlight = row:CreateTexture(nil, "BACKGROUND")
        row.highlight:SetAllPoints()
        row.highlight:SetColorTexture(0.5, 0.3, 0.7, 0)

        -- Achievement indicator (clickable !)
        AddAchievementIndicator(row)

        -- Rare name
        row.name = row:CreateFontString(nil, "OVERLAY", "SystemFont_Med1")
        row.name:SetPoint("LEFT", 16, 0)
        row.name:SetWidth(150)
        row.name:SetJustifyH("LEFT")

        -- Time indicator
        row.time = row:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        row.time:SetPoint("LEFT", 168, 0)
        row.time:SetWidth(55)
        row.time:SetJustifyH("LEFT")

        -- Mini buttons (right side)
        local btnRaid = CreateMiniButton(row, "R", "Share to Raid/Party")
        btnRaid:SetPoint("RIGHT", -2, 0)
        row.btnRaid = btnRaid

        local btnGeneral = CreateMiniButton(row, "G", "Share to General")
        btnGeneral:SetPoint("RIGHT", btnRaid, "LEFT", -2, 0)
        row.btnGeneral = btnGeneral

        local btnWay = CreateMiniButton(row, "W", "Set Waypoint")
        btnWay:SetPoint("RIGHT", btnGeneral, "LEFT", -2, 0)
        row.btnWay = btnWay

        -- Store row index for button callbacks
        row.rareIndex = i

        -- Button click handlers (will be set up in UpdateDisplay with correct data)
        row.btnWay:SetScript("OnClick", function()
            local upcoming = ns.Core:GetUpcomingRares(DISPLAY_COUNT)
            local data = upcoming[row.rareIndex]
            if data and data.rare then
                ns.Core:SetWaypoint(data.rare)
            end
        end)

        row.btnGeneral:SetScript("OnClick", function()
            local upcoming = ns.Core:GetUpcomingRares(DISPLAY_COUNT)
            local data = upcoming[row.rareIndex]
            if data and data.rare then
                ns.Core:ShareToChat(data.rare, "GENERAL", data.isCurrent, data.minutesUntil)
            end
        end)

        row.btnRaid:SetScript("OnClick", function()
            local upcoming = ns.Core:GetUpcomingRares(DISPLAY_COUNT)
            local data = upcoming[row.rareIndex]
            if data and data.rare then
                ns.Core:ShareToChat(data.rare, "RAID", data.isCurrent, data.minutesUntil)
            end
        end)

        -- Row hover (just for visual feedback, no tooltip needed now)
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            self.highlight:SetColorTexture(0.5, 0.3, 0.7, 0.1)
        end)
        row:SetScript("OnLeave", function(self)
            self.highlight:SetColorTexture(0.5, 0.3, 0.7, 0)
        end)

        frame.rareRows[i] = row
    end

    -- Expand/Collapse divider
    local REMAINING_COUNT = ns.TOTAL_RARES - DISPLAY_COUNT
    local toggleY = listStartY - (DISPLAY_COUNT * (rowHeight + 1)) - 2
    local toggleBtn = CreateFrame("Button", nil, frame)
    toggleBtn:SetSize(300, 16)
    toggleBtn:SetPoint("TOPLEFT", 10, toggleY)
    toggleBtn:EnableMouse(true)

    -- Left line
    local leftLine = toggleBtn:CreateTexture(nil, "ARTWORK")
    leftLine:SetSize(90, 1)
    leftLine:SetPoint("LEFT", 0, 0)
    leftLine:SetColorTexture(unpack(COLORS.divider))

    -- Label
    toggleBtn.label = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toggleBtn.label:SetPoint("CENTER", 0, 0)
    toggleBtn.label:SetText("|cff6b5b7fExpand|r")

    -- Right line
    local rightLine = toggleBtn:CreateTexture(nil, "ARTWORK")
    rightLine:SetSize(90, 1)
    rightLine:SetPoint("RIGHT", 0, 0)
    rightLine:SetColorTexture(unpack(COLORS.divider))

    toggleBtn:SetScript("OnEnter", function(self)
        self.label:SetText("|cffcc99ffExpand|r")
    end)
    toggleBtn:SetScript("OnLeave", function(self)
        if not ns.UI.allRaresExpanded then
            self.label:SetText("|cff6b5b7fExpand|r")
        else
            self.label:SetText("|cff6b5b7fCollapse|r")
        end
    end)

    frame.toggleBtn = toggleBtn

    -- Expanded rows container (hidden by default)
    local expandContainer = CreateFrame("Frame", nil, frame)
    local expandStartY = toggleY - 18
    expandContainer:SetPoint("TOPLEFT", 10, expandStartY)
    expandContainer:SetSize(300, REMAINING_COUNT * (rowHeight + 1))
    expandContainer:Hide()

    frame.expandContainer = expandContainer
    frame.allRareRows = {}

    for i = 1, REMAINING_COUNT do
        local row = CreateFrame("Frame", nil, expandContainer)
        row:SetSize(300, rowHeight)
        row:SetPoint("TOPLEFT", 0, -((i - 1) * (rowHeight + 1)))

        row.highlight = row:CreateTexture(nil, "BACKGROUND")
        row.highlight:SetAllPoints()
        row.highlight:SetColorTexture(0.5, 0.3, 0.7, 0)

        AddAchievementIndicator(row)

        row.name = row:CreateFontString(nil, "OVERLAY", "SystemFont_Med1")
        row.name:SetPoint("LEFT", 16, 0)
        row.name:SetWidth(150)
        row.name:SetJustifyH("LEFT")

        row.time = row:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        row.time:SetPoint("LEFT", 168, 0)
        row.time:SetWidth(55)
        row.time:SetJustifyH("LEFT")

        local btnRaid = CreateMiniButton(row, "R", "Share to Raid/Party")
        btnRaid:SetPoint("RIGHT", -2, 0)
        row.btnRaid = btnRaid

        local btnGeneral = CreateMiniButton(row, "G", "Share to General")
        btnGeneral:SetPoint("RIGHT", btnRaid, "LEFT", -2, 0)
        row.btnGeneral = btnGeneral

        local btnWay = CreateMiniButton(row, "W", "Set Waypoint")
        btnWay:SetPoint("RIGHT", btnGeneral, "LEFT", -2, 0)
        row.btnWay = btnWay

        -- This row maps to upcoming index DISPLAY_COUNT + i
        row.upcomingOffset = DISPLAY_COUNT + i

        row.btnWay:SetScript("OnClick", function()
            local upcoming = ns.Core:GetUpcomingRares(ns.TOTAL_RARES)
            local data = upcoming[row.upcomingOffset]
            if data and data.rare then
                ns.Core:SetWaypoint(data.rare)
            end
        end)

        row.btnGeneral:SetScript("OnClick", function()
            local upcoming = ns.Core:GetUpcomingRares(ns.TOTAL_RARES)
            local data = upcoming[row.upcomingOffset]
            if data and data.rare then
                ns.Core:ShareToChat(data.rare, "GENERAL", data.isCurrent, data.minutesUntil)
            end
        end)

        row.btnRaid:SetScript("OnClick", function()
            local upcoming = ns.Core:GetUpcomingRares(ns.TOTAL_RARES)
            local data = upcoming[row.upcomingOffset]
            if data and data.rare then
                ns.Core:ShareToChat(data.rare, "RAID", data.isCurrent, data.minutesUntil)
            end
        end)

        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            self.highlight:SetColorTexture(0.5, 0.3, 0.7, 0.1)
        end)
        row:SetScript("OnLeave", function(self)
            self.highlight:SetColorTexture(0.5, 0.3, 0.7, 0)
        end)

        frame.allRareRows[i] = row
    end

    -- Collapsed: fits the 4 rows + divider toggle
    local COLLAPSED_HEIGHT = 152
    local EXPANDED_HEIGHT = COLLAPSED_HEIGHT + (REMAINING_COUNT * (rowHeight + 1)) + 4

    local function SetExpanded(expanded)
        ns.UI.allRaresExpanded = expanded
        if expanded then
            toggleBtn.label:SetText("|cff6b5b7fCollapse|r")
            expandContainer:Show()
            frame:SetSize(320, EXPANDED_HEIGHT)
            frame.glowFrame:SetSize(336, EXPANDED_HEIGHT + 16)
        else
            toggleBtn.label:SetText("|cff6b5b7fExpand|r")
            expandContainer:Hide()
            frame:SetSize(320, COLLAPSED_HEIGHT)
            frame.glowFrame:SetSize(336, COLLAPSED_HEIGHT + 16)
        end
    end

    toggleBtn:SetScript("OnClick", function()
        SetExpanded(not ns.UI.allRaresExpanded)
    end)

    frame.SetExpanded = SetExpanded

    return frame
end

-- Update the display
local function UpdateDisplay()
    local frame = ns.UI.frame
    if not frame or not frame:IsShown() then return end

    local upcoming = ns.Core:GetUpcomingRares(DISPLAY_COUNT)

    for i, data in ipairs(upcoming) do
        local row = frame.rareRows[i]
        if row then
            if data.isCurrent then
                -- Current rare - muted, it's already up
                row.name:SetTextColor(unpack(COLORS.upcomingRare))
                row.time:SetTextColor(unpack(COLORS.gold))
                row.time:SetText("Now")
            elseif i == 2 then
                -- Next rare - highlighted green, this is what we're waiting for
                row.name:SetTextColor(unpack(COLORS.currentRare))
                row.time:SetTextColor(unpack(COLORS.timerActive))
                row.time:SetText("in " .. data.minutesUntil .. "m")
            else
                -- Further upcoming - muted purple
                row.name:SetTextColor(unpack(COLORS.upcomingRare))
                row.time:SetTextColor(unpack(COLORS.timerUpcoming))
                row.time:SetText("+" .. data.minutesUntil .. "m")
            end
            row.name:SetText(data.rare.name)

            -- Achievement indicator + name position
            local needsKill = ns.achievementNeedsKill and ns.achievementNeedsKill[data.rare.name]
            if needsKill then
                row.achieveBtn:Show()
                row.name:SetPoint("LEFT", 16, 0)
            else
                row.achieveBtn:Hide()
                row.name:SetPoint("LEFT", 2, 0)
            end
        end
    end

    -- Update expanded rows (remaining rares after the top 4)
    if ns.UI.allRaresExpanded and frame.allRareRows then
        local allUpcoming = ns.Core:GetUpcomingRares(ns.TOTAL_RARES)
        for i = 1, ns.TOTAL_RARES - DISPLAY_COUNT do
            local row = frame.allRareRows[i]
            local data = allUpcoming[DISPLAY_COUNT + i]
            if row and data then
                row.name:SetTextColor(unpack(COLORS.upcomingRare))
                row.time:SetTextColor(unpack(COLORS.timerUpcoming))
                row.time:SetText("+" .. data.minutesUntil .. "m")
                row.name:SetText(data.rare.name)

                local needsKill = ns.achievementNeedsKill and ns.achievementNeedsKill[data.rare.name]
                if needsKill then
                    row.achieveBtn:Show()
                    row.name:SetPoint("LEFT", 16, 0)
                else
                    row.achieveBtn:Hide()
                    row.name:SetPoint("LEFT", 2, 0)
                end
            end
        end
    end
end

-- Check if player is in Twilight Highlands
local function IsInTwilightHighlands()
    local mapID = C_Map.GetBestMapForUnit("player")
    return mapID == ns.MAP_ID
end

-- Zone change handler - show in Twilight Highlands, hide elsewhere
local function OnZoneChanged()
    if not ns.UI.frame then return end

    if IsInTwilightHighlands() then
        if not TwilightAscensionRaresDB.hidden then
            ns.UI.frame:Show()
        end
    else
        ns.UI.frame:Hide()
    end
end

-- Initialize
local function Initialize()
    TwilightAscensionRaresDB = TwilightAscensionRaresDB or {}

    ns.UI.frame = CreateMainFrame()

    -- Restore position
    if TwilightAscensionRaresDB.position then
        local pos = TwilightAscensionRaresDB.position
        ns.UI.frame:ClearAllPoints()
        ns.UI.frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    end

    -- Start hidden - OnZoneChanged will show if in Twilight Highlands
    ns.UI.frame:Hide()

    -- Update timer (display every 1s, achievement poll every 30s as fallback)
    local elapsed = 0
    local achieveElapsed = 0
    ns.UI.frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        achieveElapsed = achieveElapsed + delta
        if elapsed >= 1 then
            elapsed = 0
            UpdateDisplay()
        end
        if achieveElapsed >= 30 then
            achieveElapsed = 0
            ns.Core:RefreshAchievementProgress()
        end
    end)

    ns.Core:RefreshAchievementProgress()
    UpdateDisplay()
    print("|cff9966ff[Twilight Ascension Rares]|r Loaded! Use |cffffd100/ta|r for commands.")
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CRITERIA_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        Initialize()
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        OnZoneChanged()
    elseif event == "CRITERIA_UPDATE" then
        ns.Core:RefreshAchievementProgress()
    end
end)
