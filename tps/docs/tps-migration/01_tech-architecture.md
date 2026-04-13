# TPS Technical Architecture (Current Mainline)

This document captures the implemented runtime architecture of the Godot TPS slice on
`main`.

## Core Autoload Services

Configured in `tps/project.godot`:

- `GameState` (`SCN_SYS_GameState.tscn`)
  - Mission state and player stat signals.
  - Story chapter and branch-choice propagation.
  - Ability/progression event bridging.
  - Input action bootstrap for keyboard + gamepad defaults.
- `EventBus` (`SYS_EventBus.gd`)
  - Decoupled gameplay event emission.
- `AudioManager` (`SYS_AudioManager.gd`)
  - Music/SFX/UI bus management and event-to-audio routing.
  - Headless-safe runtime guard for CI/smoke runs.
- `SettingsSystem` (`SYS_Settings.gd`)
  - Runtime settings persistence, including linear audio controls.
- `CombatData` (`SYS_CombatData.gd`)
  - Data loader for combat/AI/mission/progression/story profile JSON.
- `AbilitySystem` (`SYS_AbilitySystem.gd`)
  - Ability cooldowns/effects, timed active effects, player handoff.
- `Progression` (`SYS_Progression.gd`)
  - Progression profile/state integration hooks.
- `DebugTools`, `QATools`
  - Runtime debug toggles and smoke reporting helpers.

## Scene Graph Composition

### `SCN_LVL_VerticalSlice_01.tscn`

- Player and camera rig
- Enemy containers + spawn markers
- Mission controller (`MIS_VS01_Controller.gd`)
- Story systems root
- HUD instance
- Extraction trigger and chapter triggers

### `SCN_SYS_GameState.tscn`

Hosts child systems that are accessed through the `GameState` singleton:

- `ProjectilePool`
- `CombatData`
- `AbilitySystem`
- `AbilityBridge`
- `Progression`
- `Settings`
- `QATools`

## Gameplay Domain Scripts

- `GP_PlayerController.gd`
  - Locomotion, sprint, damage, and ability effect reception.
  - Emits combat and footstep events into `EventBus`.
- `GP_CameraAim.gd`
  - Third-person camera yaw/pitch and aim zoom behavior.
- `WPN_Boltgun.gd`
  - Fire/reload cadence, hit confirmation events, ammo interactions via `GameState`.
- `MIS_VS01_Controller.gd`
  - Wave progression, reinforcement events, adaptive scaling.
  - Optional objective evaluation.
  - Branch consequence application and boss spawn flow.
- Enemy AI:
  - `AI_EnemyTraitorMarine.gd` (melee)
  - `AI_EnemyCultistRanged.gd` (ranged + projectile usage)
  - `AI_EnemyNurgleChampion.gd` (elite melee pressure)
  - `AI_BossHarbinger.gd` (boss phases + telegraphs)
  - `AI_EnemyProjectile.gd` (pooled projectile behavior)

## Narrative Layer

- `STY_StorySystemsRoot.gd`
- `STY_StoryManager.gd`
- `STY_DialogueUI.gd`
- `STY_CutsceneDirector.gd`
- `NPC_ContactActor.gd`

Narrative data is externalized in `tps/data/story/` for chapters, contacts, and cutscenes.

## Data Domains (JSON)

- `tps/data/combat/weapon_profiles.json`
- `tps/data/ai/squad_profiles.json`
- `tps/data/abilities/ability_profiles.json`
- `tps/data/missions/objective_profiles.json`
- `tps/data/missions/mission_profiles.json`
- `tps/data/bosses/boss_profiles.json`
- `tps/data/progression/progression_profiles.json`
- `tps/data/ux/settings_defaults.json`
- `tps/data/qa/test_matrix.json`

## Known Gaps

- Visual content is still mostly prototype/blockout quality.
- Boss/content breadth remains vertical-slice scale.
- Long-form save/meta progression UX is scaffolded, not fully productized.
