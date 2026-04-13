extends Node

const PROFILE_PATH: String = "user://tps_profile.save"
const DEFAULT_DATA_PATH: String = "res://data/progression/progression_profiles.json"
const PROFILE_VERSION: int = 2

var unlocked_perks: Array[String] = []
var unlocked_weapon_mods: Array[String] = []
var chapter_rewards_claimed: Dictionary = {}
var requisition: int = 0
var xp: int = 0
var perk_points: int = 0
var _starting_points: int = 0
var _point_gains: Dictionary = {
	"mission_primary": 5,
	"mission_optional": 3,
	"boss_kill": 10
}
var _perk_tiers: Array[Dictionary] = []
var _damage_multiplier: float = 1.0
var _spread_multiplier: float = 1.0
var _armor_absorb_multiplier: float = 1.0
var _ability_cooldown_scale: float = 1.0

func _ready() -> void:
	load_profile()

func load_profile() -> void:
	_load_progression_table()
	if FileAccess.file_exists(PROFILE_PATH):
		var file: FileAccess = FileAccess.open(PROFILE_PATH, FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				_apply_profile(parsed as Dictionary)
				_recompute_modifiers()
				return
	_load_defaults()
	save_profile()
	_recompute_modifiers()

func save_profile() -> void:
	var payload: Dictionary = {
		"version": PROFILE_VERSION,
		"unlocked_perks": unlocked_perks,
		"unlocked_weapon_mods": unlocked_weapon_mods,
		"chapter_rewards_claimed": chapter_rewards_claimed,
		"requisition": requisition,
		"xp": xp,
		"perk_points": perk_points
	}
	var file: FileAccess = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "\t"))

func award_mission(primary_completed: bool, optional_completed: bool) -> void:
	if primary_completed:
		xp += 120
		requisition += 45
		perk_points += int(_point_gains.get("mission_primary", 5))
	if optional_completed:
		xp += 60
		requisition += 35
		perk_points += int(_point_gains.get("mission_optional", 3))
	_try_unlock_new_tiers()
	_recompute_modifiers()
	save_profile()

func claim_chapter_reward(chapter_id: String) -> void:
	if chapter_id == "" or chapter_rewards_claimed.get(chapter_id, false):
		return
	chapter_rewards_claimed[chapter_id] = true
	requisition += 80
	perk_points += int(_point_gains.get("boss_kill", 10))
	_try_unlock_new_tiers()
	_recompute_modifiers()
	save_profile()

func get_damage_multiplier() -> float:
	return _damage_multiplier

func get_spread_multiplier() -> float:
	return _spread_multiplier

func get_armor_absorb_multiplier() -> float:
	return _armor_absorb_multiplier

func get_ability_cooldown_scale() -> float:
	return _ability_cooldown_scale

func _load_defaults() -> void:
	unlocked_perks = []
	unlocked_weapon_mods = []
	chapter_rewards_claimed = {}
	requisition = 0
	xp = 0
	perk_points = _starting_points
	_try_unlock_new_tiers()

func _apply_profile(data: Dictionary) -> void:
	var version: int = int(data.get("version", 1))
	unlocked_perks = _string_array(data.get("unlocked_perks", []))
	unlocked_weapon_mods = _string_array(data.get("unlocked_weapon_mods", []))
	chapter_rewards_claimed = data.get("chapter_rewards_claimed", {})
	requisition = int(data.get("requisition", 0))
	xp = int(data.get("xp", 0))
	perk_points = int(data.get("perk_points", 0))
	if version < PROFILE_VERSION and perk_points <= 0:
		# Legacy migration fallback: derive perk points from prior XP.
		perk_points = maxi(0, xp / 20)
	_try_unlock_new_tiers()

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

func _load_progression_table() -> void:
	var data: Dictionary = _load_json(DEFAULT_DATA_PATH)
	if data.is_empty():
		return
	_starting_points = maxi(0, int(data.get("starting_points", _starting_points)))
	var gains: Variant = data.get("point_gains", {})
	if gains is Dictionary:
		_point_gains = (gains as Dictionary).duplicate(true)
	var tiers: Variant = data.get("perk_tiers", [])
	_perk_tiers.clear()
	if tiers is Array:
		for tier_variant in tiers:
			if tier_variant is Dictionary:
				_perk_tiers.append((tier_variant as Dictionary).duplicate(true))

func _try_unlock_new_tiers() -> void:
	for tier in _perk_tiers:
		var required_points: int = int(tier.get("required_points", 999999))
		if perk_points < required_points:
			continue
		var perk_id: String = str(tier.get("perk_id", ""))
		if perk_id == "" or unlocked_perks.has(perk_id):
			continue
		unlocked_perks.append(perk_id)

func _recompute_modifiers() -> void:
	_damage_multiplier = 1.0
	_spread_multiplier = 1.0
	_armor_absorb_multiplier = 1.0
	_ability_cooldown_scale = 1.0
	if unlocked_perks.has("steady_hands"):
		_spread_multiplier = 0.88
	if unlocked_perks.has("stubborn_plate"):
		_armor_absorb_multiplier = 1.1
	if unlocked_perks.has("unbroken_will"):
		_ability_cooldown_scale = 0.92
