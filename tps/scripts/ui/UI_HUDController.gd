extends CanvasLayer

@onready var stats_label: Label = $Margin/VBox/TopRow/StatsLabel
@onready var enemy_count_label: Label = $Margin/VBox/EnemiesLabel
@onready var wave_label: Label = $Margin/VBox/WaveLabel
@onready var objective_label: Label = $Margin/VBox/ObjectiveLabel
@onready var event_label: Label = $Margin/VBox/EventLabel
@onready var status_label: Label = $Margin/VBox/StatusLabel
@onready var chapter_label: Label = $Margin/VBox/ChapterLabel
@onready var progression_label: Label = $Margin/VBox/ProgressionLabel

func _ready() -> void:
	GameState.player_stats_changed.connect(_on_player_stats_changed)
	GameState.objective_changed.connect(_on_objective_changed)
	GameState.enemies_remaining_changed.connect(_on_enemies_remaining_changed)
	GameState.wave_changed.connect(_on_wave_changed)
	GameState.event_feed_changed.connect(_on_event_feed_changed)
	GameState.mission_state_changed.connect(_on_mission_state_changed)
	GameState.story_chapter_changed.connect(_on_story_chapter_changed)
	GameState.progression_changed.connect(_on_progression_changed)
	_on_player_stats_changed(
		GameState.health,
		GameState.armor,
		GameState.ammo_in_magazine,
		GameState.ammo_reserve
	)
	_on_enemies_remaining_changed(GameState.enemies_remaining)
	_on_wave_changed(GameState.current_wave, GameState.total_waves)
	_on_event_feed_changed(GameState.event_feed_text)
	_on_mission_state_changed(GameState.mission_state, GameState.mission_state_reason)
	_on_story_chapter_changed(GameState.story_chapter_id, GameState.story_chapter_title)
	_on_progression_changed(GameState.player_level, GameState.player_xp, GameState.player_requisition)
	_on_objective_changed(GameState.objective_text, GameState.objective_completed)

func _on_player_stats_changed(health: float, armor: float, magazine: int, reserve: int) -> void:
	if stats_label:
		stats_label.text = "HP %d | AR %d | MAG %d/%d" % [int(round(health)), int(round(armor)), magazine, reserve]

func _on_objective_changed(text: String, completed: bool) -> void:
	var prefix := "[DONE] " if completed else "[OBJ] "
	if objective_label:
		objective_label.text = "%s%s" % [prefix, text]

func _on_enemies_remaining_changed(remaining: int) -> void:
	if enemy_count_label:
		enemy_count_label.text = "Traitors remaining: %d" % remaining

func _on_wave_changed(current_wave: int, total_waves: int) -> void:
	if not wave_label:
		return
	if total_waves <= 0:
		wave_label.text = "Wave: --"
	else:
		wave_label.text = "Wave: %d/%d" % [current_wave, total_waves]

func _on_event_feed_changed(text: String) -> void:
	if not event_label:
		return
	event_label.text = text

func _on_mission_state_changed(run_state: String, _reason: String) -> void:
	if not status_label:
		return
	match run_state:
		"failed":
			status_label.text = "STATUS: MISSION FAILED - Press R/Enter/Start to restart"
		"victory":
			status_label.text = "STATUS: OBJECTIVE COMPLETE - Press R/Enter/Start to replay"
		_:
			status_label.text = "STATUS: ACTIVE"

func _on_story_chapter_changed(_chapter_id: String, chapter_title: String) -> void:
	if chapter_label:
		chapter_label.text = "Chapter: %s" % chapter_title

func _on_progression_changed(level: int, xp: int, requisition: int) -> void:
	if progression_label:
		progression_label.text = "Lvl %d | XP %d | Req %d" % [level, xp, requisition]
