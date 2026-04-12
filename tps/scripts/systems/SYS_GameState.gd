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
signal ability_cooldowns_changed(values: Dictionary)
signal progression_changed(level: int, xp: int, requisition: int)
signal chapter_reward_unlocked(chapter_id: String, reward_id: String)
signal wave_skip_requested()
signal chapter_cycle_requested()
signal branch_choice_changed(branch_id: String, choice_id: String)

const MAX_HEALTH := 100.0
const MAX_ARMOR := 100.0
const MAX_ABILITY_SLOTS := 3

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
var player_level: int = 1
var player_xp: int = 0
var player_requisition: int = 0
var unlocked_weapon_mods: Dictionary = {}
var unlocked_perks: Dictionary = {}
var chapter_rewards: Dictionary = {}
var ability_cooldowns: Dictionary = {
	"resilience_surge": 0.0,
	"toxic_grenade": 0.0,
	"rally_command": 0.0
}
var ability_order: Array[String] = ["resilience_surge", "toxic_grenade", "rally_command"]
var commander_controller: Node = null
var branch_choices: Dictionary = {}

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
	branch_choices.clear()
	player_level = max(1, player_level)
	_reset_ability_cooldowns()
	emit_player_stats()
	emit_signal("objective_changed", objective_text, objective_completed)
	emit_signal("enemies_remaining_changed", enemies_remaining)
	emit_signal("wave_changed", current_wave, total_waves)
	emit_signal("event_feed_changed", event_feed_text)
	emit_signal("mission_state_changed", mission_state, mission_state_reason)
	emit_signal("run_state_changed", mission_state)
	emit_signal("story_chapter_changed", story_chapter_id, story_chapter_title)
	emit_signal("progression_changed", player_level, player_xp, player_requisition)
	emit_signal("ability_cooldowns_changed", ability_cooldowns.duplicate(true))

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

func request_wave_skip() -> void:
	emit_signal("wave_skip_requested")

func request_cycle_chapter() -> void:
	emit_signal("chapter_cycle_requested")

func start_contact_moment(contact_id: String) -> void:
	if contact_id == "":
		return
	emit_signal("story_contact_requested", contact_id)

func gain_progression(xp_delta: int, requisition_delta: int) -> void:
	player_xp = maxi(0, player_xp + xp_delta)
	player_requisition = maxi(0, player_requisition + requisition_delta)
	var threshold: int = _xp_threshold_for_level(player_level)
	while player_xp >= threshold:
		player_xp -= threshold
		player_level += 1
		push_event_message("Level up achieved: %d" % player_level)
		threshold = _xp_threshold_for_level(player_level)
	emit_signal("progression_changed", player_level, player_xp, player_requisition)

func unlock_chapter_reward(chapter_id: String, reward_id: String) -> void:
	if chapter_id == "" or reward_id == "":
		return
	if not chapter_rewards.has(chapter_id):
		chapter_rewards[chapter_id] = {}
	var chapter_dict: Dictionary = chapter_rewards[chapter_id] as Dictionary
	if chapter_dict.has(reward_id):
		return
	chapter_dict[reward_id] = true
	chapter_rewards[chapter_id] = chapter_dict
	emit_signal("chapter_reward_unlocked", chapter_id, reward_id)

func trigger_ability(ability_id: String) -> bool:
	if ability_id == "":
		return false
	var ability_system: Node = get_node_or_null("AbilitySystem")
	if ability_system and ability_system.has_method("trigger_ability"):
		return bool(ability_system.trigger_ability(ability_id))
	if not ability_cooldowns.has(ability_id):
		return false
	if float(ability_cooldowns[ability_id]) > 0.0:
		return false
	ability_cooldowns[ability_id] = 12.0
	emit_signal("ability_cooldowns_changed", ability_cooldowns.duplicate(true))
	return true

func tick_ability_cooldowns(delta: float) -> void:
	if delta <= 0.0:
		return
	var changed: bool = false
	for key in ability_cooldowns.keys():
		var current: float = float(ability_cooldowns[key])
		if current <= 0.0:
			continue
		var next_value: float = maxf(0.0, current - delta)
		if next_value != current:
			ability_cooldowns[key] = next_value
			changed = true
	if changed:
		emit_signal("ability_cooldowns_changed", ability_cooldowns.duplicate(true))

func set_ability_player(player: Node) -> void:
	var ability_system: Node = get_node_or_null("AbilitySystem")
	if ability_system and ability_system.has_method("set_player"):
		ability_system.set_player(player)

