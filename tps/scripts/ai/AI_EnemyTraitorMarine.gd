extends CharacterBody3D

signal died(enemy: Node3D)

@export var max_health: float = 70.0
@export var move_speed: float = 3.4
@export var acceleration: float = 9.0
@export var gravity_scale: float = 1.0
@export var detection_radius: float = 28.0
@export var attack_radius: float = 2.1
@export var attack_damage: float = 9.0
@export var attack_cooldown: float = 1.2
@export var corpse_lifetime: float = 2.6

@onready var visual_root: Node3D = get_node_or_null("VisualRoot") as Node3D
@onready var awareness_area: Area3D = get_node_or_null("Awareness") as Area3D

var gravity: float = 24.0
var health: float = 70.0
var is_dead: bool = false
var attack_timer: float = 0.0
var tracked_player: CharacterBody3D = null

func _ready() -> void:
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 24.0) * gravity_scale
	health = max_health
	if awareness_area:
		var awareness_shape: CollisionShape3D = awareness_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if awareness_shape and awareness_shape.shape is SphereShape3D:
			(awareness_shape.shape as SphereShape3D).radius = detection_radius
		awareness_area.body_entered.connect(_on_awareness_body_entered)
		awareness_area.body_exited.connect(_on_awareness_body_exited)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	attack_timer = maxf(0.0, attack_timer - delta)
	_apply_gravity(delta)

	var desired_velocity: Vector3 = Vector3.ZERO
	if _can_engage_player():
		var to_player: Vector3 = tracked_player.global_position - global_position
		to_player.y = 0.0
		var distance_to_player: float = to_player.length()
		if distance_to_player > attack_radius:
			var dir: Vector3 = to_player.normalized()
			desired_velocity = dir * move_speed
			_face_towards(global_position + dir, delta)
		else:
			_try_melee_attack()

	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	horizontal_velocity = horizontal_velocity.lerp(desired_velocity, clampf(acceleration * delta, 0.0, 1.0))
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	move_and_slide()

func apply_damage(raw_damage: float) -> void:
	if is_dead or raw_damage <= 0.0:
		return
	health = maxf(0.0, health - raw_damage)
	if health <= 0.0:
		_die()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

func _can_engage_player() -> bool:
	if tracked_player == null:
		return false
	return is_instance_valid(tracked_player) and not tracked_player.is_queued_for_deletion()

func _try_melee_attack() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	if tracked_player and tracked_player.has_method("apply_damage"):
		tracked_player.apply_damage(attack_damage)

func _face_towards(target_position: Vector3, delta: float) -> void:
	var to_target: Vector3 = target_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.001:
		return
	var yaw: float = atan2(to_target.x, to_target.z)
	rotation.y = lerp_angle(rotation.y, yaw, clampf(8.0 * delta, 0.0, 1.0))

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	if awareness_area:
		awareness_area.monitoring = false
	if visual_root:
		visual_root.scale = Vector3(1.0, 0.35, 1.0)
	emit_signal("died", self)
	var timer: SceneTreeTimer = get_tree().create_timer(corpse_lifetime)
	timer.timeout.connect(queue_free)

func _on_awareness_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		tracked_player = body as CharacterBody3D

func _on_awareness_body_exited(body: Node) -> void:
	if body == tracked_player:
		tracked_player = null
