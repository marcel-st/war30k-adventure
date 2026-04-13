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
- Death Guard-themed placeholder materials and moody battlefield lighting.

## Out of scope for this commit

- Animation state machine and final marine model rig.
- Audio design pass and cinematic scripting.
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
- No fatal startup script errors from missing nodes/scripts.
