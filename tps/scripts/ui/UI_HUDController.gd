extends CanvasLayer

@onready var stats_label: Label = $Margin/VBox/TopRow/StatsLabel
@onready var enemy_count_label: Label = $Margin/VBox/EnemyCountLabel
@onready var objective_label: Label = $Margin/VBox/ObjectiveLabel

func _ready() -> void:
	GameState.player_stats_changed.connect(_on_player_stats_changed)
	GameState.objective_changed.connect(_on_objective_changed)
	GameState.enemies_remaining_changed.connect(_on_enemies_remaining_changed)
	_on_player_stats_changed(
		GameState.health,
		GameState.armor,
		GameState.ammo_in_magazine,
		GameState.ammo_reserve
	)
	_on_enemies_remaining_changed(GameState.enemies_remaining)
	_on_objective_changed(GameState.objective_text, GameState.objective_completed)

func _on_player_stats_changed(health: float, armor: float, magazine: int, reserve: int) -> void:
	stats_label.text = "HP %d | AR %d | MAG %d/%d" % [int(round(health)), int(round(armor)), magazine, reserve]

func _on_objective_changed(text: String, completed: bool) -> void:
	var prefix := "[DONE] " if completed else "[OBJ] "
	objective_label.text = "%s%s" % [prefix, text]

func _on_enemies_remaining_changed(remaining: int) -> void:
	enemy_count_label.text = "Traitors remaining: %d" % remaining
