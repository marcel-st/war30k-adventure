extends Node

const PROFILE_PATH: String = "user://tps_profile.save"
const DEFAULT_DATA_PATH: String = "res://data/progression/progression_profiles.json"

var unlocked_perks: Array[String] = []
var unlocked_weapon_mods: Array[String] = []
var chapter_rewards_claimed: Dictionary = {}
var requisition: int = 0
var xp: int = 0

func _ready() -> void:
	load_profile()

func load_profile() -> void:
	if FileAccess.file_exists(PROFILE_PATH):
		var file: FileAccess = FileAccess.open(PROFILE_PATH, FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				_apply_profile(parsed as Dictionary)
				return
	_load_defaults()
	save_profile()

func save_profile() -> void:
	var payload: Dictionary = {
		"unlocked_perks": unlocked_perks,
		"unlocked_weapon_mods": unlocked_weapon_mods,
		"chapter_rewards_claimed": chapter_rewards_claimed,
		"requisition": requisition,
		"xp": xp
	}
	var file: FileAccess = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "\t"))

func award_mission(primary_completed: bool, optional_completed: bool) -> void:
	if primary_completed:
		xp += 120
		requisition += 45
	if optional_completed:
		xp += 60
		requisition += 35
	save_profile()

func claim_chapter_reward(chapter_id: String) -> void:
	if chapter_id == "" or chapter_rewards_claimed.get(chapter_id, false):
		return
	chapter_rewards_claimed[chapter_id] = true
	requisition += 80
	save_profile()

func _load_defaults() -> void:
	var data: Dictionary = _load_json(DEFAULT_DATA_PATH)
	var defaults: Dictionary = data.get("default_unlocks", {})
	unlocked_perks = _string_array(defaults.get("starter_perks", []))
	unlocked_weapon_mods = _string_array(defaults.get("starter_weapon_mods", []))
	chapter_rewards_claimed = {}
	requisition = 0
	xp = 0

func _apply_profile(data: Dictionary) -> void:
	unlocked_perks = _string_array(data.get("unlocked_perks", []))
	unlocked_weapon_mods = _string_array(data.get("unlocked_weapon_mods", []))
	chapter_rewards_claimed = data.get("chapter_rewards_claimed", {})
	requisition = int(data.get("requisition", 0))
	xp = int(data.get("xp", 0))

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}

func _string_array(value: Variant) -> Array[String]:
	var output: Array[String] = []
	if not (value is Array):
		return output
	for item in value:
		output.append(str(item))
	return output
