# Execution Backlog - TPS Mainline Follow-up

This backlog reflects the state after merging the TPS setup, narrative campaign, quality sprint,
and audio integration branches into `main`.

Each item is scoped as a forward task from the current implementation baseline.

---

## Completed baseline now on `main`

- Data-driven core domains are in place (`tps/data/*`), including combat, AI, abilities,
  missions, progression, settings defaults, and QA matrix.
- Runtime service autoloads are active: `GameState`, `EventBus`, `DebugTools`, `SettingsSystem`,
  `AudioManager`, `QATools`, `CombatData`, `AbilitySystem`, `Progression`.
- Mission runtime includes adaptive pressure scaling and branch consequence application.
- Narrative runtime includes chapter intros, contact dialogues, and cutscene direction.
- Boss encounter and telegraph pass are implemented.
- Audio event routing and open-license asset integration are implemented.

---

## Phase A - Combat and weapon tuning pass

### Task A1: Externalize and tune recoil/spread envelopes
- **Files**
  - `tps/scripts/weapons/WPN_Boltgun.gd`
  - `tps/data/combat/weapon_profiles.json`
- **Acceptance**
  - Spread/recoil envelope values are fully profile-driven.
  - Weapon feel can be changed without script edits.

### Task A2: Differentiate enemy hit reactions by archetype
- **Files**
  - `tps/scripts/ai/AI_EnemyTraitorMarine.gd`
  - `tps/scripts/ai/AI_EnemyCultistRanged.gd`
  - `tps/scripts/ai/AI_EnemyNurgleChampion.gd`
- **Acceptance**
  - Each archetype reacts differently to damage windows (stagger timing/threshold behavior).

---

## Phase B - Mission variety and replayability

### Task B1: Add second mission profile and scene variant
- **Files**
  - `tps/data/missions/mission_profiles.json`
  - `tps/scenes/levels/SCN_LVL_VerticalSlice_02.tscn` (new)
  - `tps/scripts/mission/MIS_VS02_Controller.gd` (new)
- **Acceptance**
  - A second playable mission with distinct wave and objective composition exists.

### Task B2: Expand optional objectives and reward hooks
- **Files**
  - `tps/data/missions/mission_profiles.json`
  - `tps/scripts/mission/MIS_VS01_Controller.gd`
  - `tps/scripts/systems/SYS_GameState.gd`
- **Acceptance**
  - Multiple optional objective conditions can be tracked and rewarded in one run.

---

## Phase C - Progression and profile persistence

### Task C1: Persist progression data to `user://`
- **Files**
  - `tps/scripts/systems/SYS_Progression.gd`
  - `tps/scripts/systems/SYS_GameState.gd`
- **Acceptance**
  - Level/xp/requisition and unlocked rewards survive restart.

### Task C2: Surface unlock/perk state in HUD
- **Files**
  - `tps/scenes/ui/SCN_UI_HUD.tscn`
  - `tps/scripts/ui/UI_HUDController.gd`
- **Acceptance**
  - HUD exposes at least one unlocked perk/reward state in-mission.

---

## Phase D - Narrative consequence depth

### Task D1: Multi-branch consequence stacking across chapters
- **Files**
  - `tps/scripts/story/STY_StoryManager.gd`
  - `tps/scripts/mission/MIS_VS01_Controller.gd`
  - `tps/data/missions/mission_profiles.json`
- **Acceptance**
  - Mission state can apply compounded consequences from chapter 2 + chapter 3 decisions.

### Task D2: Contact outcome variants
- **Files**
  - `tps/data/story/dialogues/contacts_ch2.json`
  - `tps/data/story/dialogues/contacts_ch3.json`
  - `tps/scripts/story/STY_DialogueUI.gd`
- **Acceptance**
  - At least one contact renders alternate line sets based on prior branch choice.

---

## Phase E - UX and settings completeness

### Task E1: In-game settings panel scene
- **Files**
  - `tps/scenes/ui/SCN_UI_Settings.tscn` (new)
  - `tps/scripts/ui/UI_SettingsMenu.gd` (new)
  - `tps/scripts/systems/SYS_Settings.gd`
- **Acceptance**
  - Players can change audio/sensitivity/subtitle settings at runtime and persist them.

### Task E2: Input mapping discoverability
- **Files**
  - `tps/scenes/ui/SCN_UI_HUD.tscn`
  - `tps/scripts/ui/UI_HUDController.gd`
- **Acceptance**
  - Contextual prompts display current action bindings for keyboard/controller.

---

## Phase F - Performance and validation

### Task F1: Wave simulation stress profile
- **Files**
  - `tps/data/qa/test_matrix.json`
  - `tps/scripts/mission/MIS_VS01_Controller.gd`
  - `tps/scripts/systems/SYS_ProjectilePool.gd`
- **Acceptance**
  - High-pressure ranged-wave test case is documented and reproducible from QA data.

### Task F2: Headless smoke target docs + script
- **Files**
  - `tps/tests/smoke_scenarios.md` (new)
  - `scripts/run_tps_smoke.sh` (new)
- **Acceptance**
  - One command path runs editor import pass + headless quit smoke validation.

---

## Suggested implementation order

1. Phase C (persistence baseline)
2. Phase E (runtime usability)
3. Phase B (content expansion)
4. Phase D (narrative depth)
5. Phase A (combat tuning)
6. Phase F (stress and validation hardening)
