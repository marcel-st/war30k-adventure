# Vertical Slice Spec - VS01 Isstvan Extraction

## Goal

Deliver one playable third-person shooter mission from spawn to extraction with keyboard/mouse and controller support.

## Scope in this commit

- Third-person movement and camera orbit.
- Aim mode with shoulder camera zoom behavior.
- Boltgun hitscan fire and reload.
- HUD for health, armor, ammo, objective status.
- Extraction zone objective completion.
- Death Guard-themed placeholder materials and moody battlefield lighting.

## Out of scope for this commit

- Enemy combatants and encounter wave logic.
- Animation state machine and final marine model rig.
- Audio design pass and cinematic scripting.
- Full progression and mission chain.

## Acceptance checklist

- Level boots directly from `project.godot` run scene.
- Player can move, sprint, aim, fire, and reload.
- HUD reacts to ammo changes while firing/reloading.
- Entering extraction zone marks objective as complete.
- No fatal startup script errors from missing nodes/scripts.
