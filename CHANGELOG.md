# Changelog

All notable changes to Twilight Ascension Rares will be documented in this file.

## [1.1.0] - 2026-01-28

### Changed
- Updated spawn interval from 10 minutes to 5 minutes (90-minute full cycle) to match the Feb 28 respawn hotfix
- Updated bonus rare window check from 10 minutes to 5 minutes
- Bumped addon version to 1.1.0

## [1.0.2] - 2026-01-28

### Fixed
- Removed zone ID prefix from `/way` commands in chat sharing (TomTom uses current zone context)

### Changed
- Sharing a rare to chat now also sets a TomTom waypoint automatically
- Updated CurseForge description to reflect current UI (W/G/R inline buttons, removed bonus rare reference)
- Updated CurseForge URLs from legacy domain to current domain in README
- Fixed project structure and naming references in CLAUDE.md
- Added screenshot to project assets and README preview

## [1.0.1] - 2026-01-28

### Fixed
- Replaced manual map pin hyperlink formatting with WoW's native `C_Map.SetUserWaypoint` / `GetUserWaypointHyperlink` API for reliable clickable map pins in chat
- Removed leftover debug print statements from chat sharing

### Changed
- Chat share messages now use native map pin links instead of manually constructed hyperlinks

## [1.0.0] - 2026-01-28

### Added
- Inline action buttons (W/G/R) on each rare row for waypoints and chat sharing
- Addon icon (icon.tga) and `IconTexture` / `Category` fields in TOC
- Chat messages now include timing info and `/way` command for easy copying
- Waypoint icon in clickable map pin links
- Dynamic General channel lookup instead of hardcoded channel 1
- Auto-hide UI when leaving Twilight Highlands

### Changed
- Redesigned UI layout: compact 320x135 frame with per-row action buttons replacing bottom button bar
- Current rare shown as muted "Now"; next rare highlighted green as primary focus
- Glow frame parented to main frame (moves correctly when dragged)
- Fixed off-by-one error in upcoming rare spawn time calculation
- Map pin coordinates use proper integer format
- Uses `UIPanelButtonTemplate` for reliable button input handling

### Removed
- Bottom button bar (Waypoint / Share /1 / Share Raid)
- Bonus rare (Voice of the Eclipse) indicator
- Row click-to-waypoint and hover tooltips (replaced by inline buttons)

## [0.1.2] - 2026-01-28

### Changed
- Updated Interface version to 120000 for Patch 12.0.0 compatibility
- Updated WoW version badge to 12.0.0 in README

### Removed
- Deleted duplicate claude.md file (consolidated to CLAUDE.md)

## [0.1.1] - 2026-01-28

### Added
- Apache License 2.0 file
- Comprehensive GitHub README with installation instructions, feature overview, and full rare rotation reference
- GitHub and Buy Me a Coffee links to CurseForge description

### Changed
- Set CurseForge project ID to 1447415 in TOC file
- Fixed addon name consistency ("Twilight Ascension Rares" instead of "Twilight Ascension") in CurseForge description
- Added `/twilight` alias to command documentation in CurseForge description
- Added Patch 12 API compatibility note to development documentation

## [0.1.0] - 2026-01-28

### Added
- Initial release for the Midnight pre-patch "Twilight Ascension" event
- Live schedule display showing current rare and next 3 upcoming spawns
- TomTom waypoint integration with one-click buttons
- Chat sharing to General or Raid chat with clickable map pins
- Slash commands: `/ta`, `/twilight` for addon control
- Twilight-themed UI with purple/gold color scheme
- 18-rare rotation schedule (10-minute intervals, 3-hour cycle)
- Automatic realm time detection for all regions
