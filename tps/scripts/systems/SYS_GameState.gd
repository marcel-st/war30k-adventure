extends Node

signal player_stats_changed(health: float, armor: float, magazine: int, reserve: int)
signal objective_changed(text: String, completed: bool)
signal enemies_remaining_changed(remaining: int)
signal wave_changed(current_wave: int, total_waves: int)
signal event_feed_changed(text: String)
signal mission_state_changed(state: String, reason: String)
signal run_state_changed(state: String)
signal story_chapter_changed(chapter_id: String, chapter_title: String)
signal restart_requested()
signal story_contact_requested(contact_id: String)

const MAX_HEALTH := 100.0
const MAX_ARMOR := 100.0

var health: float = MAX_HEALTH
var armor: float = MAX_ARMOR
var ammo_in_magazine: int = 30
var ammo_reserve: int = 120
var objective_text: String = "Reach extraction."
var objective_completed: bool = false
var enemies_remaining: int = 0
var current_wave: int = 0
var total_waves: int = 0
var encounter_event_text: String = ""
var event_feed_text: String = ""
var mission_state: String = "active"
var mission_state_reason: String = ""
var story_chapter_id: String = "ch1"
var story_chapter_title: String = "Drop Site Aftermath"

func _ready() -> void:
	_setup_default_input_actions()
	reset_run()

func reset_run() -> void:
	health = MAX_HEALTH
	armor = MAX_ARMOR
	objective_completed = false
	objective_text = "Push through traitor lines and reach extraction."
	enemies_remaining = 0
	current_wave = 0
	total_waves = 0
	encounter_event_text = ""
	event_feed_text = ""
	mission_state = "active"
	mission_state_reason = ""
	story_chapter_id = "ch1"
	story_chapter_title = "Drop Site Aftermath"
	emit_player_stats()
	emit_signal("objective_changed", objective_text, objective_completed)
	emit_signal("enemies_remaining_changed", enemies_remaining)
	emit_signal("wave_changed", current_wave, total_waves)
	emit_signal("event_feed_changed", event_feed_text)
	emit_signal("mission_state_changed", mission_state, mission_state_reason)
	emit_signal("run_state_changed", mission_state)
	emit_signal("story_chapter_changed", story_chapter_id, story_chapter_title)

func configure_ammo(magazine: int, reserve: int) -> void:
	ammo_in_magazine = maxi(0, magazine)
	ammo_reserve = maxi(0, reserve)
	emit_player_stats()

func can_fire() -> bool:
	return ammo_in_magazine > 0 and health > 0.0

func consume_round() -> bool:
	if not can_fire():
		return false
	ammo_in_magazine -= 1
	emit_player_stats()
	return true

func reload_magazine(max_magazine_size: int) -> bool:
	if max_magazine_size <= 0:
		return false
	if ammo_in_magazine >= max_magazine_size or ammo_reserve <= 0:
		return false
	var needed: int = max_magazine_size - ammo_in_magazine
	var moved: int = mini(needed, ammo_reserve)
	ammo_in_magazine += moved
	ammo_reserve -= moved
	emit_player_stats()
	return true

func damage_player(raw_damage: float) -> void:
	if raw_damage <= 0.0 or health <= 0.0:
		return
	var armor_absorb: float = minf(armor, raw_damage * 0.65)
	armor -= armor_absorb
	var health_damage: float = raw_damage - armor_absorb
	health = max(0.0, health - health_damage)
	emit_player_stats()
	if health <= 0.0:
		set_objective("Mission failed. Press Enter or gamepad Start to restart.")
		set_mission_state("failed", "Player eliminated")
		push_event_message("Brothers down. Extract and regroup.")

func set_objective(text: String) -> void:
	objective_text = text
	objective_completed = false
	emit_signal("objective_changed", objective_text, objective_completed)

func complete_objective(text: String) -> void:
	objective_text = text
	objective_completed = true
	emit_signal("objective_changed", objective_text, objective_completed)

func set_enemies_remaining(remaining: int) -> void:
	enemies_remaining = maxi(0, remaining)
	emit_signal("enemies_remaining_changed", enemies_remaining)

func set_wave_progress(current: int, total: int) -> void:
	current_wave = maxi(0, current)
	total_waves = maxi(0, total)
	emit_signal("wave_changed", current_wave, total_waves)

func set_encounter_event(text: String) -> void:
	encounter_event_text = text
	event_feed_text = text
	emit_signal("event_feed_changed", event_feed_text)

func push_event_message(text: String) -> void:
	set_encounter_event(text)

