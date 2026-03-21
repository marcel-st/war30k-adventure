# Changelog

All notable changes to this project are documented in this file.

## [0.4.0] - 2026-03-22

### Added
- `AnimatedSprite` module with JSON frame definitions and spritesheet loading.
- 8-direction animation switching via `setAnimation(state, direction)` where directions map to `N, NE, E, SE, S, SW, W, NW`.
- Idle breathing shoulder-pad motion and heavy 4-frame walk stomp behavior.
- Generated sprite assets and directional frame JSON files:
  - `assets/garro_sheet.bmp`
  - `assets/traitor_sheet.bmp`
  - `assets/garro_frames.json`
  - `assets/traitor_frames.json`

### Changed
- Integrated animated sprites into runtime gameplay rendering for player and enemies.
- Added procedural edge-highlighting pass for power-armor top edges in sprite generation (`scripts/generate_sheets.py`).
- Updated README with animation format details and refreshed gameplay images.

## [0.3.0] - 2026-03-21

### Added
- Enemy projectile attacks for ranged pressure during combat.
- Tactical minimap HUD showing walls, enemies, beacons, player, and objective zone.
- Branding and media assets:
  - `docs/logo.svg`
  - `docs/images/gameplay-istvaan.svg`
  - `docs/images/gameplay-terra.svg`

### Changed
- Refactored the game into a modular C++ structure:
  - Core math/font module
  - World/stage + collision module
  - Rendering module
  - Game loop module
  - Thin launcher in `main.cpp`
- Updated CMake build to compile multiple translation units.
- Expanded project documentation with architecture details, controls, setup, and visuals.

## [0.2.0] - 2026-03-21

### Added
- Stage-specific tilemaps and collision navigation.
- Pixel-style character/enemy/objective rendering.

## [0.1.0] - 2026-03-21

### Added
- Initial playable Linux C++/SDL2 top-down action-adventure prototype.
- Four-stage campaign arc and objective progression.
- Keyboard and controller support.
