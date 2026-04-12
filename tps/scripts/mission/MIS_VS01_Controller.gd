extends Node3D

@onready var extraction_zone: Area3D = $ExtractionZone

func _ready() -> void:
	GameState.reset_run()
	GameState.set_objective("Push through traitor lines and reach extraction.")
	_refresh_player_group_tag()
	extraction_zone.body_entered.connect(_on_extraction_body_entered)

func _on_extraction_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.complete_objective("Extraction reached. Loyalist warning secured.")

func _refresh_player_group_tag() -> void:
	var player := get_node_or_null("Player")
	if player and not player.is_in_group("player"):
		player.add_to_group("player")
