extends CharacterBody3D

@export var contact_id: String = ""
@export var interaction_radius: float = 2.4
@export var auto_start_on_enter: bool = false
@export var one_shot: bool = true
@export var contact_prompt: String = "Press interact to contact"
@export var character_display_name: String = ""
@export var chapter_gate: String = ""

@onready var interact_area: Area3D = $InteractArea
@onready var interaction_shape: CollisionShape3D = $InteractArea/CollisionShape3D
@onready var prompt_label: Label3D = $PromptLabel

var _player_inside: bool = false
var _consumed: bool = false

func _ready() -> void:
	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)
	_set_prompt_visible(false)
	if interaction_shape and interaction_shape.shape is SphereShape3D:
		(interaction_shape.shape as SphereShape3D).radius = interaction_radius
	if prompt_label:
		prompt_label.text = contact_prompt

func _physics_process(_delta: float) -> void:
	if _consumed and one_shot:
		return
	if _player_inside and Input.is_action_just_pressed("interact"):
		_trigger_contact()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	_set_prompt_visible(true)
	if auto_start_on_enter:
		_trigger_contact()

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = false
	_set_prompt_visible(false)

func _trigger_contact() -> void:
	if contact_id == "":
		return
	if _consumed and one_shot:
		return
	if chapter_gate != "":
		if GameState.story_chapter_id != chapter_gate:
			GameState.push_event_message("Contact unavailable: chapter mismatch.")
			return
	var story_root: Node = _find_story_systems()
	if story_root and story_root.has_method("request_contact"):
		story_root.request_contact(contact_id)
		var display_name: String = character_display_name if character_display_name != "" else contact_id
		GameState.push_event_message("Contact ping sent: %s" % display_name)
		if one_shot:
			_consumed = true
			_set_prompt_visible(false)

func _set_prompt_visible(is_visible: bool) -> void:
	if prompt_label:
		prompt_label.visible = is_visible

func _find_story_systems() -> Node:
	var node: Node = self
	while node:
		var maybe_story: Node = node.get_node_or_null("StorySystems")
		if maybe_story:
			return maybe_story
		node = node.get_parent()
	return null
