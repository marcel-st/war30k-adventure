# Vertical Slice Spec - VS01 Isstvan Extraction

## Goal

Deliver one playable third-person shooter mission from spawn to extraction with keyboard/mouse and controller support.

## Scope in this commit

- Third-person movement and camera orbit.
- Aim mode with shoulder camera zoom behavior.
- Boltgun hitscan fire and reload.
- HUD for health, armor, ammo, objective status.
- Extraction zone objective completion after combat gating.
- Multiple enemy archetypes:
  - melee traitor marine
  - ranged cultist with projectiles
  - elite nurgle champion
- Encounter director scripting:
  - mixed-wave composition
  - timed reinforcement events
  - in-mission event feed messaging
- Mission state loop:
  - active combat
  - failed (player death)
  - victory (extraction reached)
  - restart (`Enter`/`R`/gamepad `Start`) support
- Narrative layer:
  - four-chapter story progression scaffold
  - chapter intro cutscenes with subtitle timeline and skip support (`Esc`/gamepad `B`/`Start`)
  - contact moments through NPC interaction triggers (`E`/gamepad `A`)
  - chapter/event/subtitle HUD integration
- Death Guard-themed placeholder materials and moody battlefield lighting.

## Out of scope for this commit

- Animation state machine and final marine model rig.
- Full cinematic camera rails and authored animation track system.
- Full progression and mission chain.

## Acceptance checklist

- Level boots directly from `project.godot` run scene.
- Player can move, sprint, aim, fire, and reload.
- HUD reacts to ammo changes while firing/reloading.
- Wave composition spawns melee/ranged/elite enemies.
- Reinforcement events can spawn additional units mid-wave.
- Entering extraction zone marks objective complete only after combat lock is cleared.
- Player death marks mission failed and blocks objective completion.
- Restart key reloads the mission scene after fail or victory.
- Story systems load chapter data from JSON and expose chapter intro cutscenes.
- NPC contact moments can trigger dialogue in-mission and update objective/event messaging.
- Controller can progress dialogue/cutscene flow without keyboard.
- No fatal startup script errors from missing nodes/scripts.
