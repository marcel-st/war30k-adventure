extends Area3D

@export var speed: float = 22.0
@export var damage: float = 8.0
@export var lifetime: float = 3.0

var direction: Vector3 = Vector3.FORWARD
var _life_timer: float = 0.0

func _ready() -> void:
	_life_timer = lifetime
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_life_timer = maxf(0.0, _life_timer - delta)
	if _life_timer <= 0.0:
		queue_free()
		return
	global_position += direction * speed * delta

func set_direction(dir: Vector3) -> void:
	if dir.length_squared() <= 0.0001:
		direction = Vector3.FORWARD
		return
	direction = dir.normalized()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("apply_damage"):
		body.apply_damage(damage, global_position)
	queue_free()
