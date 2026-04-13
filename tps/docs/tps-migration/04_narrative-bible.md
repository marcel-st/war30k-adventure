# Narrative Bible - Loyalist Death Guard Arc (Runtime State)

## Narrative Pillars

- **Tone**: stoic, attritional, operationally focused.
- **Perspective**: loyalist Death Guard command element after Isstvan betrayal.
- **Loop**: chapter intro -> in-mission contact moments -> combat pressure escalation -> extraction/transition.
- **Gameplay alignment**: narrative beats should reinforce tactical intent, never block core combat controls.

## Chapter Arc

### Chapter I - Drop Site Aftermath

- Establish corridor and stabilize command flow.
- Contact beats emphasize immediate survival doctrine.

### Chapter II - Warp Transit Crisis

- Relay integrity and sabotage response under increasing pressure.
- Introduces branching doctrine choice in dialogue (`relay_decision`).

### Chapter III - Blockade Breach

- Boarding pressure and breach stance escalation.
- Adds tactical branch choice (`ch3_tactic`) that feeds mission composition.

### Chapter IV - Terra Relay

- Final transmission push and resolution framing.
- Contact beats transition from tactical to strategic consequence.

## Runtime Data Schema

### Chapters (`tps/data/story/chapters/chapters.json`)

Each chapter entry includes:

- `chapter_id`
- `title`
- `summary`
- `intro_cutscene`
- `contacts_file`

### Contacts (`tps/data/story/dialogues/contacts_*.json`)

Per contact entry:

- `contact_id`
- `display_name`
- `title`
- `lines`
- `objective_update` (optional)
- `branch_id` / `branch_choices` (optional branch-defining contacts)

### Cutscenes (`tps/data/story/cutscenes/*.json`)

Per cutscene:

- `cutscene_id`
- `title`
- `allow_skip`
- `shots[]` with camera and subtitle data

Per shot:

- `duration`
- `camera_pos`
- `look_at`
- `fov`
- `speaker` / `line` (optional subtitle content)

## Branch Integration

Current branch-aware contacts:

- `ch2_contact_hest` -> branch `relay_decision`
- `ch3_contact_luna_vox` -> branch `ch3_tactic`

Branch selections propagate through `STY_StoryManager` into `GameState.set_branch_choice(...)`, then into mission logic (`MIS_VS01_Controller`) where they influence wave makeup and event messaging.

## Dialogue and Subtitle Style

- Keep lines concise and directive.
- Prefer concrete verbs (hold, breach, secure, transmit, endure).
- Avoid ornate language that dilutes tactical clarity.
- Ensure each beat carries actionable context or emotional consequence.

## Input/UX Expectations

- Continue dialogue: `Enter`, mouse-left, or gamepad `A`
- Skip/close dialogue: `Esc`, gamepad `B`/`Start`
- Skip cutscene: `Esc`, gamepad `B`/`Start`
- Trigger contact actors: `E`, gamepad `A`

## Integration Notes

- Narrative state is surfaced through `GameState.story_chapter_changed`.
- Contact objective updates are pushed into HUD/event feed.
- Missed optional contacts should not hard-fail mission progression.
- Branch choice events should always have a fallback/default mission path.
