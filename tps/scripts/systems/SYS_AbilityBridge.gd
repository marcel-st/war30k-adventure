extends Node

func set_player(player: Node) -> void:
	if not GameState or not GameState.has_method("set_ability_player"):
		return
	GameState.set_ability_player(player)

func trigger_ability(ability_id: String) -> bool:
	if not GameState or not GameState.has_method("trigger_ability"):
		return false
	return bool(GameState.trigger_ability(ability_id))

func get_move_speed_multiplier() -> float:
	if not GameState or not GameState.has_method("get_ability_move_speed_multiplier"):
		return 1.0
	return float(GameState.get_ability_move_speed_multiplier())
