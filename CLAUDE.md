# Twilight Ascension

A World of Warcraft addon for tracking rare spawns during the Midnight pre-patch "Twilight Ascension" event (January 27 – March 2, 2026).

## Purpose

Helps players complete the **Two Minutes to Midnight** achievement by:
- Displaying a live schedule of rare spawns (current + next 3)
- Providing one-click TomTom waypoints
- Sharing rare locations to General or Raid chat with clickable map pins

## Project Structure

```
TwilightAscensionRares/          # The actual addon (copy to WoW AddOns folder)
├── TwilightAscensionRares.toc   # Addon manifest
├── Data.lua                     # Rare data, coordinates, rotation order
├── Core.lua                     # Schedule calculation, waypoints, chat sharing
└── UI.lua                       # Themed UI frame and buttons

assets/                          # Project assets (not part of addon)
├── CurseForgeDescription.md
├── Screenshot1.png
├── TwilightAscensionRaresIcon.png
└── TwilightAscensionRaresIcon_400x400.png

docs/
├── schedule.md             # Raw rare spawn schedule data
└── CreatingWoWAddons.md    # Reference documentation
```

## Key Technical Details

- **Zone**: Twilight Highlands (Map ID 241)
- **Schedule**: 18 rares, 5-minute rotation, 90-minute full cycle
- **Time calculation**: Uses `GetGameTime()` (realm time) — works across all regions automatically
- **Anchor**: Region-specific — NA at 00:25 (minute 25), EU at 01:25 (minute 85). Uses `GetCurrentRegion()` to select.
- **Interface version**: 120000 (patch 12.0.0)

### Patch 12 API Note

Patch 12.0.0 (Midnight pre-patch, January 20, 2026) introduces major addon API changes via the "Secret Values" system that restricts combat data access. **This addon is unaffected** — it uses only scheduling/utility APIs (`GetGameTime()`, UI frames, TomTom integration) rather than combat-related functions. See [docs/CreatingWoWAddons.md](docs/CreatingWoWAddons.md) for full details on Patch 12 changes if extending this addon's functionality.

## Slash Commands

- `/ta` or `/twilight` — Show help
- `/ta show` / `/ta hide` — Toggle window
- `/ta way` — Set waypoint for current rare
- `/ta debug` — Show timing debug info

## CurseForge

- **Project**: https://www.curseforge.com/wow/addons/twilightascensionrares
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
