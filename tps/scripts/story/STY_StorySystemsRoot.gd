extends Node

@onready var story_manager: Node = $StoryManager
@onready var cutscene_director: Node3D = $CutsceneDirector
@onready var dialogue_ui: CanvasLayer = $DialogueUI

const CHAPTER_ID_BY_NUMBER: Dictionary = {
	1: "ch1_drop_site_aftermath",
	2: "ch2_warp_transit_crisis",
	3: "ch3_blockade_breach",
	4: "ch4_terra_relay"
}

func bootstrap_story() -> void:
	if story_manager and story_manager.has_method("bind_runtime"):
		story_manager.bind_runtime(dialogue_ui, cutscene_director)
	if story_manager and story_manager.has_method("start_first_chapter"):
		story_manager.start_first_chapter()
	if story_manager and story_manager.has_signal("subtitle_changed"):
		if not story_manager.subtitle_changed.is_connected(_on_story_subtitle_changed):
			story_manager.subtitle_changed.connect(_on_story_subtitle_changed)
	if story_manager and story_manager.has_signal("branch_choice_required"):
		if not story_manager.branch_choice_required.is_connected(_on_branch_choice_required):
			story_manager.branch_choice_required.connect(_on_branch_choice_required)

func play_chapter_intro(chapter_ref: Variant) -> void:
	var chapter_id: String = _chapter_id_from_ref(chapter_ref)
	if chapter_id == "":
		return
	if story_manager and story_manager.has_method("play_chapter_intro"):
		story_manager.play_chapter_intro(chapter_id)

func request_contact(contact_id: String) -> void:
	if contact_id == "":
		return
	if story_manager and story_manager.has_method("request_contact"):
		story_manager.request_contact(contact_id)

func queue_contact(contact_id: String) -> void:
	request_contact(contact_id)

func _chapter_id_from_ref(chapter_ref: Variant) -> String:
	if chapter_ref is int:
		return str(CHAPTER_ID_BY_NUMBER.get(chapter_ref, ""))
	if chapter_ref is String:
		var chapter_id: String = chapter_ref
		if chapter_id.begins_with("ch") and chapter_id.find("_") == -1:
			var chapter_number: int = int(chapter_id.trim_prefix("ch"))
			return str(CHAPTER_ID_BY_NUMBER.get(chapter_number, chapter_id))
		return chapter_id
	return ""

func _on_story_subtitle_changed(speaker: String, text: String) -> void:
	if text == "":
		return
	GameState.push_event_message("%s: %s" % [speaker, text])

func _on_branch_choice_required(branch_id: String, options: Array[String]) -> void:
	if options.is_empty():
		return
	GameState.push_event_message("Branch %s selected: %s" % [branch_id, options[0]])