func get_ability_move_speed_multiplier() -> float:
	var ability_system: Node = get_node_or_null("AbilitySystem")
	if ability_system and ability_system.has_method("get_move_speed_multiplier"):
		return float(ability_system.get_move_speed_multiplier())
	return 1.0

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
	_ensure_action("ability_primary", [
		_key_event(KEY_Q),
		_joy_button_event(JOY_BUTTON_X)
	])
	_ensure_action("ability_secondary", [
		_key_event(KEY_F),
		_joy_button_event(JOY_BUTTON_DPAD_UP)
	])
	_ensure_action("ability_tertiary", [
		_key_event(KEY_C),
		_joy_button_event(JOY_BUTTON_DPAD_RIGHT)
	])
	_ensure_action("quick_save", [
		_key_event(KEY_F5),
		_joy_button_event(JOY_BUTTON_DPAD_LEFT)
	])
	_ensure_action("quick_load", [
		_key_event(KEY_F9),
		_joy_button_event(JOY_BUTTON_DPAD_DOWN)
	])
	_ensure_action("debug_toggle_god_mode", [_key_event(KEY_F1)])
	_ensure_action("debug_toggle_infinite_ammo", [_key_event(KEY_F2)])
	_ensure_action("debug_skip_wave", [_key_event(KEY_F3)])
	_ensure_action("debug_cycle_chapter", [_key_event(KEY_F4)])

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

func _xp_threshold_for_level(level: int) -> int:
	return 120 + maxi(1, level) * 40

func _reset_ability_cooldowns() -> void:
	for ability in ability_order:
		ability_cooldowns[ability] = 0.0

func get_mission_profile(profile_id: String) -> Dictionary:
	var combat_data: Node = get_node_or_null("CombatData")
	if combat_data and combat_data.has_method("get_mission_profile"):
		return combat_data.get_mission_profile(profile_id)
	return {}

func set_branch_choice(branch_id: String, choice_id: String) -> void:
	if branch_id == "" or choice_id == "":
		return
	branch_choices[branch_id] = choice_id
	emit_signal("branch_choice_changed", branch_id, choice_id)

func get_branch_choice(branch_id: String, fallback: String = "") -> String:
	if branch_choices.has(branch_id):
		return str(branch_choices[branch_id])
	return fallback

func get_all_branch_choices() -> Dictionary:
	return branch_choices.duplicate(true)

func get_profile_entry(domain: String, array_key: String, entry_id: String) -> Dictionary:
	if domain == "" or array_key == "" or entry_id == "":
		return {}
	if not has_node("CombatData"):
		return {}
	var combat_data: Node = get_node("CombatData")
	var method_name: String = "get_%s_profile" % domain.trim_suffix("s")
	if combat_data.has_method(method_name):
		return combat_data.call(method_name, entry_id)
	return {}

func grant_progression_reward(reward_key: String) -> void:
	match reward_key:
		"objective_optional":
			gain_progression(40, 30)
		"boss_defeated":
			gain_progression(120, 90)
		_:
			gain_progression(20, 10)

func get_enemy_role_profile(role_id: String) -> Dictionary:
	var combat_data: Node = get_node_or_null("CombatData")
	if combat_data == null or not combat_data.has_method("get_squad_profile"):
		return {}
	var squad_profile: Dictionary = combat_data.get_squad_profile("vs01_default")
	if squad_profile.is_empty():
		return {}
	var role_map: Dictionary = squad_profile.get("traitor_roles", {})
	if role_map.is_empty():
		return {}
	if role_map.has(role_id):
		var role_entry: Variant = role_map[role_id]
		if role_entry is Dictionary:
			return role_entry as Dictionary
	return {}

func register_elite_controller(elite_node: Node) -> void:
	if elite_node and elite_node.is_in_group("traitor_commander"):
		return
	if elite_node and elite_node.has_method("add_to_group"):
		elite_node.add_to_group("traitor_commander")

func clear_elite_controller(elite_node: Node) -> void:
	if elite_node and elite_node.has_method("remove_from_group"):
		elite_node.remove_from_group("traitor_commander")

func release_enemy_projectile(projectile: Node) -> void:
	var projectile_pool: Node = get_node_or_null("ProjectilePool")
	if projectile_pool and projectile_pool.has_method("recycle_enemy_projectile"):
		projectile_pool.recycle_enemy_projectile(projectile)
	else:
		projectile.queue_free()

func configure_projectile_pool_container(container: Node3D) -> void:
	var projectile_pool: Node = get_node_or_null("ProjectilePool")
	if projectile_pool and projectile_pool.has_method("configure_container"):
		projectile_pool.configure_container(container)
