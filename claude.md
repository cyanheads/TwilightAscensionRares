# Twilight Ascension

A World of Warcraft addon for tracking rare spawns during the Midnight pre-patch "Twilight Ascension" event (January 27 – March 2, 2026).

## Purpose

Helps players complete the **Two Minutes to Midnight** achievement by:
- Displaying a live schedule of rare spawns (current + next 3)
- Providing one-click TomTom waypoints
- Sharing rare locations to General or Raid chat with clickable map pins

## Project Structure

```
TwilightAscension/          # The actual addon (copy to WoW AddOns folder)
├── TwilightAscension.toc   # Addon manifest
├── Data.lua                # Rare data, coordinates, rotation order
├── Core.lua                # Schedule calculation, waypoints, chat sharing
└── UI.lua                  # Themed UI frame and buttons

assets/                     # Project assets (not part of addon)
├── CurseForgeDescription.md
├── TwilightAscensionRaresIcon.png
└── TwilightAscensionRaresIcon_400x400.png

docs/
├── schedule.md             # Raw rare spawn schedule data
└── CreatingWoWAddons.md    # Reference documentation
```

## Key Technical Details

- **Zone**: Twilight Highlands (Map ID 241)
- **Schedule**: 18 rares, 10-minute rotation, 3-hour full cycle
- **Time calculation**: Uses `GetGameTime()` (realm time) — works across all regions automatically
- **Anchor**: Cycle anchored at 02:50 realm time (minute 170 of day)
- **Interface version**: 110100 (patch 11.1.0)

## Slash Commands

- `/ta` or `/twilight` — Show help
- `/ta show` / `/ta hide` — Toggle window
- `/ta way` — Set waypoint for current rare
- `/ta debug` — Show timing debug info

## CurseForge

- **Project**: https://www.curseforge.com/wow/addons/twilight-ascension (update URL once published)
- **Categories**: Map & Minimap (main), Achievements (secondary)

## Updating the Description

The CurseForge page description is maintained in `assets/CurseForgeDescription.md`.

**If you update this file, alert the user to manually update the CurseForge page** — CurseForge descriptions are not auto-synced from the repo.

Example message:
> ⚠️ I've updated `assets/CurseForgeDescription.md`. Remember to copy the changes to your CurseForge project page.

## Future Enhancements (not yet implemented)

- Achievement progress tracking (filter out already-killed rares)
- Sound/visual alert before spawn
- Minimap button
- Localization support
