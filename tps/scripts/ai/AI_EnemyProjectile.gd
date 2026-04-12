extends Area3D

@export var speed: float = 22.0
@export var damage: float = 8.0
@export var lifetime: float = 3.0

var direction: Vector3 = Vector3.FORWARD
var _life_timer: float = 0.0
var _active: bool = false
var _shooter: Node = null

func _ready() -> void:
	_life_timer = lifetime
	body_entered.connect(_on_body_entered)
	_deactivate_visual_state()

func _physics_process(delta: float) -> void:
	if not _active:
		return
	_life_timer = maxf(0.0, _life_timer - delta)
	if _life_timer <= 0.0:
		_deactivate()
		return
	global_position += direction * speed * delta

func set_direction(dir: Vector3) -> void:
	if dir.length_squared() <= 0.0001:
		direction = Vector3.FORWARD
		return
	direction = dir.normalized()

func activate(start_position: Vector3, dir: Vector3, projectile_speed: float, projectile_damage: float, shooter: Node = null) -> void:
	global_position = start_position
	set_direction(dir)
	speed = projectile_speed
	damage = projectile_damage
	_shooter = shooter
	_life_timer = lifetime
	_active = true
	_activate_visual_state()

func deactivate() -> void:
	_deactivate()

func _on_body_entered(body: Node) -> void:
	if not _active:
		return
	if _shooter != null and body == _shooter:
		return
	if body.is_in_group("player") and body.has_method("apply_damage"):
		body.apply_damage(damage)
	_deactivate()

func _deactivate() -> void:
	if not _active:
		return
	_active = false
	_shooter = null
	_deactivate_visual_state()
	if GameState.has_method("release_enemy_projectile"):
		GameState.release_enemy_projectile(self)
	else:
		queue_free()

func _activate_visual_state() -> void:
	monitoring = true
	monitorable = true
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	set_physics_process(true)

func _deactivate_visual_state() -> void:
	monitoring = false
	monitorable = false
	visible = false
	set_physics_process(false)
