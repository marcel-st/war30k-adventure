extends Node

signal settings_changed(setting_name: String, value: Variant)

const SETTINGS_PATH: String = "user://tps_settings.json"
const DEFAULTS_PATH: String = "res://data/ux/settings_defaults.json"

var _settings: Dictionary = {}
var _defaults: Dictionary = {
	"mouse_sensitivity": 0.0019,
	"aim_assist_strength": 0.0,
	"fov": 75.0,
	"master_volume_db": 0.0,
	"sfx_volume_db": 0.0,
	"music_volume_db": 0.0,
	"enable_subtitle_background": true
}

func _ready() -> void:
	_load_defaults()
	_load_user_settings()

func get_setting(name: String, fallback: Variant = null) -> Variant:
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
