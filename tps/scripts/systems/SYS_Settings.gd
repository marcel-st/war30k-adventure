extends Node

signal settings_changed(setting_name: String, value: Variant)

const SETTINGS_PATH: String = "user://tps_settings.json"
const DEFAULTS_PATH: String = "res://data/ux/settings_defaults.json"

var _settings: Dictionary = {}
var _defaults: Dictionary = {
	"mouse_sensitivity": 0.0019,
	"stick_sensitivity": 2.2,
	"fov": 75.0,
	"aim_assist_strength": 0.0,
	"master_volume": 0.9,
	"sfx_volume": 0.9,
	"music_volume": 0.8,
	"enable_subtitle_background": true,
	"controller_look_deadzone": 0.16,
	"look_acceleration": 8.0,
	"hud_scale": 1.0
}

func _ready() -> void:
	_load_defaults()
	_load_user_settings()

func get_setting(name: String, fallback: Variant = null) -> Variant:
	if not _settings.has(name) and not _defaults.has(name):
		name = _resolve_legacy_alias(name)
	if _settings.has(name):
		return _settings[name]
	if _defaults.has(name):
		return _defaults[name]
	return fallback

func set_setting(name: String, value: Variant) -> void:
	_settings[name] = value
	emit_signal("settings_changed", name, value)
	_save_user_settings()

func get_all_settings() -> Dictionary:
	var merged: Dictionary = _defaults.duplicate(true)
	for key in _settings.keys():
		merged[key] = _settings[key]
	return merged

func _load_defaults() -> void:
	var data: Dictionary = _load_json_dict(DEFAULTS_PATH)
	if data.is_empty():
		return
	var defaults_variant: Variant = data.get("defaults", {})
	if not (defaults_variant is Dictionary):
		defaults_variant = data.get("settings", {})
	if defaults_variant is Dictionary:
		_defaults = (defaults_variant as Dictionary).duplicate(true)

func _load_user_settings() -> void:
	var data: Dictionary = _load_json_dict(SETTINGS_PATH)
	if data.is_empty():
		return
	var settings_variant: Variant = data.get("settings", {})
	if settings_variant is Dictionary:
		_settings = (settings_variant as Dictionary).duplicate(true)

func _save_user_settings() -> void:
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	var payload: Dictionary = {"settings": _settings}
	file.store_string(JSON.stringify(payload, "\t"))

func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}

func _resolve_legacy_alias(setting_name: String) -> String:
	match setting_name:
		"camera_fov":
			return "fov"
		"controller_deadzone":
			return "controller_look_deadzone"
		"controller_look_accel":
			return "look_acceleration"
		_:
			return setting_name
