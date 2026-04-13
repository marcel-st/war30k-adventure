# TPS Technical Architecture (Bootstrap)

This document captures the first implementation slice of the Godot-based TPS runtime.

## Runtime Components

- `GameState` autoload:
  - Player health/armor state
  - Ammo/magazine state
  - Objective text and completion flags
  - HUD synchronization signals
- `PlayerMarine` scene:
  - `CharacterBody3D` locomotion with gravity
  - Third-person aim camera rig
  - Boltgun node at weapon socket
- `SCN_LVL_VerticalSlice_01`:
  - Playable test arena floor
  - Extract zone trigger
  - Mission controller + HUD instance

## Script Roles

- `GP_PlayerController.gd`
  - Movement, sprint modulation, and facing direction
  - Mouse capture toggling
  - Triggering boltgun fire/reload calls
- `GP_CameraAim.gd`
  - Yaw/pitch handling
  - Aim shoulder zoom via spring arm + FOV
  - Camera access for fire traces
- `WPN_Boltgun.gd`
  - Fire cooldown and reload timing
  - Hitscan ray query
  - Debug tracer line rendering
- `MIS_VS01_Controller.gd`
  - Mission objective initialization
  - Extraction completion trigger handling
- `UI_HUDController.gd`
  - Displays health/armor/ammo/objective from `GameState`

## Known Bootstrap Limitations

- No enemy AI yet.
- No animation graph or rigged marine model yet.
- No weapon spread/recoil model yet (currently fixed-center hitscan).
- No save/checkpoint pipeline yet.
