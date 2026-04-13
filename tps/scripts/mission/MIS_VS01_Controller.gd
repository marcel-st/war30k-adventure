extends Node3D

@onready var extraction_zone: Area3D = $ExtractionZone
@onready var enemy_container: Node3D = $Enemies
@onready var story_systems: Node = $StorySystems
@onready var story_trigger_ch2: Area3D = $StoryCutsceneTrigger_CH2
@onready var story_trigger_ch3: Area3D = $StoryCutsceneTrigger_CH3

const TRAITOR_SCENE: PackedScene = preload("res://scenes/enemies/SCN_EnemyTraitorMarine.tscn")
const CULTIST_SCENE: PackedScene = preload("res://scenes/enemies/SCN_EnemyCultistRanged.tscn")
const CHAMPION_SCENE: PackedScene = preload("res://scenes/enemies/SCN_EnemyNurgleChampion.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/SCN_Boss_HarbingerOfRuin.tscn")

var _wave_index: int = 0
var _waves: Array[Dictionary] = [
	{
		"melee": 2,
		"ranged": 1,
		"elite": 0,
		"spawn_interval": 0.55,
		"objective": "Wave 1: break initial traitor push.",
		"events": [
			{"delay": 1.8, "type": "message", "text": "Vox: Traitor signal spike detected ahead."}
		]
	},
	{
		"melee": 3,
		"ranged": 2,
		"elite": 1,
		"spawn_interval": 0.45,
		"objective": "Wave 2: hold under suppressive fire.",
		"events": [
			{"delay": 2.0, "type": "reinforcement", "unit": "ranged", "count": 2, "interval": 0.35, "text": "Warning: cultist fireteam reinforcements inbound."},
			{"delay": 4.5, "type": "message", "text": "Warning: plague champion entering combat zone."}
		]
	}
]
var _active_enemies: Array[Node3D] = []
var _combat_completed: bool = false
var _is_spawning_wave: bool = false
var _encounter_token: int = 0
var _mission_failed: bool = false
var _can_restart: bool = false
var _restart_debounce: float = 0.0
var _chapter_triggered: Dictionary = {}
var _current_chapter_number: int = 1
var _spawn_markers: Array[Marker3D] = []
var _enemy_compact_timer: float = 0.0
var _boss_spawned: bool = false
var _active_mission_profile: Dictionary = {}
var _bonus_objective_active: bool = false
var _bonus_objective_completed: bool = false
var _adaptive_reinforcement_scale: float = 1.0
var _adaptive_spawn_interval_scale: float = 1.0
var _current_branch_choice: String = "default_path"
var _branch_consequence_library: Dictionary = {}
var _active_branch_consequence: Dictionary = {}
var _mission_mode: String = "assault"
var _sabotage_required_ticks: int = 0
var _sabotage_progress_ticks: int = 0
var _sabotage_active: bool = false
var _sabotage_completed: bool = false
var _sabotage_tick_timer: float = 0.0
var _sabotage_enemy_gate: int = 2
var _sabotage_radius: float = 4.2

const ENEMY_COMPACT_INTERVAL: float = 0.5

func _ready() -> void:
	GameState.reset_run()
	_refresh_player_group_tag()
	_cache_spawn_markers()
	extraction_zone.body_entered.connect(_on_extraction_body_entered)
	story_trigger_ch2.body_entered.connect(_on_story_trigger_body_entered.bind(2))
	story_trigger_ch3.body_entered.connect(_on_story_trigger_body_entered.bind(3))
	GameState.mission_state_changed.connect(_on_mission_state_changed)
	GameState.restart_requested.connect(_on_restart_requested)
	GameState.story_contact_requested.connect(_on_story_contact_requested)
	if GameState.has_signal("branch_choice_changed"):
		GameState.branch_choice_changed.connect(_on_branch_choice_changed)
	if story_systems and story_systems.has_method("bootstrap_story"):
		story_systems.bootstrap_story()
	if story_systems and story_systems.has_method("play_chapter_intro"):
		story_systems.play_chapter_intro(1)
	if story_systems and story_systems.has_method("request_contact"):
		story_systems.request_contact("ch1_contact_ignatius")
	_chapter_triggered[1] = true
	_setup_mission_profile()
	GameState.set_meta("mission_mode", _mission_mode)
	_apply_branch_choice("default_path")
	extraction_zone.monitoring = false
	GameState.configure_projectile_pool_container(get_node_or_null("ProjectileContainer"))
	_start_next_wave()

