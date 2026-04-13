# TPS Vision - Death Guard 30K

This migration evolves the original SDL2 top-down prototype into a third-person
shooter focused on 30K-era loyalist Death Guard combat fantasy.

## Core Pillars

- Heavy, deliberate Astartes movement and weapon feel.
- Over-shoulder third-person shooting with objective-driven encounters.
- Warhammer 30K visual identity: worn ceramite, gothic military ruins,
  smoke-heavy atmospherics.
- Story continuity from Garro's warning run while shifting to 3D mission spaces.

## Implemented Vertical Slice Outcome

The current `tps/` implementation now includes:

- Playable VS01 mission from spawn to extraction.
- Core movement/combat loop:
  - locomotion, sprint, shoulder aim, hitscan boltgun fire, reload.
- Wave combat orchestration:
  - melee/ranged/elite enemy composition
  - timed reinforcement events
  - boss encounter and wave-to-extraction state flow.
- Mission-layer progression and branch hooks:
  - adaptive mission pacing
  - branch consequence modifiers
  - optional objective reward path.
- Narrative systems:
  - chapter intro cutscenes
  - contact/NPC dialogue runtime
  - chapter/contact/event feed integration in HUD.
- Audio identity:
  - hard-rock combat music + intermission rock ballad transition
  - event-driven combat/UI/ability/boss/footstep SFX.

## Next Vision Steps

- Replace placeholder geometry with cohesive chapter-specific combat spaces.
- Expand campaign from one vertical slice into chapter-linked missions with
  persistent outcomes.
- Deepen class fantasy through animation polish, stronger weapon presentation,
  and authored boss climaxes.
