# WAR30K ADVENTURE: GARRO'S FLIGHT

![War30K Adventure Logo](docs/logo.svg)

![War30K Mark](docs/images/logo-mark.svg)

WAR30K Adventure currently contains two playable development tracks in one repository:

1. A Linux-native C++/SDL2 top-down action-adventure prototype.
2. A Godot 4 third-person shooter vertical slice (`tps/`) focused on a loyalist Death Guard fantasy during the Horus Heresy.

## Current Project Status

### SDL2 top-down prototype (legacy track)

- 4-stage campaign structure and objective flow.
- Retro sprite rendering and ALttP-inspired movement/cadence.
- Melee + projectile pressure combat loop.
- Minimap, objective UI, and mission-state flow.

### Godot TPS vertical slice (active migration track)

- Third-person locomotion, aim camera, sprint, hitscan boltgun, reload.
- Wave mission controller with mixed enemy archetypes and reinforcements.
- Boss encounter with attack telegraphs and multi-phase behavior.
- Story layer with chapter intros, NPC contacts, dialogue UI, and cutscene flow.
- Ability kit (`resilience_surge`, `toxic_grenade`, `rally_command`) with cooldowns and physicalized gameplay effects.
- Adaptive mission director + branch consequence hooks.
- Progression hooks (level/xp/requisition) and HUD integration.
- Audio runtime via autoloaded `AudioManager`:
  - combat SFX, UI SFX, footsteps, boss cues
  - layered ambience
  - hard-rock combat tracks and intermission rock ballad transitions
- Graphics crispness pass:
  - CC0 PBR texture integration for environment/character readability
  - sky panorama + lighting/post-process tuning for cleaner contrast

## Repository Layout

```text
.
├── include/                     # C++ headers (SDL2 track)
├── src/                         # C++ source (SDL2 track)
├── assets/                      # C++ track assets
├── docs/                        # Root project docs/release notes
└── tps/                         # Godot 4 TPS migration project
    ├── assets/audio/            # Integrated runtime audio assets
    ├── audio/                   # Audio source provenance + licenses
    ├── data/                    # JSON gameplay/story/progression/config data
    ├── scenes/                  # Godot scenes
    ├── scripts/                 # GDScript runtime systems
    └── docs/tps-migration/      # TPS migration design/runtime docs
```

## Build and Run (SDL2)

### Dependencies

- C++17 compiler (`g++` or `clang++`)
- `cmake` (3.16+)
- SDL2 development package

Debian/Ubuntu example:

```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake libsdl2-dev
```

Build and run:

```bash
cmake -S . -B build
cmake --build build -j
./build/war30k_adventure
```

## Run (Godot TPS)

Install Godot 4.x, then:

```bash
cd tps
godot4 --editor
```

If your binary is named `godot`, use that instead of `godot4`.

Headless smoke check:

```bash
godot --headless --path tps --quit
```

## TPS Controls

- Move: `W A S D` or left stick
- Look: mouse or right stick
- Aim: right mouse button / gamepad LT-LB mapping (project action `aim`)
- Fire: left mouse button / gamepad RT-RB mapping (project action `fire`)
- Reload: `R` or gamepad `Y`
- Sprint: `Shift` or left stick press
- Interact: `E` or gamepad `A`
- Dialogue continue: `Enter`/mouse left/gamepad `A`
- Skip dialogue/cutscene: `Esc` or gamepad `B`/`Start`
- Restart after fail/win: `Enter`/`R`/gamepad `Start`

## Audio Attribution

Integrated TPS audio assets were sourced from open-license packs.

- Manifest: `tps/audio/ASSET_MANIFEST.json`
- License notes: `tps/audio/THIRD_PARTY_AUDIO_LICENSES.md`

## Graphics Attribution

Recent visual upgrades in the TPS scene use open-license graphics assets.

- Manifest: `tps/art/GRAPHICS_ASSET_MANIFEST.json`
- License notes: `tps/art/THIRD_PARTY_GRAPHICS_LICENSES.md`

## Additional Documentation

- Root release history: [`CHANGELOG.md`](CHANGELOG.md)
- Latest recorded SDL2 release note: `docs/releases/v0.6.0.md`
- TPS migration docs: `tps/docs/tps-migration/`

## Disclaimer

This is a fan-made, non-commercial prototype inspired by the Warhammer 30K setting.