func _physics_process(_delta: float) -> void:
	if _restart_debounce > 0.0:
		_restart_debounce = maxf(0.0, _restart_debounce - _delta)
	if _can_restart and _restart_debounce <= 0.0:
		if Input.is_action_just_pressed("restart_mission"):
			get_tree().reload_current_scene()
			return
	if _mission_failed:
		return
	_enemy_compact_timer = maxf(0.0, _enemy_compact_timer - _delta)
	if _enemy_compact_timer <= 0.0:
		_enemy_compact_timer = ENEMY_COMPACT_INTERVAL
		_compact_active_enemies()
	if _active_enemies.is_empty() and not _combat_completed and not _is_spawning_wave:
		_start_next_wave()
	_process_sabotage_objective(_delta)

func _on_extraction_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_finish_optional_objectives()
		if story_systems and story_systems.has_method("play_chapter_intro"):
			if _current_chapter_number < 4:
				_current_chapter_number = 4
				story_systems.play_chapter_intro(4)
		if story_systems and story_systems.has_method("request_contact"):
			story_systems.request_contact("ch4_contact_relay")
		GameState.complete_objective("Extraction reached. Loyalist warning secured.")
		_finalize_mission_rewards()
		GameState.set_mission_state("victory", "Extraction reached")
		_can_restart = true
		_restart_debounce = 0.25

func _refresh_player_group_tag() -> void:
	var player: Node3D = get_node_or_null("Player")
	if player and not player.is_in_group("player"):
		player.add_to_group("player")

func _start_next_wave() -> void:
	if _wave_index >= _waves.size():
		if not _boss_spawned:
			_spawn_boss_encounter()
			return
		_combat_completed = true
		GameState.set_enemies_remaining(0)
		GameState.set_objective("Combat lane secured. Move to extraction zone.")
		GameState.push_event_message("Combat lane secured. Extraction corridor now open.")
		GameState.set_mission_state("extract")
		extraction_zone.monitoring = true
		return

	var wave_data: Dictionary = _waves[_wave_index].duplicate(true)
	var melee_count: int = int(wave_data.get("melee", 0))
	var ranged_count: int = int(wave_data.get("ranged", 0))
	var elite_count: int = int(wave_data.get("elite", 0))
	var spawn_interval: float = float(wave_data.get("spawn_interval", 0.5))
	melee_count = int(round(float(melee_count) * _adaptive_reinforcement_scale))
	ranged_count = int(round(float(ranged_count) * _adaptive_reinforcement_scale))
	elite_count = int(round(float(elite_count) * _adaptive_reinforcement_scale))
	if not _active_branch_consequence.is_empty():
		melee_count += int(_active_branch_consequence.get("bonus_melee", 0))
		ranged_count += int(_active_branch_consequence.get("bonus_ranged", 0))
		elite_count += int(_active_branch_consequence.get("bonus_elite", 0))
	spawn_interval *= _adaptive_spawn_interval_scale
	var total_count: int = melee_count + ranged_count + elite_count
	var objective_text: String = str(wave_data.get("objective", "Eliminate all enemies in wave %d." % (_wave_index + 1)))
	if _mission_mode == "sabotage" and _wave_index == _waves.size() - 1:
		objective_text = "Sabotage relay uplink while holding off traitor counterfire."
	GameState.set_objective("%s (%d/%d)" % [objective_text, _wave_index + 1, _waves.size()])
	GameState.set_wave_progress(_wave_index + 1, _waves.size())
	GameState.set_enemies_remaining(total_count)
	GameState.push_event_message("Wave %d started: %d hostiles." % [_wave_index + 1, total_count])
	if EventBus:
		EventBus.emit_event("mission.wave_started", {"wave": _wave_index + 1, "hostiles": total_count})
	if story_systems and story_systems.has_method("request_contact"):
		if _wave_index == 0:
			story_systems.request_contact("ch1_contact_macer")
		elif _wave_index == 1:
			if _current_chapter_number < 2:
				_current_chapter_number = 2
				if story_systems and story_systems.has_method("play_chapter_intro"):
					story_systems.play_chapter_intro(2)
			story_systems.request_contact("ch2_contact_hest")
	if _active_branch_consequence.has("event_message"):
		GameState.push_event_message(str(_active_branch_consequence.get("event_message", "")))
	_is_spawning_wave = true
	await _spawn_wave_units(melee_count, ranged_count, elite_count, spawn_interval)
	_is_spawning_wave = false
	_start_wave_events(wave_data)
	_wave_index += 1
	if _mission_mode == "sabotage" and _wave_index >= _waves.size():
		_activate_sabotage_phase()

