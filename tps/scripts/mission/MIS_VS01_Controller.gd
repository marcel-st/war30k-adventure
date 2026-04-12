extends Node3D

@onready var extraction_zone: Area3D = $ExtractionZone
@onready var enemy_container: Node3D = $Enemies

const TRAITOR_SCENE: PackedScene = preload("res://scenes/enemies/SCN_EnemyTraitorMarine.tscn")
const CULTIST_SCENE: PackedScene = preload("res://scenes/enemies/SCN_EnemyCultistRanged.tscn")

var _wave_index: int = 0
var _waves: Array[Dictionary] = [
	{
		"melee": 2,
		"ranged": 1,
		"spawn_interval": 0.55,
		"objective": "Wave 1: break initial traitor push."
	},
	{
		"melee": 3,
		"ranged": 2,
		"spawn_interval": 0.45,
		"objective": "Wave 2: hold under suppressive fire."
	}
]
var _active_enemies: Array[Node3D] = []
var _combat_completed: bool = false
var _is_spawning_wave: bool = false

func _ready() -> void:
	GameState.reset_run()
	_refresh_player_group_tag()
	extraction_zone.body_entered.connect(_on_extraction_body_entered)
	extraction_zone.monitoring = false
	_start_next_wave()

func _physics_process(_delta: float) -> void:
	_cleanup_dead_enemies()
	if _active_enemies.is_empty() and not _combat_completed and not _is_spawning_wave:
		_start_next_wave()

func _on_extraction_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.complete_objective("Extraction reached. Loyalist warning secured.")

func _refresh_player_group_tag() -> void:
	var player: Node3D = get_node_or_null("Player")
	if player and not player.is_in_group("player"):
		player.add_to_group("player")

func _start_next_wave() -> void:
	if _wave_index >= _waves.size():
		_combat_completed = true
		GameState.set_enemies_remaining(0)
		GameState.set_objective("Combat lane secured. Move to extraction zone.")
		extraction_zone.monitoring = true
		return

	var wave_data: Dictionary = _waves[_wave_index]
	var melee_count: int = int(wave_data.get("melee", 0))
	var ranged_count: int = int(wave_data.get("ranged", 0))
	var spawn_interval: float = float(wave_data.get("spawn_interval", 0.5))
	var total_count: int = melee_count + ranged_count
	var objective_text: String = str(wave_data.get("objective", "Eliminate all enemies in wave %d." % (_wave_index + 1)))
	GameState.set_objective("%s (%d/%d)" % [objective_text, _wave_index + 1, _waves.size()])
	GameState.set_enemies_remaining(total_count)
	_is_spawning_wave = true
	await _spawn_wave_units(melee_count, ranged_count, spawn_interval)
	_is_spawning_wave = false
	_wave_index += 1

func _spawn_wave_units(melee_count: int, ranged_count: int, interval: float) -> void:
	var spawn_order: Array[PackedScene] = []
	for _i in range(melee_count):
		spawn_order.append(TRAITOR_SCENE)
	for _j in range(ranged_count):
		spawn_order.append(CULTIST_SCENE)
	spawn_order.shuffle()
	for spawn_index in range(spawn_order.size()):
		var spawn_scene: PackedScene = spawn_order[spawn_index]
		var spawn_position: Vector3 = _pick_spawn_position(spawn_index)
		var enemy: Node3D = spawn_scene.instantiate()
		enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))
		enemy_container.add_child(enemy)
		enemy.global_position = spawn_position
		_active_enemies.append(enemy)
		if spawn_index < spawn_order.size() - 1:
			var timer: SceneTreeTimer = get_tree().create_timer(maxf(0.05, interval))
			await timer.timeout

func _pick_spawn_position(index: int) -> Vector3:
	var marker_nodes: Array[Node] = get_tree().get_nodes_in_group("enemy_spawn")
	if marker_nodes.is_empty():
		return Vector3(0.0, 1.1, -10.0 - float(index) * 2.5)
	var marker_index: int = index % marker_nodes.size()
	var marker: Node3D = marker_nodes[marker_index] as Node3D
	if marker:
		return marker.global_position
	return Vector3(0.0, 1.1, -10.0 - float(index) * 2.5)

func _cleanup_dead_enemies() -> void:
	var survivors: Array[Node3D] = []
	for enemy in _active_enemies:
		if is_instance_valid(enemy):
			survivors.append(enemy)
	_active_enemies = survivors
	GameState.set_enemies_remaining(_active_enemies.size())

func _on_enemy_tree_exited(enemy: Node3D) -> void:
	_active_enemies.erase(enemy)
	GameState.set_enemies_remaining(_active_enemies.size())
