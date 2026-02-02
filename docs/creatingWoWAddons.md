# Creating and publishing World of Warcraft addons in 2025-2026

The Midnight expansion (Patch 12.0, pre-patch January 20, 2026) introduces the most disruptive addon API changes in WoW's history—a "Secret Values" system that fundamentally restricts what addons can do with combat data. Addon developers must now adapt to an environment where health values, unit names, and combat log data become opaque during fights, displayable but not processable by addon code. This guide covers everything from basic addon structure through these critical Patch 12 changes to CurseForge publishing automation.

## Addon structure fundamentals

Every WoW addon lives in `Interface/AddOns` within the game installation, with separate paths for each game variant:

| Game Version | Path                                                |
| ------------ | --------------------------------------------------- |
| Retail       | `World of Warcraft/_retail_/Interface/AddOns/`      |
| Classic      | `World of Warcraft/_classic_/Interface/AddOns/`     |
| Classic Era  | `World of Warcraft/_classic_era_/Interface/AddOns/` |

**The critical rule**: Your addon folder name must exactly match your `.toc` filename (case-sensitive). A typical addon structure looks like:

```
MyAddon/
├── MyAddon.toc              # Required manifest
├── MyAddon.lua              # Main code
├── MyAddon_Mainline.toc     # Retail-specific TOC (optional)
├── MyAddon_Vanilla.toc      # Classic Era TOC (optional)
├── Libs/                    # Embedded libraries
├── Locales/                 # Translation files
└── Media/                   # Textures, sounds
```

The TOC file acts as your addon's manifest, declaring metadata and listing files to load in order:

```toc
## Interface: 120000
## Title: My Addon
## Notes: Description shown on hover
## Author: YourName
## Version: @project-version@
## SavedVariables: MyAddonDB
## SavedVariablesPerCharacter: MyAddonCharDB
## X-Curse-Project-ID: 123456

Libs/LibStub/LibStub.lua
Core.lua
UI.lua
```

Key TOC fields include `Interface` (required—the client version number), `SavedVariables` for persistent data, and `Dependencies` for load-order requirements. Modern addons added since Patch 10.1 can use `IconTexture` for minimap icons and `AddonCompartmentFunc` for the addon dropdown menu. Interface version **120000** corresponds to Patch 12.0.0 (Midnight pre-patch).

## The Lua-WoW relationship

WoW addons share a single global Lua environment, making namespace pollution a constant hazard. Always use `local` variables to prevent conflicts:

```lua
-- Access the shared addon namespace via vararg
local addonName, ns = ...
ns.MyFunction = function() print("Safe namespace usage") end

-- Localize frequently-used globals for performance
local CreateFrame, UnitHealth = CreateFrame, UnitHealth
```

A minimal working addon needs just two files—the TOC and a Lua file:

```lua
-- MyAddon.lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == "MyAddon" then
        print("MyAddon loaded!")
        MyAddonDB = MyAddonDB or { loadCount = 0 }
        MyAddonDB.loadCount = MyAddonDB.loadCount + 1
    end
end)
```

## Development workflow and debugging

The `/reload` command (or `/reloadui`) reloads all addons without restarting the client—your primary iteration tool. Bind it to a hotkey for rapid testing. Changes to Lua files take effect immediately on reload, though TOC file changes require a full client restart.

### Essential debugging commands

| Command                   | Purpose                                        |
| ------------------------- | ---------------------------------------------- |
| `/dump <expression>`      | Inspect any Lua value, including nested tables |
| `/etrace`                 | Real-time event tracer showing all game events |
| `/fstack`                 | Shows all UI frames under your cursor          |
| `/tinspect <table>`       | Interactive table browser                      |
| `/console scriptErrors 1` | Enable built-in Lua error display              |

**BugSack and BugGrabber** are mandatory development addons. BugGrabber silently captures all Lua errors with full stack traces; BugSack provides a visual interface to review them. **DevTool** (or ViragDevTool) offers advanced debugging with table inspection, event monitoring, and function call logging.

For editor setup, **VS Code** with the **WoW API** extension by Ketho provides IntelliSense for all WoW APIs, auto-activating when it detects TOC files. The **WoW Bundle** extension adds TOC syntax highlighting and combat lockdown awareness.

### The taint system

Addon code is inherently "tainted" (untrusted), while Blizzard UI code is "secure." Protected functions like `CastSpellByName` or `TargetUnit` refuse execution from tainted code paths, especially during combat. Always check `InCombatLockdown()` before modifying secure frames, and use `hooksecurefunc()` for safe post-hooks that don't spread taint.

## Patch 12 API changes reshape addon development