func _spawn_wave_units(melee_count: int, ranged_count: int, elite_count: int, interval: float) -> void:
	var spawn_order: Array[PackedScene] = []
	for _i in range(melee_count):
		spawn_order.append(TRAITOR_SCENE)
	for _j in range(ranged_count):
		spawn_order.append(CULTIST_SCENE)
	for _k in range(elite_count):
		spawn_order.append(CHAMPION_SCENE)
	spawn_order.shuffle()
	for spawn_index in range(spawn_order.size()):
		var spawn_scene: PackedScene = spawn_order[spawn_index]
		var spawn_position: Vector3 = _pick_spawn_position(spawn_index)
		_spawn_unit(spawn_scene, spawn_position)
		if spawn_index < spawn_order.size() - 1:
			var timer: SceneTreeTimer = get_tree().create_timer(maxf(0.05, interval))
			await timer.timeout

func _spawn_unit(spawn_scene: PackedScene, spawn_position: Vector3) -> void:
	var enemy: Node3D = spawn_scene.instantiate()
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))
	if enemy.has_method("set_target_player"):
		enemy.set_target_player(get_node_or_null("Player"))
	enemy_container.add_child(enemy)
	enemy.global_position = spawn_position
	_active_enemies.append(enemy)
	enemy.add_to_group("enemy")
	GameState.set_enemies_remaining(_active_enemies.size())

func _start_wave_events(wave_data: Dictionary) -> void:
	var events_variant: Variant = wave_data.get("events", [])
	if not (events_variant is Array):
		return
	_encounter_token += 1
	var event_token: int = _encounter_token
	var events_array: Array = events_variant as Array
	for event_item in events_array:
		if event_item is Dictionary:
			_run_wave_event(event_item as Dictionary, event_token)

func _run_wave_event(event_data: Dictionary, event_token: int) -> void:
	var delay: float = float(event_data.get("delay", 0.0))
	var timer: SceneTreeTimer = get_tree().create_timer(maxf(0.0, delay))
	timer.timeout.connect(func() -> void:
		if event_token != _encounter_token or _combat_completed:
			return
		var event_type: String = str(event_data.get("type", "message"))
		var text: String = str(event_data.get("text", ""))
		if event_type == "reinforcement":
			var count: int = int(event_data.get("count", 1))
			var interval: float = float(event_data.get("interval", 0.3))
			var unit_name: String = str(event_data.get("unit", "ranged"))
			if text != "":
				GameState.push_event_message(text)
			_spawn_reinforcement_group(unit_name, count, interval, event_token)
			return
		if text != "":
			GameState.push_event_message(text)
	)

