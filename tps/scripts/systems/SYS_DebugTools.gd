extends Node

@export var invulnerable: bool = false
@export var infinite_ammo: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_god_mode"):
		invulnerable = not invulnerable
		GameState.push_event_message("Debug god mode: %s" % ("ON" if invulnerable else "OFF"))
	if event.is_action_pressed("debug_toggle_infinite_ammo"):
		infinite_ammo = not infinite_ammo
		GameState.push_event_message("Debug infinite ammo: %s" % ("ON" if infinite_ammo else "OFF"))
	if event.is_action_pressed("debug_skip_wave"):
		GameState.push_event_message("Debug wave skip requested")
		GameState.set_mission_state("extract", "Debug skip wave")
	if event.is_action_pressed("debug_cycle_chapter"):
		GameState.push_event_message("Debug chapter cycle requested")

func can_take_damage() -> bool:
	return not invulnerable

func should_consume_ammo() -> bool:
	return not infinite_ammo
