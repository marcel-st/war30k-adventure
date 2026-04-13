extends Node

@export var weapon_profiles_path: String = "res://data/combat/weapon_profiles.json"
@export var squad_profiles_path: String = "res://data/ai/squad_profiles.json"
@export var ability_profiles_path: String = "res://data/abilities/ability_profiles.json"
@export var objective_profiles_path: String = "res://data/missions/objective_profiles.json"
@export var mission_profiles_path: String = "res://data/missions/mission_profiles.json"
@export var progression_profiles_path: String = "res://data/progression/progression_profiles.json"
@export var boss_profiles_path: String = "res://data/bosses/boss_profiles.json"
@export var settings_defaults_path: String = "res://data/ux/settings_defaults.json"
@export var qa_matrix_path: String = "res://data/qa/test_matrix.json"

var _cache: Dictionary = {}

func get_weapon_profile(profile_id: String) -> Dictionary:
	var data: Dictionary = _load_json(weapon_profiles_path)
	return _get_profile_with_fallback(data, ["weapon_profiles", "weapons"], profile_id, ["id", "weapon_id"])

func get_squad_profile(profile_id: String) -> Dictionary:
	var data: Dictionary = _load_json(squad_profiles_path)
	return _get_profile_with_fallback(data, ["squad_profiles", "profiles"], profile_id, ["id", "squad_id"])

func get_ability_profile(profile_id: String) -> Dictionary:
	var data: Dictionary = _load_json(ability_profiles_path)
	return _get_profile_with_fallback(data, ["abilities"], profile_id, ["id", "ability_id"])

func get_objective_profile(profile_id: String) -> Dictionary:
	var data: Dictionary = _load_json(objective_profiles_path)
	return _get_profile_with_fallback(data, ["objective_profiles"], profile_id, ["id", "objective_id"])

func get_mission_profile(profile_id: String) -> Dictionary:
	var data: Dictionary = _load_json(mission_profiles_path)
	return _get_profile_with_fallback(data, ["mission_profiles"], profile_id, ["id", "mission_id"])

func get_progression_profile(profile_id: String) -> Dictionary:
	var data: Dictionary = _load_json(progression_profiles_path)
	return _get_profile_with_fallback(data, ["progression_profiles"], profile_id, ["id", "progression_id"])

func get_boss_profile(profile_id: String) -> Dictionary:
	var data: Dictionary = _load_json(boss_profiles_path)
	return _get_profile_with_fallback(data, ["boss_profiles", "bosses"], profile_id, ["id", "boss_id"])

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

func _get_profile_with_fallback(data: Dictionary, container_keys: Array[String], wanted_id: String, id_keys: Array[String]) -> Dictionary:
	if wanted_id == "":
		return {}
	for container_key in container_keys:
		var container: Variant = data.get(container_key, null)
		if container is Array:
			var match_from_array: Dictionary = _find_in_array(container as Array, wanted_id, id_keys)
			if not match_from_array.is_empty():
				return match_from_array
		elif container is Dictionary:
			var container_dict: Dictionary = container as Dictionary
			if container_dict.has(wanted_id):
				var by_key_variant: Variant = container_dict[wanted_id]
				if by_key_variant is Dictionary:
					return by_key_variant as Dictionary
			for nested_key in container_dict.keys():
				var nested_variant: Variant = container_dict[nested_key]
				if nested_variant is Dictionary:
					var nested_dict: Dictionary = nested_variant as Dictionary
					for id_key in id_keys:
						if str(nested_dict.get(id_key, "")) == wanted_id:
							return nested_dict
	return {}

func _find_in_array(entries: Array, wanted_id: String, id_keys: Array[String]) -> Dictionary:
	for entry_variant in entries:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant as Dictionary
		for id_key in id_keys:
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
