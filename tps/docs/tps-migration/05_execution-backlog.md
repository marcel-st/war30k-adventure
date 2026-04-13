# Execution Backlog - Full TPS Improvement Program

This backlog converts the roadmap into concrete, file-targeted implementation tasks with acceptance criteria.

---

## Phase 0 - Foundation (data-driven runtime)

### Task F0-1: Add centralized gameplay data packs
- **Files**
  - `tps/data/combat/weapon_profiles.json`
  - `tps/data/ai/squad_roles.json`
  - `tps/data/abilities/ability_definitions.json`
  - `tps/data/missions/mission_templates.json`
  - `tps/data/progression/progression_tree.json`
  - `tps/data/bosses/boss_profiles.json`
  - `tps/data/ux/settings_schema.json`
  - `tps/data/qa/runtime_checklist.json`
  - `tps/data/profile/default_profile.json`
- **Acceptance**
  - All files parse as JSON.
  - Runtime systems consume at least one field from each core domain file.

### Task F0-2: Add runtime service singletons
- **Files**
  - `tps/scripts/systems/SYS_EventBus.gd`
  - `tps/scripts/systems/SYS_ProfileManager.gd`
  - `tps/scripts/systems/SYS_SquadDirector.gd`
  - `tps/scenes/systems/SCN_SYS_GameState.tscn`
  - `tps/scripts/systems/SYS_GameState.gd`
- **Acceptance**
  - GameState exposes wrappers for event bus/profile/projectile pool/tactical director.
  - Mission and gameplay scripts can emit and consume service events without direct tight coupling.

### Task F0-3: Add debug/runtime toggles
- **Files**
  - `tps/scripts/systems/SYS_GameState.gd`
  - `tps/scripts/mission/MIS_VS01_Controller.gd`
- **Acceptance**
  - Toggleable runtime flags exist for invulnerability and wave skip hooks.
  - Hooks are no-op in normal play unless explicitly toggled.

---

## Phase 1 - Combat feel pass

### Task F1-1: Data-driven boltgun handling
- **Files**
  - `tps/scripts/weapons/WPN_Boltgun.gd`
  - `tps/data/combat/weapon_profiles.json`
- **Acceptance**
  - Bloom/spread and recoil values load from profile data.
  - Fire feel differs between first shot and sustained fire.

### Task F1-2: Hit feedback UX hooks
- **Files**
  - `tps/scripts/ui/UI_HUDController.gd`
  - `tps/scenes/ui/SCN_UI_HUD.tscn`
  - `tps/scripts/systems/SYS_EventBus.gd`
- **Acceptance**
  - Hit confirmation appears on successful shots.
  - Indicator auto-fades.

---

## Phase 2 - Enemy coordination AI

### Task F2-1: Tactical role assignment
- **Files**
  - `tps/scripts/systems/SYS_SquadDirector.gd`
  - `tps/scripts/ai/AI_EnemyTraitorMarine.gd`
  - `tps/scripts/ai/AI_EnemyCultistRanged.gd`
  - `tps/scripts/ai/AI_EnemyNurgleChampion.gd`
  - `tps/scripts/mission/MIS_VS01_Controller.gd`
- **Acceptance**
  - Enemies receive role updates (suppressor/flanker/rusher/anchor).
  - Role changes alter movement/engagement behavior in combat.

---

## Phase 3 - Player ability kit

### Task F3-1: Implement three ability actions
- **Files**
  - `tps/scripts/gameplay/GP_PlayerController.gd`
  - `tps/scripts/systems/SYS_GameState.gd`
  - `tps/data/abilities/ability_definitions.json`
- **Acceptance**
  - Resilience, toxic burst, and rally abilities trigger from input.
  - Cooldowns gate ability reuse.

### Task F3-2: Ability status in HUD
- **Files**
  - `tps/scripts/ui/UI_HUDController.gd`
  - `tps/scenes/ui/SCN_UI_HUD.tscn`
