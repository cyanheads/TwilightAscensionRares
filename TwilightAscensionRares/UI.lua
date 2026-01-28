local addonName, ns = ...

ns.UI = {}

local DISPLAY_COUNT = 4  -- Current + next 3

-- Color palette (Twilight/Void theme)
local COLORS = {
    background = { 0.05, 0.03, 0.09, 0.92 },      -- Deep void purple
    border = { 0.6, 0.3, 0.9, 1 },                 -- Glowing purple
    borderGlow = { 0.5, 0.2, 0.8, 0.4 },           -- Outer glow
    title = { 0.8, 0.6, 1.0 },                     -- Light purple
    gold = { 1.0, 0.82, 0.0 },                     -- Twilight gold accent
    currentRare = { 1.0, 0.9, 0.7 },               -- Warm highlight
    upcomingRare = { 0.55, 0.45, 0.65 },           -- Muted purple
    timerActive = { 0.4, 1.0, 0.4 },               -- Green for current
    timerUpcoming = { 0.6, 0.5, 0.7 },             -- Purple-gray
    divider = { 0.4, 0.2, 0.6, 0.5 },              -- Subtle purple line
}

-- Create the main frame with layered glow effect
local function CreateMainFrame()
    -- Outer glow frame (behind main frame)
    local glowFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    glowFrame:SetSize(296, 176)
    glowFrame:SetPoint("CENTER")
    glowFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    glowFrame:SetBackdropColor(0, 0, 0, 0)
    glowFrame:SetBackdropBorderColor(unpack(COLORS.borderGlow))

    -- Main frame
    local frame = CreateFrame("Frame", "TwilightAscensionRaresFrame", UIParent, "BackdropTemplate")
    frame:SetSize(280, 160)
    frame:SetPoint("CENTER")
    frame:SetFrameLevel(glowFrame:GetFrameLevel() + 1)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(unpack(COLORS.background))
    frame:SetBackdropBorderColor(unpack(COLORS.border))

    -- Store glow reference
    frame.glowFrame = glowFrame

    -- Make draggable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self.glowFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.glowFrame:StopMovingOrSizing()
        local point, _, relPoint, xOfs, yOfs = self:GetPoint()
        TwilightAscensionRaresDB.position = { point = point, relPoint = relPoint, x = xOfs, y = yOfs }
    end)

    -- Keep glow frame synced
    frame:SetScript("OnShow", function(self) self.glowFrame:Show() end)
    frame:SetScript("OnHide", function(self) self.glowFrame:Hide() end)

    -- Title with twilight styling
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cffcc99ffTwilight|r |cff9966ffAscension|r")

    -- Subtle divider line under title
    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetSize(200, 1)
    divider:SetPoint("TOP", title, "BOTTOM", 0, -4)
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

    -- Bonus rare indicator (gold accent)
    frame.bonusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.bonusText:SetPoint("TOP", divider, "BOTTOM", 0, -6)
    frame.bonusText:SetFont(frame.bonusText:GetFont(), 11)

    -- Rare list container
    frame.rareRows = {}
    local listStartY = -48

    for i = 1, DISPLAY_COUNT do
        local row = CreateFrame("Frame", nil, frame)
        row:SetSize(260, 20)
        row:SetPoint("TOPLEFT", 10, listStartY - ((i - 1) * 22))

        -- Row highlight on hover
        row.highlight = row:CreateTexture(nil, "BACKGROUND")
        row.highlight:SetAllPoints()
        row.highlight:SetColorTexture(0.5, 0.3, 0.7, 0)

        -- Status indicator
        row.status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.status:SetPoint("LEFT", 2, 0)
        row.status:SetWidth(14)

        -- Rare name
        row.name = row:CreateFontString(nil, "OVERLAY", "SystemFont_Med1")
        row.name:SetPoint("LEFT", 18, 0)
        row.name:SetWidth(175)
        row.name:SetJustifyH("LEFT")

        -- Time indicator
        row.time = row:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        row.time:SetPoint("RIGHT", -4, 0)

        -- Make row clickable
        row:EnableMouse(true)
        row.rareIndex = i
        row:SetScript("OnMouseUp", function(self)
            local upcoming = ns.Core:GetUpcomingRares(DISPLAY_COUNT)
            local data = upcoming[self.rareIndex]
            if data and data.rare then
                ns.Core:SetWaypoint(data.rare)
            end
        end)
        row:SetScript("OnEnter", function(self)
            self.highlight:SetColorTexture(0.5, 0.3, 0.7, 0.15)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local upcoming = ns.Core:GetUpcomingRares(DISPLAY_COUNT)
            local data = upcoming[self.rareIndex]
            if data and data.rare then
                GameTooltip:AddLine(data.rare.name, COLORS.gold[1], COLORS.gold[2], COLORS.gold[3])
                GameTooltip:AddLine(string.format("Location: %.1f, %.1f", data.rare.x, data.rare.y), 0.8, 0.8, 0.8)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Click to set waypoint", 0.6, 0.6, 0.6)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(self)
            self.highlight:SetColorTexture(0.5, 0.3, 0.7, 0)
            GameTooltip:Hide()
        end)

        frame.rareRows[i] = row
    end

    -- Bottom divider
    local bottomDivider = frame:CreateTexture(nil, "ARTWORK")
    bottomDivider:SetSize(260, 1)
    bottomDivider:SetPoint("BOTTOM", 0, 34)
    bottomDivider:SetColorTexture(unpack(COLORS.divider))

    -- Button container
    local btnFrame = CreateFrame("Frame", nil, frame)
    btnFrame:SetSize(260, 24)
    btnFrame:SetPoint("BOTTOM", 0, 6)

    -- Custom button creator
    local function CreateThemedButton(parent, width, text)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(width, 22)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.15, 0.08, 0.2, 0.9)
        btn:SetBackdropBorderColor(0.5, 0.3, 0.7, 0.8)

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER", 0, 1)
        btn.text:SetText(text)
        btn.text:SetTextColor(0.85, 0.75, 0.95)

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.25, 0.15, 0.35, 0.95)
            self:SetBackdropBorderColor(unpack(COLORS.gold))
            self.text:SetTextColor(unpack(COLORS.gold))
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.08, 0.2, 0.9)
            self:SetBackdropBorderColor(0.5, 0.3, 0.7, 0.8)
            self.text:SetTextColor(0.85, 0.75, 0.95)
        end)

        return btn
    end

    -- Waypoint button
    local wayBtn = CreateThemedButton(btnFrame, 58, "Waypoint")
    wayBtn:SetPoint("LEFT", 2, 0)
    wayBtn:SetScript("OnClick", function()
        local currentIndex = ns.Core:GetCurrentRare()
        local rare = ns.Core:GetRare(currentIndex)
        ns.Core:SetWaypoint(rare)
    end)

    -- Share to General button
    local generalBtn = CreateThemedButton(btnFrame, 65, "Share /1")
    generalBtn:SetPoint("LEFT", wayBtn, "RIGHT", 4, 0)
    generalBtn:SetScript("OnClick", function()
        local currentIndex = ns.Core:GetCurrentRare()
        local rare = ns.Core:GetRare(currentIndex)
        ns.Core:ShareToChat(rare, "GENERAL")
    end)

    -- Share to Raid button
    local raidBtn = CreateThemedButton(btnFrame, 72, "Share Raid")
    raidBtn:SetPoint("LEFT", generalBtn, "RIGHT", 4, 0)
    raidBtn:SetScript("OnClick", function()
        local currentIndex = ns.Core:GetCurrentRare()
        local rare = ns.Core:GetRare(currentIndex)
        ns.Core:ShareToChat(rare, "RAID")
    end)

    return frame
