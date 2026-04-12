# Narrative Bible - Loyalist Death Guard Arc

## Pillars

- Tone: stoic, attritional, disciplined, anti-theatrical.
- Perspective: loyalist Death Guard strike captain operating after the Isstvan betrayal.
- Narrative function: each chapter delivers one operational objective plus one human contact beat.
- Delivery model: brief intro cutscene, one or more contact moments, gameplay combat lane, extraction/transition.

## Four-Chapter Arc

### Chapter I - Drop Site Aftermath

- Setting: ash plains and ruined kill-lanes immediately after the massacre.
- Objective beat: establish survival corridor and hold until extraction route opens.
- Contact beat: Macer Varren reports traitor sweep patterns and stabilizes loyalist comms.
- Theme: betrayal is acknowledged but subordinated to duty.

### Chapter II - Warp Transit Crisis

- Setting: unstable relay corridor under warp-static pressure.
- Objective beat: secure transmission lane while sabotage pressure rises.
- Contact beat: Vox-Magos Hest confirms traitor ciphers inside maintenance channels.
- Theme: endurance over certainty.

### Chapter III - Blockade Breach

- Setting: Luna approach under active interdiction.
- Objective beat: force a breach to preserve warning route continuity.
- Contact beat: bridge vox coordination under boarding pressure.
- Theme: attrition as strategy.

### Chapter IV - Terra Relay

- Setting: final relay bastion with collapsing perimeter.
- Objective beat: hold chamber and complete transmission window.
- Contact beat: Euphrati Keeler and Malcador relay guidance at final stand.
- Theme: warning delivered through sacrifice-capable resolve.

## Dialogue Style Guide

- Keep lines concise and purposeful; avoid ornate rhetoric.
- Favor concrete verbs (hold, anchor, endure, breach, transmit).
- Keep operational information embedded in character voice.
- Loyalist Death Guard voice should feel emotionally restrained but morally unambiguous.

## Runtime Authoring Schema

### Chapters (`data/story/chapters/chapters.json`)

Each chapter entry uses:

- `chapter_id`: unique chapter key.
- `title`: UI-ready chapter title.
- `summary`: short context string.
- `intro_cutscene`: path to cutscene JSON.
- `contacts_file`: path to contacts JSON.

### Contacts (`data/story/dialogues/contacts_*.json`)

Top-level:

- `chapter_id`: chapter key for organization.
- `contacts`: array of contact blocks.

Each contact block:

- `contact_id`: unique trigger key used by NPCs and mission scripts.
- `display_name`: name used in event messaging.
- `objective_update` (optional): objective text to push after dialogue.
- `lines`: array of `{ speaker, text }`.

### Cutscenes (`data/story/cutscenes/*.json`)

Top-level:

- `cutscene_id`: unique key.
- `title`: display label.
- `allow_skip`: whether skip action is honored.
- `shots`: ordered camera beats.

Each shot:

- `duration`: seconds.
- `camera_pos`: `[x, y, z]`.
- `look_at`: `[x, y, z]`.
- `fov`: field of view.
- `speaker` / `line`: optional subtitle pair.

## Control Mapping Expectations

- Continue dialogue: `Enter`, gamepad `A`, or primary fire action.
- Skip dialogue: `Esc`.
- Skip cutscene: `Esc`, gamepad `B`, or `Start`.
- Trigger NPC contact: `E`, gamepad `A`.

## Narrative Integration Notes

- Narrative pacing should never hard-lock combat flow if a contact is missed.
- Contacts can be triggered by NPC overlap or mission-script queueing.
- Chapter titles are propagated via `GameState.story_chapter_changed` for HUD display.
- Cutscene subtitle lines are mirrored into the HUD event feed for readability.
