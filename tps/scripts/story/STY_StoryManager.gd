extends Node

signal chapter_loaded(chapter_id: String, chapter_title: String)
signal chapter_completed(chapter_id: String)
signal contact_triggered(contact_id: String)
signal cutscene_started(cutscene_id: String)
signal cutscene_finished(cutscene_id: String)
signal subtitle_changed(speaker: String, text: String)
signal branch_choice_required(branch_id: String, options: Array[String])
signal branch_choice_applied(branch_id: String, choice_id: String)
signal branch_choice_made(chapter_id: String, choice_id: String)

@export var chapter_data_path: String = "res://data/story/chapters/chapters.json"

var chapters_by_id: Dictionary = {}
var chapter_order: Array[String] = []
var current_chapter_id: String = ""

var _dialogue_ui
var _cutscene_director
var _dialogue_cache: Dictionary = {}
var _cutscene_cache: Dictionary = {}
var _triggered_contacts: Dictionary = {}
var _completed_cutscenes: Dictionary = {}
var _playing_contact: bool = false
var _pending_contacts: Array[String] = []
var _branch_state: Dictionary = {}
var _chapter_summary_queue: Array[String] = []
var _branch_flags: Dictionary = {}

func _ready() -> void:
	_load_chapter_data()

func bind_runtime(dialogue_ui: Node, cutscene_director: Node) -> void:
	_dialogue_ui = dialogue_ui
	_cutscene_director = cutscene_director
	if _cutscene_director:
		_cutscene_director.subtitle_changed.connect(_on_cutscene_subtitle_changed)
		_cutscene_director.cutscene_started.connect(_on_cutscene_started)
		_cutscene_director.cutscene_finished.connect(_on_cutscene_finished)
	if not GameState.story_contact_requested.is_connected(queue_contact):
		GameState.story_contact_requested.connect(queue_contact)

func has_chapter(chapter_id: String) -> bool:
	return chapters_by_id.has(chapter_id)

func start_chapter(chapter_id: String) -> void:
	if not chapters_by_id.has(chapter_id):
		return
	current_chapter_id = chapter_id
	var chapter: Dictionary = chapters_by_id[chapter_id]
	var chapter_title: String = str(chapter.get("title", chapter_id))
	emit_signal("chapter_loaded", chapter_id, chapter_title)
	GameState.set_story_chapter(chapter_id, chapter_title)
	_emit_branch_choice_for_chapter(chapter_id)
	_pending_contacts.clear()
	_playing_contact = false

func start_first_chapter() -> void:
	if chapter_order.is_empty():
		return
	start_chapter(chapter_order[0])

func play_chapter_intro(chapter_id: String) -> void:
	if not has_chapter(chapter_id):
		return
	if current_chapter_id != chapter_id:
		start_chapter(chapter_id)
	await start_chapter_intro_cutscene()

func start_chapter_intro_cutscene() -> void:
	var chapter: Dictionary = _current_chapter()
	if chapter.is_empty() or _cutscene_director == null:
		return
	var cutscene_file: String = str(chapter.get("intro_cutscene", ""))
	if cutscene_file == "":
		return
	var cutscene_data: Dictionary = _load_cutscene_data(cutscene_file)
	if cutscene_data.is_empty():
		return
	var cutscene_id: String = str(cutscene_data.get("cutscene_id", cutscene_file))
	if _completed_cutscenes.has(cutscene_id):
		return
	emit_signal("cutscene_started", cutscene_id)
	await _cutscene_director.play_cutscene_data(cutscene_data)
	_completed_cutscenes[cutscene_id] = true
	emit_signal("cutscene_finished", cutscene_id)

func queue_contact(contact_id: String) -> void:
	if contact_id == "":
		return
	if _triggered_contacts.has(contact_id):
		return
	if _pending_contacts.has(contact_id):
		return
	_pending_contacts.append(contact_id)
	_try_run_next_contact()

func register_branch_choice(branch_id: String, choice_id: String) -> void:
	if branch_id == "" or choice_id == "":
		return
	_branch_state[branch_id] = choice_id
	emit_signal("branch_choice_applied", branch_id, choice_id)
	if GameState and GameState.has_method("set_branch_choice"):
		GameState.set_branch_choice(branch_id, choice_id)
	GameState.push_event_message("Branch set: %s -> %s" % [branch_id, choice_id])

func get_branch_choice(branch_id: String, fallback: String = "") -> String:
	if _branch_state.has(branch_id):
		return str(_branch_state[branch_id])
	return fallback

func trigger_contact(contact_id: String) -> void:
	queue_contact(contact_id)

func _try_run_next_contact() -> void:
	if _playing_contact:
		return
	if _dialogue_ui == null:
		return
	if _dialogue_ui.is_active():
		return
	if _pending_contacts.is_empty():
		return
	var contact_id: String = _pending_contacts.pop_front()
	await _play_contact(contact_id)
	if not _pending_contacts.is_empty():
		call_deferred("_try_run_next_contact")