Patch 12.0.0 (Midnight pre-patch, January 20, 2026) introduces what the community calls the "Addon Apocalypse"—a philosophical shift where **addons should no longer offer competitive advantages in WoW combat**. The centerpiece is the Secret Values system.

### Secret Values fundamentally change combat data access

Combat-related information now returns as "secret values" that addons can **display but cannot process**. With secret values, your code cannot:

- Perform arithmetic operations (`health - damage`)
- Concatenate strings (`name .. " - " .. health`)
- Use values in conditionals (`if health < 20 then`)
- Inspect or "know" the actual underlying values

What addons **can** do with secrets: store them in variables, pass them to other functions, and pass them to approved Blizzard APIs like `StatusBar:SetValue()` for display.

```lua
-- New testing functions for secrets
issecretvalue(value)       -- Returns true if value is secret
canaccesssecrets()         -- Returns false if execution is tainted
canaccessvalue(value)      -- Returns true if value is accessible
```

APIs like `UnitHealth()` and `UnitName()` now conditionally return secret values during combat. The key migration pattern: instead of reading health values and doing math, you pass them directly to status bars that handle display natively.

### New objects for displaying secret data

Blizzard introduced several new object types for working with secrets:

**Duration Objects** handle secret time values for cast bars and cooldowns:

```lua
local duration = C_DurationUtil.CreateDuration()
StatusBar:SetTimerDuration(duration, direction)  -- Auto-updating timer bar
```

**Curve and ColorCurve Objects** map secret values to visual outputs:

```lua
local colorCurve = C_CurveUtil.CreateColorCurve()
-- Use for health-based coloring without knowing the actual health value
```

**UnitHealPredictionCalculator** replaces direct heal prediction math:

```lua
local calculator = CreateUnitHealPredictionCalculator()
UnitGetDetailedHealPrediction(unit, healer, calculator)
local incomingHeals = calculator:GetIncomingHeals()
```

### Major functionality removed

`COMBAT_LOG_EVENT_UNFILTERED` is **heavily restricted in instanced endgame content**—the core event that powered damage meters, boss mods, and combat analysis now returns secret values in raids and dungeons. Combat log messages are converted to KStrings that prevent parsing. Chat messages in instances become secret values, breaking addon communication channels for loot councils and break timers. Note: Blizzard eased some of these restrictions after community feedback, so the exact limitations continue to evolve.

**WeakAuras has discontinued retail support** for Patch 12.0+, though it remains available in Classic. ElvUI initially paused development but announced in December 2025 they would resume work for Midnight after Blizzard relaxed some API restrictions. Boss mods (DBM, BigWigs) are adapting to timer-based displays using Duration Objects, while Blizzard adds native boss warnings to the base UI.

### Current interface versions

| Patch      | Interface Version | Date                            |
| ---------- | ----------------- | ------------------------------- |
| 11.1.0     | 110100            | Feb 25, 2025                    |
| 11.2.0     | 110200            | Aug 2025                        |
| **12.0.0** | **120000**        | Pre-patch January 20, 2026      |
| 12.0.1     | 120001            | March 2, 2026 (Midnight launch) |

## Key APIs every addon developer needs

### Creating and positioning UI elements

```lua
-- Create a frame with backdrop
local frame = CreateFrame("Frame", "MyFrame", UIParent, "BackdropTemplate")
frame:SetSize(200, 100)
frame:SetPoint("CENTER")  -- Anchor to parent's center
frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

-- Create text
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER")
text:SetText("Hello World")

-- Make draggable
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
```

Frame strata controls layering: `BACKGROUND`, `LOW`, `MEDIUM`, `HIGH`, `DIALOG`, `FULLSCREEN`, `FULLSCREEN_DIALOG`, `TOOLTIP` (lowest to highest).

### Event-driven architecture

WoW's interface is entirely event-driven. The dispatch table pattern keeps handlers organized:

```lua
local frame = CreateFrame("Frame")
local events = {}

function events:ADDON_LOADED(addonName)
    if addonName == "MyAddon" then
        MyAddonDB = MyAddonDB or {}
        print("MyAddon initialized")
    end
end

function events:PLAYER_ENTERING_WORLD(isInitialLogin, isReload)
    print("Entered world")
end

frame:SetScript("OnEvent", function(self, event, ...)
    if events[event] then events[event](self, ...) end
end)

for event in pairs(events) do
    frame:RegisterEvent(event)
end
```

Critical events include `ADDON_LOADED` (fires after saved variables load), `PLAYER_LOGIN` (character fully loaded, once per session), and `PLAYER_ENTERING_WORLD` (after every loading screen).

