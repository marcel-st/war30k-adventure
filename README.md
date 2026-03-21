# WAR30K ADVENTURE: GARRO'S FLIGHT

![War30K Adventure Logo](docs/logo.svg)

![War30K Mark](docs/images/logo-mark.svg)

Linux-native top-down action-adventure RPG prototype in C++/SDL2.

You play as Nathaniel Garro during the Horus Heresy, surviving Isstvan V, crossing the warp, breaking the Luna approach blockade, and reaching Terra to deliver warning of Horus' betrayal.

## Gameplay Overview

- Genre: top-down action-adventure (classic 16-bit style flow)
- Platform target: Linux
- Input: keyboard + game controller
- Campaign: 4 connected story stages with objectives and narrative panels
- Combat: melee attack arc + enemy ranged projectiles
- Tactical UI: objective tracking, HP HUD, and minimap

## Story Campaign

1. **Isstvan V – Broken Loyalty**
	- Escape the Drop Site massacre and reach extraction.
2. **Warp Crossing – The Eisenstein**
	- Stabilize warp wards by activating beacon relics.
3. **Luna Approach – Blockade Run**
	- Purge traitor boarding forces to open a corridor.
4. **Terra – The Warning**
	- Reach the relay and send warning to the Emperor.

## Screenshots / Images

![Gameplay - Isstvan V](docs/images/gameplay-istvaan.svg)

![Gameplay - Terra](docs/images/gameplay-terra.svg)

## Controls

### Keyboard

- Move: `W A S D` or Arrow Keys
- Attack: `Space` or `J`
- Interact / Continue: `E` or `Enter`
- Restart after win/loss: `R`
- Quit: `Esc`

### Controller

- Move: Left Stick
- Attack: `A` (or Right Trigger)
- Interact / Continue: `X` or `B`

## Tech Stack

- Language: C++17
- Rendering/Input: SDL2
- Build system: CMake

## Modular Project Structure

```text
include/
  core_types.hpp        # Shared constants, data structs, enums, math signatures
  font.hpp              # Bitmap font interface
  world.hpp             # Stages, map generation, collision
  render.hpp            # Sprite/tile/minimap rendering
  game.hpp              # Game class interface

src/
  main.cpp              # Thin launcher
  game.cpp              # Core loop, state machine, gameplay systems
  core/
	 common.cpp          # Math + bitmap font implementation
	 world.cpp           # Stage data + map/collision implementation
	 render.cpp          # Tile/sprite/minimap drawing implementation
```

## Performance Notes (Modular + Fast)

- Split into translation units to reduce incremental build time and improve code locality.
- Data-oriented containers (`std::vector`) for enemies/projectiles/beacons.
- `reserve()` used for hot-path entity vectors to reduce runtime reallocations.
- Fixed-size tile grid with lightweight collision checks.
- Frame delta clamping to avoid simulation spikes.
- Rendering built on simple primitives and low-overhead pixel sprites.

## Linux Setup

### Dependencies

- `g++` or `clang++` with C++17 support
- `cmake` (3.16+)
- SDL2 development package

Debian/Ubuntu example:

```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake libsdl2-dev
```

## Build

```bash
cmake -S . -B build
cmake --build build -j
```

## Run

```bash
./build/war30k_adventure
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

## Disclaimer

This is a fan-made, non-commercial prototype inspired by the Warhammer 30K setting.

