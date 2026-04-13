extends Node

const ENEMY_PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemies/SCN_EnemyProjectile.tscn")

@export var prewarm_count: int = 16
@export var max_pool_size: int = 64

var _available_enemy_projectiles: Array[Node] = []
var _in_use_enemy_projectiles: Dictionary = {}
var _container: Node3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func configure_container(container: Node3D) -> void:
	_container = container
	_prewarm_enemy_projectiles()

func spawn_enemy_projectile(position: Vector3, direction: Vector3, speed: float, damage: float, owner: Node) -> Node:
	var projectile: Node = _take_enemy_projectile()
	if projectile == null:
		return null
	if _container and projectile.get_parent() != _container:
		_container.add_child(projectile)
	projectile.visible = true
	projectile.set_process(true)
	projectile.set_physics_process(true)
	projectile.global_position = position
	if projectile.has_method("setup"):
		projectile.setup(direction, speed, damage, owner)
	_in_use_enemy_projectiles[projectile] = true
	return projectile

func recycle_enemy_projectile(projectile: Node) -> void:
	if projectile == null:
		return
	if not is_instance_valid(projectile):
		return
	if not _in_use_enemy_projectiles.has(projectile):
		return
	_in_use_enemy_projectiles.erase(projectile)
	if _available_enemy_projectiles.size() >= max_pool_size:
		projectile.queue_free()
		return
	if projectile.has_method("reset_for_pool"):
		projectile.reset_for_pool()
	else:
		projectile.set_physics_process(false)
		projectile.set_process(false)
		projectile.visible = false
	_available_enemy_projectiles.append(projectile)

func _take_enemy_projectile() -> Node:
	if not _available_enemy_projectiles.is_empty():
		return _available_enemy_projectiles.pop_back()
	var created: Node = ENEMY_PROJECTILE_SCENE.instantiate()
	created.set_meta("pooled_projectile", true)
	return created

func _prewarm_enemy_projectiles() -> void:
	var count: int = maxi(0, mini(prewarm_count, max_pool_size))
	for _i in range(count):
		var projectile: Node = ENEMY_PROJECTILE_SCENE.instantiate()
		projectile.set_meta("pooled_projectile", true)
		if _container:
			_container.add_child(projectile)
		if projectile.has_method("reset_for_pool"):
			projectile.reset_for_pool()
		else:
			projectile.set_physics_process(false)
			projectile.set_process(false)
			projectile.visible = false
		_available_enemy_projectiles.append(projectile)