### Slash commands and saved variables

```lua
-- Register slash commands
SLASH_MYADDON1 = "/myaddon"
SLASH_MYADDON2 = "/ma"
SlashCmdList["MYADDON"] = function(msg)
    local cmd = msg:lower():match("^(%S+)") or ""
    if cmd == "show" then MyAddonFrame:Show()
    elseif cmd == "hide" then MyAddonFrame:Hide()
    else print("Usage: /myaddon [show|hide]") end
end
```

Saved variables declared in the TOC persist between sessions. They're `nil` until `ADDON_LOADED` fires—always initialize with defaults:

```lua
MyAddonDB = MyAddonDB or {}
MyAddonDB.enabled = MyAddonDB.enabled ~= false  -- Default true
```

Only strings, numbers, booleans, and tables can be saved. Functions and userdata silently fail to persist.

### Delayed execution with C_Timer

```lua
-- One-shot delay
C_Timer.After(2.5, function()
    print("2.5 seconds passed")
end)

-- Repeating ticker (returns cancellable handle)
local ticker = C_Timer.NewTicker(1.0, function()
    print("Tick!")
end, 5)  -- Stop after 5 iterations

ticker:Cancel()  -- Cancel early
```

## Publishing on CurseForge with automation

### Project setup

Create your project at [authors.curseforge.com](https://authors.curseforge.com). Note your **Project ID** from the sidebar—you'll need it for your TOC file:

```toc
## X-Curse-Project-ID: 123456
## X-WoWI-ID: 12345
## X-Wago-ID: he54k6bL
```

Generate API tokens for automated uploads at the respective sites' account settings.

### The .pkgmeta configuration file

The `.pkgmeta` file controls how BigWigs Packager builds your release:

```yaml
package-as: MyAddon

externals:
  Libs/LibStub:
    url: https://repos.wowace.com/wow/libstub/trunk
    tag: latest
  Libs/AceAddon-3.0:
    url: https://repos.wowace.com/wow/ace3/trunk/AceAddon-3.0

ignore:
  - README.md
  - .github
  - Tests

enable-nolib-creation: no
```

### GitHub Actions workflow for automated releases

Create `.github/workflows/release.yml`:

```yaml
name: Package and Release

on:
  push:
    tags:
      - "**"

jobs:
  release:
    runs-on: ubuntu-latest
    env:
      CF_API_KEY: ${{ secrets.CF_API_KEY }}
      WOWI_API_TOKEN: ${{ secrets.WOWI_API_TOKEN }}
      WAGO_API_TOKEN: ${{ secrets.WAGO_API_TOKEN }}
      GITHUB_OAUTH: ${{ secrets.GITHUB_TOKEN }}

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0 # Required for changelog generation

      - uses: BigWigsMods/packager@v2
```

Add your API tokens as repository secrets (Settings → Secrets → Actions). The workflow triggers on git tags:

```bash
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0  # Triggers automated build and upload
```

Use `@project-version@` in your TOC's Version field—the packager substitutes the tag name automatically.

## Best practices for maintainable addons

**Code organization**: Use the addon namespace (`local addonName, ns = ...`) rather than polluting globals. Structure larger addons into modules loaded via the TOC file order.

**Multi-version support**: Create separate TOC files for different game versions (`MyAddon_Mainline.toc`, `MyAddon_Vanilla.toc`) or use comma-separated interface versions. The client selects the appropriate TOC automatically.

**Localization**: Integrate with CurseForge's localization system using `@localization@` keywords in your Lua files. Translators can contribute via the web interface without code access, and translations automatically inject during packaging.

**Handle API differences**: Wrap version-specific calls in conditionals checking `WOW_PROJECT_ID` or test for API existence with `if C_NewNamespace then`. For Patch 12, test values with `issecretvalue()` before attempting operations that would fail on secrets.

**Performance**: Cache API lookups at file scope (`local UnitHealth = UnitHealth`). Throttle `OnUpdate` handlers—they fire every frame. Prefer event-driven design over polling, and hide frames that don't need continuous updates.

## Conclusion

The Midnight pre-patch (January 20, 2026) includes the "Twilight Ascension" pre-expansion event alongside the sweeping API changes. Addon development in 2025-2026 requires adapting to Patch 12's Secret Values paradigm—a fundamental shift from "addons can do anything with game data" to "addons can display but not analyze combat information." The silver lining: Blizzard is adding native support for smooth status bars, timer displays, and other features previously requiring addon logic. Focus your development on areas where addons still add value—UI customization, non-combat utilities, and quality-of-life improvements—while leveraging BigWigs Packager and GitHub Actions for effortless multi-platform distribution.