- **Acceptance**
  - HUD displays readiness/cooldown status.

---

## Phase 4 - Mission variety

### Task F4-1: Optional objective + extraction hold
- **Files**
  - `tps/scripts/mission/MIS_VS01_Controller.gd`
  - `tps/data/missions/mission_templates.json`
- **Acceptance**
  - Mission includes optional objective tracking.
  - Extraction requires timed hold before completion.

---

## Phase 5 - Progression/meta

### Task F5-1: Persistent profile and reward flow
- **Files**
  - `tps/scripts/systems/SYS_ProfileManager.gd`
  - `tps/scripts/systems/SYS_GameState.gd`
  - `tps/scripts/mission/MIS_VS01_Controller.gd`
  - `tps/data/progression/progression_tree.json`
  - `tps/data/profile/default_profile.json`
- **Acceptance**
  - Mission rewards persist to `user://` profile save.
  - Unlocks become available after threshold progression.

---

## Phase 6 - Narrative branching

### Task F6-1: Branch flag integration
- **Files**
  - `tps/scripts/story/STY_StoryManager.gd`
  - `tps/scripts/story/STY_StorySystemsRoot.gd`
  - `tps/scripts/mission/MIS_VS01_Controller.gd`
- **Acceptance**
  - Mission outcome can set branch flags.
  - Narrative system reacts to at least one branch flag.

---

## Phase 7 - Boss encounters + chapter climax

### Task F7-1: Add chapter boss archetype
- **Files**
  - `tps/scripts/ai/AI_BossGraveWarden.gd`
  - `tps/scenes/enemies/SCN_BossGraveWarden.tscn`
  - `tps/scripts/mission/MIS_VS01_Controller.gd`
  - `tps/data/bosses/boss_profiles.json`
- **Acceptance**
  - Boss spawns in late mission phase.
  - Boss has at least 2 behavior phases.

---

## Phase 8 - Art/audio identity hooks

### Task F8-1: Chapter mood and ambience parameters
- **Files**
  - `tps/data/missions/mission_templates.json`
  - `tps/scripts/mission/MIS_VS01_Controller.gd`
- **Acceptance**
  - Chapter transitions alter lighting/encounter tone parameters.

---

## Phase 9 - Performance/scalability follow-through

### Task F9-1: AI and projectile scalability controls
- **Files**
  - `tps/scripts/ai/AI_EnemyProjectile.gd`
  - `tps/scripts/mission/MIS_VS01_Controller.gd`
  - `tps/scripts/systems/SYS_ProjectilePool.gd`
- **Acceptance**
  - Projectile reuse path remains stable under sustained ranged fire.
  - Enemy updates avoid per-frame expensive scene scans.

---

## Phase 10 - UX completeness

### Task F10-1: Runtime settings menu + applied options
- **Files**
  - `tps/scripts/ui/UI_SettingsMenu.gd`
  - `tps/scenes/ui/SCN_UI_Settings.tscn`
  - `tps/scenes/levels/SCN_LVL_VerticalSlice_01.tscn`
  - `tps/scripts/gameplay/GP_CameraAim.gd`
  - `tps/data/ux/settings_schema.json`
- **Acceptance**
  - Settings menu toggles in runtime.
  - Changes apply and persist through ProfileManager.

---

## Phase 11 - QA/balancing scaffolding

### Task F11-1: Add machine-readable validation checklist
- **Files**
  - `tps/data/qa/runtime_checklist.json`
  - `tps/tests/smoke_scenarios.md`
- **Acceptance**
  - Checklist includes startup, controls, mission states, and progression validation points.

---

## Delivery Cadence (implementation order)

1. Foundation (Phase 0)
2. Combat + AI + abilities + mission variety (Phases 1-4)
3. Progression + branching narrative (Phases 5-6)
4. Boss + environment identity + UX (Phases 7-10)
5. QA scaffolding and final validation (Phase 11)