func _spawn_reinforcement_group(unit_name: String, count: int, interval: float, event_token: int) -> void:
	var scene: PackedScene = CULTIST_SCENE
	match unit_name:
		"melee":
			scene = TRAITOR_SCENE
		"elite":
			scene = CHAMPION_SCENE
		_:
			scene = CULTIST_SCENE
	for idx in range(maxi(1, count)):
		var timer: SceneTreeTimer = get_tree().create_timer(maxf(0.0, interval * float(idx)))
		timer.timeout.connect(func() -> void:
			if event_token != _encounter_token or _combat_completed:
				return
			var spawn_pos: Vector3 = _pick_spawn_position(idx + 100)
			_spawn_unit(scene, spawn_pos)
			GameState.set_enemies_remaining(_active_enemies.size())
		)

func _pick_spawn_position(index: int) -> Vector3:
	if _spawn_markers.is_empty():
		_cache_spawn_markers()
	if _spawn_markers.is_empty():
		return Vector3(0.0, 1.1, -10.0 - float(index) * 2.5)
	var marker_index: int = index % _spawn_markers.size()
	var marker: Marker3D = _spawn_markers[marker_index]
	if marker:
		return marker.global_position
	return Vector3(0.0, 1.1, -10.0 - float(index) * 2.5)

func _compact_active_enemies() -> void:
	var survivors: Array[Node3D] = []
	for enemy in _active_enemies:
		if is_instance_valid(enemy):
			survivors.append(enemy)
	if survivors.size() == _active_enemies.size():
		return
	_active_enemies = survivors
	GameState.set_enemies_remaining(_active_enemies.size())

func _cache_spawn_markers() -> void:
	_spawn_markers.clear()
	var marker_nodes: Array[Node] = get_tree().get_nodes_in_group("enemy_spawn")
	for marker_node in marker_nodes:
		if marker_node is Marker3D:
			_spawn_markers.append(marker_node as Marker3D)

func _spawn_boss_encounter() -> void:
	_boss_spawned = true
	GameState.push_event_message("Boss contact: Harbinger of Ruin enters the field.")
	GameState.set_objective("Defeat the Harbinger and secure extraction.")
	var spawn_position: Vector3 = _pick_spawn_position(999)
	var boss_node: Node3D = BOSS_SCENE.instantiate()
	if boss_node.has_method("set_target_player"):
		boss_node.set_target_player(get_node_or_null("Player"))
	enemy_container.add_child(boss_node)
	boss_node.global_position = spawn_position + Vector3(0.0, 0.0, -3.0)
	_active_enemies.append(boss_node)
	boss_node.add_to_group("enemy")
	GameState.set_enemies_remaining(_active_enemies.size())
	if boss_node.has_signal("counter_window_opened"):
		boss_node.counter_window_opened.connect(_on_boss_counter_window_opened)
	if boss_node.has_signal("counter_window_closed"):
		boss_node.counter_window_closed.connect(_on_boss_counter_window_closed)
	boss_node.tree_exited.connect(_on_enemy_tree_exited.bind(boss_node))

func _on_enemy_tree_exited(enemy: Node3D) -> void:
	_active_enemies.erase(enemy)
	GameState.set_enemies_remaining(_active_enemies.size())
	_update_adaptive_director()

func _on_mission_state_changed(new_state: String) -> void:
	if new_state == "failed":
		_mission_failed = true
		_can_restart = true
		_restart_debounce = 0.25
		_encounter_token += 1
		extraction_zone.monitoring = false
		_sabotage_active = false

func _on_story_trigger_body_entered(body: Node, chapter_number: int) -> void:
	if not body.is_in_group("player"):
		return
	if _chapter_triggered.get(chapter_number, false):
		return
	_chapter_triggered[chapter_number] = true
	if chapter_number > _current_chapter_number:
		_current_chapter_number = chapter_number
	if story_systems and story_systems.has_method("play_chapter_intro"):
		story_systems.play_chapter_intro(chapter_number)
	if story_systems and story_systems.has_method("request_contact"):
		match chapter_number:
			2:
				story_systems.request_contact("ch2_contact_hest")
			3:
				story_systems.request_contact("ch3_contact_luna_vox")
			4:
				story_systems.request_contact("ch4_contact_malcador")

