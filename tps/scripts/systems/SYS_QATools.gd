extends Node

@export var qa_data_path: String = "res://data/qa/test_matrix.json"

var _qa_data: Dictionary = {}

func _ready() -> void:
	_load_qa_data()

func get_test_matrix() -> Dictionary:
	return _qa_data

func emit_basic_smoke_report() -> void:
	var report: Dictionary = {
		"mission_state": GameState.mission_state,
		"chapter_id": GameState.story_chapter_id,
		"wave": GameState.current_wave,
		"enemies_remaining": GameState.enemies_remaining,
		"mission_mode": str(GameState.get_meta("mission_mode", "wave_assault")),
		"active_branch_choices": GameState.get_all_branch_choices(),
		"profile_version": 2
	}
	if EventBus:
		EventBus.emit_gameplay_event("qa_smoke_report", report)

func _load_qa_data() -> void:
	if not FileAccess.file_exists(qa_data_path):
		_qa_data = {}
		return
	var file: FileAccess = FileAccess.open(qa_data_path, FileAccess.READ)
	if file == null:
		_qa_data = {}
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_qa_data = parsed as Dictionary
	else:
		_qa_data = {}