end

-- Update the display
local function UpdateDisplay()
    local frame = ns.UI.frame
    if not frame or not frame:IsShown() then return end

    -- Update bonus rare indicator
    if ns.Core:IsBonusRareTime() then
        local c = COLORS.gold
        frame.bonusText:SetText(string.format("|cff%02x%02x%02xVoice of the Eclipse may spawn!|r",
            c[1] * 255, c[2] * 255, c[3] * 255))
    else
        frame.bonusText:SetText("")
    end

    local upcoming = ns.Core:GetUpcomingRares(DISPLAY_COUNT)

    for i, data in ipairs(upcoming) do
        local row = frame.rareRows[i]
        if row then
            if data.isCurrent then
                -- Current rare - gold/bright styling
                row.status:SetText("|cffffd100>|r")
                row.name:SetTextColor(unpack(COLORS.currentRare))
                row.time:SetTextColor(unpack(COLORS.timerActive))
                row.time:SetText(data.minutesUntil .. "m")
            else
                -- Upcoming - muted purple
                row.status:SetText("|cff6b5b7f-|r")
                row.name:SetTextColor(unpack(COLORS.upcomingRare))
                row.time:SetTextColor(unpack(COLORS.timerUpcoming))
                row.time:SetText("+" .. data.minutesUntil .. "m")
            end
            row.name:SetText(data.rare.name)
        end
    end
end

-- Sync glow frame position with main frame
local function SyncGlowPosition()
    local frame = ns.UI.frame
    if frame and frame.glowFrame then
        frame.glowFrame:ClearAllPoints()
        frame.glowFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
    end
end

-- Check if player is in Twilight Highlands
local function IsInTwilightHighlands()
    local mapID = C_Map.GetBestMapForUnit("player")
    return mapID == ns.MAP_ID
end

-- Zone change handler
local function OnZoneChanged()
    if not ns.UI.frame then return end

    if IsInTwilightHighlands() and not TwilightAscensionRaresDB.hidden then
        ns.UI.frame:Show()
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
        SyncGlowPosition()
    end

    if TwilightAscensionRaresDB.hidden then
        ns.UI.frame:Hide()
    end

    -- Update timer
    local elapsed = 0
    ns.UI.frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= 1 then
            elapsed = 0
            UpdateDisplay()
        end
    end)

    UpdateDisplay()
    print("|cff9966ff[Twilight Ascension Rares]|r Loaded! Use |cffffd100/ta|r for commands.")
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        Initialize()
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        OnZoneChanged()
    end
end)
