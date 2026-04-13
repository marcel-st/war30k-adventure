# Changelog

All notable changes to this project are documented in this file.

## [0.7.0] - 2026-04-12

### Added
- Godot TPS audio stack:
  - `tps/scripts/systems/SYS_AudioManager.gd` autoload for music/SFX/UI buses and event routing.
  - Licensed third-party music and SFX packs under `tps/assets/audio/`.
  - Audio provenance and license documentation:
    - `tps/audio/ASSET_MANIFEST.json`
    - `tps/audio/THIRD_PARTY_AUDIO_LICENSES.md`
- Story and mission extension systems:
  - Multi-chapter story runtime, dialogue, and cutscene directors.
  - Branch-choice propagation into mission pacing/consequence logic.
  - Mission profile data (`tps/data/missions/mission_profiles.json`) for adaptive/balance tuning.

### Changed
- Merged the full TPS branch history into `main`:
  - `cursor/initial-setup-7401`
  - `cursor/narrative-campaign-7401`
  - `cursor/quality-sprint-7401`
- Expanded TPS gameplay systems on main:
  - Boss telegraphs and phase pressure tuning.
  - Ability physicalization (`toxic_grenade` hazard area, damage reduction/buffs).
  - Progression HUD line (level/xp/requisition) and profile-linked reward flow.
  - Adaptive mission director and branch-dependent wave composition.
- Updated settings defaults to use linear audio controls (`master_volume`, `music_volume`, `sfx_volume`) for easier runtime scaling and persistence.

### Fixed
- Eliminated headless validation regressions from audio script loading:
  - Removed legacy preload/runtime handler mismatch path.
  - Added headless-safe audio manager behavior to avoid audio resource teardown errors in smoke runs.
- Resolved multiple TPS runtime integration issues previously tracked in branch commits (enemy muzzle paths, profile wiring, duplicate function definitions, autoload usage consistency).

## [0.6.0] - 2026-03-22

### Added
- Retro sprite-system module:
  - `include/sprite_system.hpp`
  - `src/core/sprite_system.cpp`
- New sprite entities for the active gameplay loop:
  - `retro::SpaceMarine` (2-frame walk cadence + torso bob)
  - `retro::WarpDaemon` (sine-wave hover/floating)
- Y-sort utility for stable top-down render depth ordering (`sortEntitiesByY`).

### Changed
- Integrated retro sprite entities into `game.cpp` runtime update/render paths.
- Replaced primary character render pass with Y-sorted entity rendering (Garro + enemies).
- Kept fallback rendering for missing textures to preserve playability.
- Updated docs and gameplay image callouts for retro visuals and depth sorting.

### Fixed
- Briefing lock-in: movement input now exits briefing and starts gameplay immediately.
- Eisenstein mission start collision: stage spawn positions moved to guaranteed walkable tiles.
- Added spawn safety fallback to random free tile when a configured spawn collides.

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