func _on_restart_requested() -> void:
	if _can_restart and _restart_debounce <= 0.0:
		get_tree().reload_current_scene()

func _on_story_contact_requested(contact_id: String) -> void:
	if story_systems and story_systems.has_method("request_contact"):
		story_systems.request_contact(contact_id)

func _setup_mission_profile() -> void:
	if not GameState.has_method("get_mission_profile"):
		return
	var profile: Dictionary = GameState.get_mission_profile("vs01")
	if profile.is_empty():
		return
	_active_mission_profile = profile
	var adaptive_variant: Variant = profile.get("adaptive_director", {})
	if not (adaptive_variant is Dictionary):
		adaptive_variant = profile.get("adaptive_rules", {})
	if adaptive_variant is Dictionary:
		var adaptive_dict: Dictionary = adaptive_variant as Dictionary
		_adaptive_reinforcement_scale = clampf(float(adaptive_dict.get("base_reinforcement_scale", 1.0)), 0.8, 1.4)
		_adaptive_spawn_interval_scale = clampf(float(adaptive_dict.get("base_spawn_interval_scale", 1.0)), 0.65, 1.3)
	var branch_variant: Variant = profile.get("branch_consequences", {})
	if branch_variant is Dictionary:
		var branch_dict: Dictionary = branch_variant as Dictionary
		var tone_variant: Variant = branch_dict.get("ops_tone", {})
		if tone_variant is Dictionary:
			_branch_consequence_library = tone_variant as Dictionary
	var optional_variant: Variant = profile.get("optional_objectives", [])
	if optional_variant is Array and not (optional_variant as Array).is_empty():
		_bonus_objective_active = true
		_bonus_objective_completed = false
		GameState.push_event_message("Optional objective active: complete run with no deaths.")
	var mission_modes_variant: Variant = profile.get("mission_modes", [])
	if mission_modes_variant is Array:
		var mission_modes: Array = mission_modes_variant as Array
		if mission_modes.has("sabotage"):
			_mission_mode = "sabotage"
	var sabotage_variant: Variant = profile.get("sabotage_objective", {})
	if sabotage_variant is Dictionary:
		var sabotage_dict: Dictionary = sabotage_variant as Dictionary
		_sabotage_required_ticks = maxi(4, int(sabotage_dict.get("required_ticks", 8)))
		_sabotage_enemy_gate = maxi(1, int(sabotage_dict.get("enemy_gate", 2)))
		_sabotage_radius = maxf(2.0, float(sabotage_dict.get("radius", 4.2)))

func _finish_optional_objectives() -> void:
	if not _bonus_objective_active or _bonus_objective_completed:
		return
	if GameState.mission_state == "failed":
		GameState.push_event_message("Optional objective failed.")
		return
	_bonus_objective_completed = true
	if GameState.has_method("grant_progression_reward"):
		GameState.grant_progression_reward("objective_optional")
	GameState.push_event_message("Optional objective complete: bonus requisition awarded.")

func _update_adaptive_director() -> void:
	if _active_mission_profile.is_empty():
		return
	var enemy_pressure: float = clampf(float(_active_enemies.size()) / 10.0, 0.0, 1.0)
	var player_health_ratio: float = clampf(GameState.health / GameState.MAX_HEALTH, 0.0, 1.0)
	var pressure_target: float = 0.45 + enemy_pressure * 0.45
	if player_health_ratio < 0.35:
		pressure_target -= 0.18
	elif player_health_ratio > 0.8:
		pressure_target += 0.08
	_adaptive_reinforcement_scale = clampf(0.9 + pressure_target * 0.5, 0.75, 1.35)
	_adaptive_spawn_interval_scale = clampf(1.08 - pressure_target * 0.32, 0.7, 1.2)

