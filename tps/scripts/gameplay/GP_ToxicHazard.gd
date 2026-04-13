extends Area3D

@export var radius: float = 4.8
@export var damage_per_tick: float = 5.5
@export var tick_interval: float = 0.45
@export var lifetime: float = 7.5

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ring_mesh: MeshInstance3D = $VisualRoot/HazardDecalMesh

var _life_remaining: float = 0.0
var _tick_remaining: float = 0.0
var _affected_bodies: Array[Node] = []
var _owner: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	configure(radius, damage_per_tick, lifetime)
	if EventBus:
		EventBus.emit_event("ability.toxic_hazard_spawned")

func configure(new_radius: float, new_damage_per_tick: float, new_lifetime: float, owner_node: Node = null) -> void:
	radius = maxf(0.6, new_radius)
	damage_per_tick = maxf(0.1, new_damage_per_tick)
	lifetime = maxf(0.3, new_lifetime)
	_owner = owner_node
	_life_remaining = lifetime
	_tick_remaining = 0.05
	if collision_shape and collision_shape.shape is SphereShape3D:
		var sphere: SphereShape3D = collision_shape.shape as SphereShape3D
		sphere.radius = radius
	elif collision_shape and collision_shape.shape is CylinderShape3D:
		var cylinder: CylinderShape3D = collision_shape.shape as CylinderShape3D
		cylinder.radius = radius
	if ring_mesh:
		ring_mesh.scale = Vector3(radius * 2.0, 0.06, radius * 2.0)

func set_owner_node(owner_node: Node) -> void:
	_owner = owner_node

func _physics_process(delta: float) -> void:
	_life_remaining = maxf(0.0, _life_remaining - delta)
	_tick_remaining = maxf(0.0, _tick_remaining - delta)
	if _tick_remaining <= 0.0:
		_tick_remaining = tick_interval
		_apply_tick_damage()
	if _life_remaining <= 0.0:
		queue_free()

func _apply_tick_damage() -> void:
	var applied_tick: bool = false
	var survivors: Array[Node] = []
	for body in _affected_bodies:
		if not is_instance_valid(body):
			continue
		survivors.append(body)
		if body == _owner:
			continue
		if body.is_in_group("player") and body.has_method("apply_damage_from_hazard"):
			body.apply_damage_from_hazard(damage_per_tick, global_position)
			applied_tick = true
			continue
		if body.has_method("apply_damage"):
			body.apply_damage(damage_per_tick)
			applied_tick = true
	_affected_bodies = survivors
	if applied_tick and EventBus:
		EventBus.emit_event("ability.toxic_hazard_tick")

func _on_body_entered(body: Node) -> void:
	if _affected_bodies.has(body):
		return
	_affected_bodies.append(body)

func _on_body_exited(body: Node) -> void:
	_affected_bodies.erase(body)
