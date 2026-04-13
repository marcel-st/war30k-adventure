extends Node3D

signal cutscene_started(cutscene_id: String)
signal cutscene_finished(cutscene_id: String, skipped: bool)
signal subtitle_changed(text: String, speaker: String)

@onready var camera_root: Node3D = $CameraRoot
@onready var camera: Camera3D = $CameraRoot/Camera3D

var _active_cutscene_id: String = ""
var _playing: bool = false
var _skipped: bool = false
var _subtitle_queue: Array[Dictionary] = []
var _active_subtitle_index: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	camera.current = false

func _unhandled_input(event: InputEvent) -> void:
	if not _playing:
		return
	if event.is_action_pressed("skip_cutscene"):
		skip_active_cutscene()
		get_viewport().set_input_as_handled()

func is_playing() -> bool:
	return _playing

func play_cutscene_data(cutscene_data: Dictionary) -> void:
	if _playing:
		return

	_active_cutscene_id = str(cutscene_data.get("cutscene_id", "unknown"))
	_playing = true
	_skipped = false
	_subtitle_queue = _typed_dict_array(cutscene_data.get("subtitle_lines", []))
	_active_subtitle_index = -1

	camera.current = true
	emit_signal("cutscene_started", _active_cutscene_id)
	emit_signal("subtitle_changed", "", "")

	var shots: Array[Dictionary] = _typed_dict_array(cutscene_data.get("shots", []))
	for shot in shots:
		if _skipped:
			break
		await _play_shot(shot)

	_finish_cutscene()

func skip_active_cutscene() -> void:
	if not _playing:
		return
	_skipped = true

func _play_shot(shot: Dictionary) -> void:
	if _skipped:
		return
	var pos: Vector3 = _vec3_from_variant(shot.get("camera_pos", [0.0, 4.0, 8.0]), Vector3(0.0, 4.0, 8.0))
	var look: Vector3 = _vec3_from_variant(shot.get("look_at", [0.0, 1.0, 0.0]), Vector3(0.0, 1.0, 0.0))
	var fov: float = float(shot.get("fov", 60.0))
	var duration: float = maxf(0.05, float(shot.get("duration", 2.0)))

	camera_root.global_position = pos
	camera_root.look_at(look, Vector3.UP)
	camera.fov = fov
	_emit_subtitle_for_index(_active_subtitle_index + 1)

	var timer: SceneTreeTimer = get_tree().create_timer(duration)
	await timer.timeout

func _emit_subtitle_for_index(index: int) -> void:
	if index < 0 or index >= _subtitle_queue.size():
		emit_signal("subtitle_changed", "", "")
		return
	_active_subtitle_index = index
	var line: Dictionary = _subtitle_queue[index]
	emit_signal("subtitle_changed", str(line.get("text", "")), str(line.get("speaker", "")))

func _vec3_from_variant(value: Variant, fallback: Vector3) -> Vector3:
	if value is Array:
		var arr: Array = value as Array
		if arr.size() >= 3:
			return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
	return fallback

func _typed_dict_array(value: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not (value is Array):
		return out
	for item in value as Array:
		if item is Dictionary:
			out.append(item as Dictionary)
	return out

func _finish_cutscene() -> void:
	camera.current = false
	emit_signal("subtitle_changed", "", "")
	emit_signal("cutscene_finished", _active_cutscene_id, _skipped)
	_active_cutscene_id = ""
	_playing = false
	_skipped = false
	_subtitle_queue.clear()
	_active_subtitle_index = -1
