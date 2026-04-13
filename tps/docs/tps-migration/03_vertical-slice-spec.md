# Vertical Slice Spec - VS01 Loyalist Breakout

## Goal

Deliver one fully playable TPS mission lane (spawn -> combat waves -> boss -> extraction)
with chapter narrative beats, controller support, and integrated audio identity.

## In-scope implementation (current main)

### Core shooter loop

- Third-person movement/camera, sprint, aim, hitscan boltgun, reload.
- Health/armor/ammo combat state with fail/victory mission transitions.
- Mission restart support after fail/victory (`Enter`/`R`/gamepad `Start`).

### Enemy and mission flow

- Wave-driven encounter controller with:
  - melee traitors
  - ranged cultists (projectiles)
  - elite nurgle champions
- Boss phase: Harbinger encounter with telegraphed strikes/nova pressure.
- Extraction unlock gating after combat completion.
- Adaptive mission tuning and event-feed messaging during wave flow.

### Narrative and chapter systems

- Four chapter JSON scaffold with cutscene intros and contact dialogues.
- Story interaction layers:
  - chapter intro playback
  - NPC/contact triggered dialogue
  - chapter/contact event feed updates on HUD
- Branch-choice registration and mission consequence hook points.

### Progression and abilities

- Ability system with three active slots:
  - `resilience_surge`
  - `toxic_grenade`
  - `rally_command`
- Progression state broadcasts for level/xp/requisition HUD updates.
- Optional objective reward hooks tied to mission outcomes.

### Audio

- Event-driven audio manager autoload (`SYS_AudioManager.gd`):
  - combat/UI/footstep/boss SFX routing
  - ambience layers
  - combat/intermission music transitions
- Headless-safe audio behavior for runtime validation environments.

### Visual crisp pass

- Curated CC0 texture + sky assets integrated for cleaner readability:
  - ambientCG PBR surfaces for environment/armor material detail
  - Poly Haven sky image for improved scene backdrop
- VS01 visual updates include:
  - textured floor/walls and improved extraction pad emphasis
  - small environment set-dressing to reduce empty graybox feel
  - updated enemy/player material response for more consistent PBR look

## Known constraints (still out of scope)

- Final hero/enemy art production assets and full animation graph polish.
- Full campaign persistence across multiple authored mission scenes.
- Advanced cinematic toolchain beyond current cutscene-shot JSON runtime.
- Full settings menu UX surface (data + backend exist; front-end remains lightweight).

## Acceptance checklist (current)

- `project.godot` boots directly into `SCN_LVL_VerticalSlice_01.tscn`.
- Player can move/sprint/aim/fire/reload with keyboard+mouse and controller.
- HUD updates for HP/armor/ammo/objective/wave/enemy count.
- Wave combat spawns mixed archetypes and handles reinforcements.
- Boss encounter can spawn and resolve mission progression.
- Extraction completes mission only when combat gate opens.
- Story systems can start chapter intros and contact dialogue.
- Branch choices emit to mission systems without fatal errors.
- Audio manager initializes in normal runtime and safely no-ops in headless mode.
- Headless smoke run completes without fatal script parse/runtime failures.