func set_mission_state(state: String, reason: String = "") -> void:
	mission_state = state
	mission_state_reason = reason
	emit_signal("mission_state_changed", mission_state, mission_state_reason)
	emit_signal("run_state_changed", mission_state)

func mark_mission_failed(reason: String = "Player eliminated") -> void:
	if mission_state == "failed":
		return
	set_objective("Mission failed. Press Enter or gamepad Start to restart.")
	set_mission_state("failed", reason)
	push_event_message("Brothers down. Extract and regroup.")

func set_story_chapter(chapter_id: String, chapter_title: String) -> void:
	story_chapter_id = chapter_id
	story_chapter_title = chapter_title
	emit_signal("story_chapter_changed", story_chapter_id, story_chapter_title)

func request_restart() -> void:
	emit_signal("restart_requested")

func start_contact_moment(contact_id: String) -> void:
	if contact_id == "":
		return
	emit_signal("story_contact_requested", contact_id)

func emit_player_stats() -> void:
	emit_signal("player_stats_changed", health, armor, ammo_in_magazine, ammo_reserve)

func _setup_default_input_actions() -> void:
	_ensure_action("move_forward", [
		_key_event(KEY_W),
		_key_event(KEY_UP),
		_joy_motion_event(JOY_AXIS_LEFT_Y, -1.0)
	])
	_ensure_action("move_backward", [
		_key_event(KEY_S),
		_key_event(KEY_DOWN),
		_joy_motion_event(JOY_AXIS_LEFT_Y, 1.0)
	])
	_ensure_action("move_left", [
		_key_event(KEY_A),
		_key_event(KEY_LEFT),
		_joy_motion_event(JOY_AXIS_LEFT_X, -1.0)
	])
	_ensure_action("move_right", [
		_key_event(KEY_D),
		_key_event(KEY_RIGHT),
		_joy_motion_event(JOY_AXIS_LEFT_X, 1.0)
	])
	_ensure_action("look_left", [_joy_motion_event(JOY_AXIS_RIGHT_X, -1.0)])
	_ensure_action("look_right", [_joy_motion_event(JOY_AXIS_RIGHT_X, 1.0)])
	_ensure_action("look_up", [_joy_motion_event(JOY_AXIS_RIGHT_Y, -1.0)])
	_ensure_action("look_down", [_joy_motion_event(JOY_AXIS_RIGHT_Y, 1.0)])
	_ensure_action("fire", [
		_mouse_button_event(MOUSE_BUTTON_LEFT),
		_joy_button_event(JOY_BUTTON_RIGHT_SHOULDER)
	])
	_ensure_action("aim", [
		_mouse_button_event(MOUSE_BUTTON_RIGHT),
		_joy_button_event(JOY_BUTTON_LEFT_SHOULDER)
	])
	_ensure_action("reload", [
		_key_event(KEY_R),
		_joy_button_event(JOY_BUTTON_Y)
	])
	_ensure_action("restart_mission", [
		_key_event(KEY_ENTER),
		_key_event(KEY_KP_ENTER),
		_key_event(KEY_R),
		_joy_button_event(JOY_BUTTON_START),
		_joy_button_event(JOY_BUTTON_BACK)
	])
	_ensure_action("sprint", [
		_key_event(KEY_SHIFT),
		_joy_button_event(JOY_BUTTON_LEFT_STICK)
	])
	_ensure_action("pause", [_key_event(KEY_ESCAPE)])
	_ensure_action("interact", [
		_key_event(KEY_E),
		_joy_button_event(JOY_BUTTON_A)
	])
	_ensure_action("dialogue_continue", [
		_key_event(KEY_ENTER),
		_key_event(KEY_KP_ENTER),
		_mouse_button_event(MOUSE_BUTTON_LEFT),
		_joy_button_event(JOY_BUTTON_A)
	])
	_ensure_action("skip_cutscene", [
		_key_event(KEY_ESCAPE),
		_joy_button_event(JOY_BUTTON_B),
		_joy_button_event(JOY_BUTTON_START)
	])

func _ensure_action(action_name: String, events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var existing_events: Array[InputEvent] = InputMap.action_get_events(action_name)
	if existing_events.is_empty():
		for event in events:
			InputMap.action_add_event(action_name, event)

func _key_event(keycode: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	return ev

func _mouse_button_event(button_index: MouseButton) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = button_index
	return ev

func _joy_button_event(button_index: JoyButton) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button_index
	return ev

func _joy_motion_event(axis: JoyAxis, axis_value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = axis_value
	return ev