func _on_branch_choice_changed(branch_id: String, choice_id: String) -> void:
	if branch_id == "":
		return
	if branch_id == "relay_decision" or branch_id == "ch3_tactic":
		_apply_branch_choice(choice_id)

func _apply_branch_choice(choice_id: String) -> void:
	if choice_id == "":
		return
	_current_branch_choice = choice_id
	_active_branch_consequence.clear()
	if _branch_consequence_library.has(choice_id):
		var consequence_variant: Variant = _branch_consequence_library.get(choice_id, {})
		if consequence_variant is Dictionary:
			_active_branch_consequence = consequence_variant as Dictionary
	if EventBus:
		EventBus.emit_event("mission.branch_choice_applied", {"choice_id": choice_id})
	match choice_id:
		"secure_relay":
			_adaptive_spawn_interval_scale = minf(_adaptive_spawn_interval_scale * 0.92, 1.05)
			_sabotage_required_ticks = maxi(4, _sabotage_required_ticks - 1)
		"breach_aggressive":
			_adaptive_reinforcement_scale = minf(_adaptive_reinforcement_scale * 1.14, 1.35)
		"hold_the_line":
			_adaptive_spawn_interval_scale = maxf(_adaptive_spawn_interval_scale * 1.04, 0.78)
		_:
			pass

func _on_boss_counter_window_opened(window_name: String) -> void:
	GameState.push_event_message("Counter window: %s exposed. Focus fire!" % window_name.capitalize())

func _on_boss_counter_window_closed(window_name: String, was_exploited: bool) -> void:
	if was_exploited:
		GameState.push_event_message("Counter successful: %s disrupted." % window_name.capitalize())
	else:
		GameState.push_event_message("Counter missed: %s attack completed." % window_name.capitalize())

func _activate_sabotage_phase() -> void:
	if _sabotage_completed or _sabotage_active:
		return
	_sabotage_active = true
	_sabotage_tick_timer = 1.0
	_sabotage_progress_ticks = 0
	GameState.push_event_message("Relay sabotage initiated. Stay on uplink while keeping hostiles down.")
	GameState.set_objective("Sabotage uplink progress %d/%d" % [_sabotage_progress_ticks, _sabotage_required_ticks])

func _process_sabotage_objective(delta: float) -> void:
	if not _sabotage_active or _sabotage_completed:
		return
	if _mission_failed or GameState.mission_state == "failed":
		return
	var player: Node3D = get_node_or_null("Player")
	if player == null:
		return
	_sabotage_tick_timer = maxf(0.0, _sabotage_tick_timer - delta)
	if _sabotage_tick_timer > 0.0:
		return
	_sabotage_tick_timer = 1.0
	if _active_enemies.size() > _sabotage_enemy_gate:
		GameState.push_event_message("Uplink disrupted by enemy pressure. Clear nearby traitors.")
		return
	var relay_anchor: Vector3 = extraction_zone.global_position
	var in_range: bool = player.global_position.distance_to(relay_anchor) <= _sabotage_radius
	if not in_range:
		GameState.push_event_message("Move to relay zone to continue sabotage.")
		return
	_sabotage_progress_ticks += 1
	GameState.set_objective("Sabotage uplink progress %d/%d" % [_sabotage_progress_ticks, _sabotage_required_ticks])
	if _sabotage_progress_ticks >= _sabotage_required_ticks:
		_sabotage_completed = true
		_sabotage_active = false
		GameState.push_event_message("Relay sabotage complete. Extraction corridor stabilized.")
		if not _boss_spawned:
			_spawn_boss_encounter()

func _finalize_mission_rewards() -> void:
	var progression: Node = GameState.get_node_or_null("Progression")
	if progression and progression.has_method("award_mission"):
		progression.award_mission(true, _bonus_objective_completed)
	GameState.gain_progression(90, 60)
