extends Node

@export var weapon_profiles_path: String = "res://data/combat/weapon_profiles.json"
@export var squad_profiles_path: String = "res://data/ai/squad_profiles.json"
@export var ability_profiles_path: String = "res://data/abilities/ability_profiles.json"
@export var objective_profiles_path: String = "res://data/missions/objective_profiles.json"
@export var progression_profiles_path: String = "res://data/progression/progression_profiles.json"
@export var boss_profiles_path: String = "res://data/bosses/boss_profiles.json"
@export var settings_defaults_path: String = "res://data/ux/settings_defaults.json"
@export var qa_matrix_path: String = "res://data/qa/test_matrix.json"

var _cache: Dictionary = {}

func get_weapon_profile(profile_id: String) -> Dictionary:
	return _get_entry(weapon_profiles_path, "weapon_profiles", "id", profile_id)

func get_squad_profile(profile_id: String) -> Dictionary:
	return _get_entry(squad_profiles_path, "squad_profiles", "id", profile_id)

func get_ability_profile(profile_id: String) -> Dictionary:
	return _get_entry(ability_profiles_path, "abilities", "id", profile_id)

func get_objective_profile(profile_id: String) -> Dictionary:
	return _get_entry(objective_profiles_path, "objective_profiles", "id", profile_id)

func get_progression_profile(profile_id: String) -> Dictionary:
	return _get_entry(progression_profiles_path, "progression_profiles", "id", profile_id)

func get_boss_profile(profile_id: String) -> Dictionary:
	return _get_entry(boss_profiles_path, "boss_profiles", "id", profile_id)

func get_settings_defaults() -> Dictionary:
	return _load_json(settings_defaults_path)

func get_qa_matrix() -> Dictionary:
	return _load_json(qa_matrix_path)

func _get_entry(path: String, array_key: String, id_key: String, wanted_id: String) -> Dictionary:
	if wanted_id == "":
		return {}
	var data: Dictionary = _load_json(path)
	var list_variant: Variant = data.get(array_key, [])
	if not (list_variant is Array):
		return {}
	for entry_variant in list_variant as Array:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant as Dictionary
		if str(entry.get(id_key, "")) == wanted_id:
			return entry
	return {}

func _load_json(path: String) -> Dictionary:
	if _cache.has(path):
		return _cache[path]
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var data: Dictionary = parsed as Dictionary
		_cache[path] = data
		return data
	return {}
