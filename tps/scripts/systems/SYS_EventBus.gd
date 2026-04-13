extends Node

signal gameplay_event_emitted(event_name: String, payload: Dictionary)

func emit_gameplay_event(event_name: String, payload: Dictionary = {}) -> void:
	if event_name == "":
		return
	emit_signal("gameplay_event_emitted", event_name, payload)

func emit_event(event_name: String, payload: Dictionary = {}) -> void:
	emit_gameplay_event(event_name, payload)
