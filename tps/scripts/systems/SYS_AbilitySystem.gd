extends Node

signal ability_triggered(ability_id: String)
signal ability_cooldown_changed(ability_id: String, remaining: float, total: float)

@export var ability_data_path: String = "res://data/abilities/ability_profiles.json"

var _profiles: Dictionary = {}
var _cooldowns: Dictionary = {}
var _owner: Node = null
var _active_effect_timers: Dictionary = {}

func _ready() -> void:
	_load_profiles()

func bind_owner(owner: Node) -> void:
	_owner = owner

func set_player(player: Node) -> void:
	bind_owner(player)

func _physics_process(delta: float) -> void:
	if not _cooldowns.is_empty():
		var ids: Array = _cooldowns.keys()
		for ability_id_variant in ids:
			var ability_id: String = str(ability_id_variant)
			var remaining: float = float(_cooldowns.get(ability_id, 0.0))
			if remaining <= 0.0:
				continue
			remaining = maxf(0.0, remaining - delta)
			_cooldowns[ability_id] = remaining
			var profile: Dictionary = _profiles.get(ability_id, {}) as Dictionary
			emit_signal("ability_cooldown_changed", ability_id, remaining, float(profile.get("cooldown", 0.0)))
	if not _active_effect_timers.is_empty():
		var effect_ids: Array = _active_effect_timers.keys()
		for effect_id_variant in effect_ids:
			var effect_id: String = str(effect_id_variant)
			var effect_remaining: float = float(_active_effect_timers.get(effect_id, 0.0))
			if effect_remaining <= 0.0:
				continue
			effect_remaining = maxf(0.0, effect_remaining - delta)
			_active_effect_timers[effect_id] = effect_remaining
	if GameState:
		GameState.tick_ability_cooldowns(delta)

func trigger_ability(ability_id: String) -> bool:
	if not _profiles.has(ability_id):
		return false
	var remaining: float = float(_cooldowns.get(ability_id, 0.0))
	if remaining > 0.0:
		return false
	var profile: Dictionary = _profiles[ability_id] as Dictionary
	var cooldown: float = float(profile.get("cooldown", 0.0))
	var progression: Node = GameState.get_node_or_null("Progression")
	if progression and progression.has_method("get_ability_cooldown_scale"):
		cooldown *= float(progression.get_ability_cooldown_scale())
	_cooldowns[ability_id] = cooldown
	var effect: Dictionary = profile.get("effect", {}) as Dictionary
	_active_effect_timers[ability_id] = float(effect.get("duration", 0.0))
	_apply_effect(profile)
	emit_signal("ability_triggered", ability_id)
	var cooldown_display_total: float = float(profile.get("cooldown", cooldown))
	emit_signal("ability_cooldown_changed", ability_id, cooldown, cooldown_display_total)
	if GameState:
		GameState.ability_cooldowns[ability_id] = cooldown
		GameState.emit_signal("ability_cooldowns_changed", GameState.ability_cooldowns.duplicate(true))
	if GameState:
		GameState.push_event_message("Ability used: %s" % str(profile.get("name", ability_id)))
	if EventBus:
		EventBus.emit_event("ability_triggered", {"ability_id": ability_id})
	return true

func get_cooldown_remaining(ability_id: String) -> float:
	return float(_cooldowns.get(ability_id, 0.0))

func get_move_speed_multiplier() -> float:
	if _active_effect_timers.is_empty():
		return 1.0
	var surge_remaining: float = float(_active_effect_timers.get("resilience_surge", 0.0))
	if surge_remaining > 0.0:
		return 1.08
	var rally_remaining: float = float(_active_effect_timers.get("rally_command", 0.0))
	if rally_remaining > 0.0:
		return 1.04
	return 1.0

func _apply_effect(profile: Dictionary) -> void:
	var effect: Dictionary = profile.get("effect", {}) as Dictionary
	if _owner == null:
		return
	var effect_type: String = str(effect.get("type", ""))
	match effect_type:
		"damage_reduction":
			if _owner.has_method("apply_temporary_damage_reduction"):
				_owner.apply_temporary_damage_reduction(
					float(effect.get("ratio", 0.2)),
					float(effect.get("duration", 3.0)),
					float(effect.get("hazard_resist_ratio", 0.0))
				)
		"aoe_dot":
			if _owner.has_method("spawn_toxic_grenade"):
				_owner.spawn_toxic_grenade(float(effect.get("radius", 4.5)), float(effect.get("damage_per_tick", 3.0)), float(effect.get("duration", 5.0)))
		"self_buff":
			if _owner.has_method("apply_temporary_move_buff"):
				_owner.apply_temporary_move_buff(float(effect.get("move_speed_bonus", 0.2)), float(effect.get("duration", 4.0)))
		_:
			pass

func _load_profiles() -> void:
	_profiles.clear()
	_cooldowns.clear()
	_active_effect_timers.clear()
	if not FileAccess.file_exists(ability_data_path):
		return
	var file: FileAccess = FileAccess.open(ability_data_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	var profile_list: Variant = (parsed as Dictionary).get("abilities", [])
	if not (profile_list is Array):
		return
	for profile_variant in profile_list as Array:
		if not (profile_variant is Dictionary):
			continue
		var profile: Dictionary = profile_variant as Dictionary
		var ability_id: String = str(profile.get("ability_id", ""))
		if ability_id == "":
			continue
		_profiles[ability_id] = profile
		_cooldowns[ability_id] = 0.0
		_active_effect_timers[ability_id] = 0.0
