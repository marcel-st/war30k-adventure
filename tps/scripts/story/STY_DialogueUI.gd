extends CanvasLayer

signal dialogue_started(contact_id: String)
signal dialogue_advanced(contact_id: String, line_index: int)
signal dialogue_finished(contact_id: String)

@onready var root_margin: MarginContainer = $RootMargin
@onready var speaker_label: Label = $RootMargin/Panel/VBox/SpeakerLabel
@onready var line_label: RichTextLabel = $RootMargin/Panel/VBox/LineLabel
@onready var hint_label: Label = $RootMargin/Panel/VBox/HintLabel

var _active_contact_id: String = ""
var _lines: Array[Dictionary] = []
var _line_index: int = -1
var _active: bool = false

func _ready() -> void:
	_set_visible(false)
	process_mode = Node.PROCESS_MODE_ALWAYS

func is_active() -> bool:
	return _active

func play_contact(contact_id: String, lines: Array[Dictionary]) -> void:
	if lines.is_empty():
		return
	if _active:
		await dialogue_finished
	_active_contact_id = contact_id
	_lines = lines
	_line_index = -1
	_active = true
	_set_visible(true)
	emit_signal("dialogue_started", _active_contact_id)
	_show_next_line()
	await dialogue_finished

func force_close() -> void:
	if not _active:
		return
	_end_dialogue()

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("dialogue_continue") or event.is_action_pressed("fire"):
		_show_next_line()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("skip_cutscene") or event.is_action_pressed("pause"):
		_end_dialogue()
		get_viewport().set_input_as_handled()

func _show_next_line() -> void:
	_line_index += 1
	if _line_index >= _lines.size():
		_end_dialogue()
		return
	var line: Dictionary = _lines[_line_index]
	speaker_label.text = str(line.get("speaker", "Unknown"))
	line_label.text = str(line.get("text", ""))
	hint_label.text = "Enter / A / RB: Next   Esc / B: Close"
	if AudioManager:
		AudioManager.play_ui_event("ui_click")
	emit_signal("dialogue_advanced", _active_contact_id, _line_index)

func _end_dialogue() -> void:
	var finished_contact: String = _active_contact_id
	_active_contact_id = ""
	_lines.clear()
	_line_index = -1
	_active = false
	_set_visible(false)
	emit_signal("dialogue_finished", finished_contact)

func _set_visible(is_visible: bool) -> void:
	root_margin.visible = is_visible
