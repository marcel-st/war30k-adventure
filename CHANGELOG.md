# Changelog

All notable changes to this project are documented in this file.

## [0.5.0] - 2026-03-22

### Added
- `Player` class for Nathaniel Garro with ALttP-style 4-direction sprite state (`Up`, `Down`, `Left`, `Right`).
- `Player::render()` path using `SDL_RenderCopyEx` with frame selection from a master sprite sheet.
- Player sword swing state with a 180-degree arc hitbox and tuned slash cadence.
- `Enemy` base class module (`war30k::ai`) with derived variants:
  - `DeathGuardTraitorEnemy`
  - `NurgleDaemonEnemy`
- Zelda-style enemy AI (random wander + aggro pursuit by player distance).
- Legion palette swap helper using `SDL_SetTextureColorMod`.

### Changed
- Integrated `Player` class into gameplay loop for movement, sword collision, and rendering.
- Replaced runtime enemy movement logic with Enemy base-class AI updates.
- Added knockback-on-hit behavior that separates enemies from Garro's collision box.
- Updated README architecture and feature documentation for Player + Enemy systems.

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