func _play_contact(contact_id: String) -> void:
	if contact_id == "":
		return
	var chapter: Dictionary = _current_chapter()
	if chapter.is_empty():
		return
	var contact_file: String = str(chapter.get("contacts_file", ""))
	if contact_file == "":
		return
	var contacts_data: Dictionary = _load_dialogue_data(contact_file)
	if contacts_data.is_empty():
		return

	var contact_entry: Dictionary = _find_contact_entry(contacts_data, contact_id)
	if contact_entry.is_empty():
		return
	var contact_lines: Array[Dictionary] = _extract_line_dicts(contact_entry.get("lines", []))
	if contact_lines.is_empty():
		return

	var contact_name: String = str(contact_entry.get("display_name", contact_id))
	var objective_update: String = str(contact_entry.get("objective_update", ""))
	var branch_id: String = str(contact_entry.get("branch_id", ""))
	var branch_choices: Array[String] = _extract_string_array(contact_entry.get("branch_choices", []))
	_playing_contact = true
	emit_signal("contact_triggered", contact_id)
	_triggered_contacts[contact_id] = true
	GameState.push_event_message("Contact established: %s" % contact_name)
	await _dialogue_ui.play_contact(contact_id, contact_lines)
	if branch_id != "" and not branch_choices.is_empty():
		emit_signal("branch_choice_required", branch_id, branch_choices)
		register_branch_choice(branch_id, branch_choices[0])
		GameState.push_event_message("Branch selected [%s]: %s" % [branch_id, branch_choices[0]])
	if objective_update != "":
		GameState.set_objective(objective_update)
	_playing_contact = false

func complete_current_chapter() -> void:
	if current_chapter_id == "":
		return
	var chapter_id: String = current_chapter_id
	emit_signal("chapter_completed", chapter_id)
	var next_id: String = _next_chapter_id(chapter_id)
	if next_id != "":
		start_chapter(next_id)

func request_contact(contact_id: String) -> void:
	queue_contact(contact_id)

func _find_contact_entry(contacts_data: Dictionary, contact_id: String) -> Dictionary:
	var contacts_variant: Variant = contacts_data.get("contacts", [])
	if not (contacts_variant is Array):
		return {}
	for contact_entry_variant in contacts_variant as Array:
		if not (contact_entry_variant is Dictionary):
			continue
		var contact_entry: Dictionary = contact_entry_variant as Dictionary
		if str(contact_entry.get("contact_id", "")) == contact_id:
			return contact_entry
	return {}

func _extract_line_dicts(lines_variant: Variant) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if not (lines_variant is Array):
		return output
	for line_variant in lines_variant as Array:
		if line_variant is Dictionary:
			output.append(line_variant as Dictionary)
	return output

func _extract_string_array(value: Variant) -> Array[String]:
	var output: Array[String] = []
	if not (value is Array):
		return output
	for item in value as Array:
		output.append(str(item))
	return output

func _load_chapter_data() -> void:
	var data: Dictionary = _load_json_dict(chapter_data_path)
	if data.is_empty():
		return
	var chapter_list_variant: Variant = data.get("chapters", [])
	if not (chapter_list_variant is Array):
		return
	var chapter_list: Array = chapter_list_variant as Array
	chapters_by_id.clear()
	chapter_order.clear()
	for entry in chapter_list:
		if not (entry is Dictionary):
			continue
		var chapter_dict: Dictionary = entry as Dictionary
		var chapter_id: String = str(chapter_dict.get("chapter_id", ""))
		if chapter_id == "":
			continue
		chapters_by_id[chapter_id] = chapter_dict
		chapter_order.append(chapter_id)

func _current_chapter() -> Dictionary:
	if current_chapter_id == "" or not chapters_by_id.has(current_chapter_id):
		return {}
	return chapters_by_id[current_chapter_id] as Dictionary

func _next_chapter_id(chapter_id: String) -> String:
	var idx: int = chapter_order.find(chapter_id)
	if idx == -1:
		return ""
	var next_idx: int = idx + 1
	if next_idx >= chapter_order.size():
		return ""
	return chapter_order[next_idx]

func _load_dialogue_data(path: String) -> Dictionary:
	if _dialogue_cache.has(path):
		return _dialogue_cache[path]
	var data: Dictionary = _load_json_dict(path)
	if not data.is_empty():
		_dialogue_cache[path] = data
	return data

func _load_cutscene_data(path: String) -> Dictionary:
	if _cutscene_cache.has(path):
		return _cutscene_cache[path]
	var data: Dictionary = _load_json_dict(path)
	if not data.is_empty():
		_cutscene_cache[path] = data
	return data

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

func _on_cutscene_subtitle_changed(text: String, speaker: String) -> void:
	emit_signal("subtitle_changed", speaker, text)

func _on_cutscene_started(cutscene_id: String) -> void:
	emit_signal("cutscene_started", cutscene_id)

func _on_cutscene_finished(cutscene_id: String, _skipped: bool) -> void:
	emit_signal("cutscene_finished", cutscene_id)

func _emit_branch_choice_for_chapter(chapter_id: String) -> void:
	var choice_id: String = "default_path"
	match chapter_id:
		"ch1_drop_site_aftermath":
			choice_id = "hold_the_line"
		"ch2_warp_transit_crisis":
			choice_id = "secure_relay"
		"ch3_blockade_breach":
			choice_id = "breach_aggressive"
		"ch4_terra_relay":
			choice_id = "transmit_priority"
		_:
			choice_id = "default_path"
	_branch_flags[chapter_id] = choice_id
	emit_signal("branch_choice_made", chapter_id, choice_id)
