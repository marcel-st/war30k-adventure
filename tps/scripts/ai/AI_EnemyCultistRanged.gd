extends CharacterBody3D

signal died(enemy: Node3D)

@export var max_health: float = 45.0
@export var move_speed: float = 3.0
@export var acceleration: float = 8.0
@export var gravity_scale: float = 1.0
@export var detection_radius: float = 34.0
@export var ideal_range: float = 12.0
@export var retreat_range: float = 6.0
@export var projectile_speed: float = 20.0
@export var attack_damage: float = 11.0
@export var attack_cooldown: float = 1.5
@export var corpse_lifetime: float = 2.2
@export var hit_react_duration: float = 0.12
@export var hit_react_knockback: float = 2.1

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemies/SCN_EnemyProjectile.tscn")

@onready var visual_root: Node3D = $VisualRoot
@onready var body_mesh: MeshInstance3D = $VisualRoot/BodyMesh
@onready var awareness_area: Area3D = $Awareness
@onready var muzzle: Marker3D = $VisualRoot/Muzzle

var gravity: float = 24.0
var health: float = 45.0
var is_dead: bool = false
var attack_timer: float = 0.0
var hit_react_timer: float = 0.0
var tracked_player: CharacterBody3D = null

func _ready() -> void:
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 24.0) * gravity_scale
	health = max_health
	var awareness_shape: CollisionShape3D = awareness_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if awareness_shape and awareness_shape.shape is SphereShape3D:
		(awareness_shape.shape as SphereShape3D).radius = detection_radius
	awareness_area.body_entered.connect(_on_awareness_body_entered)
	awareness_area.body_exited.connect(_on_awareness_body_exited)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	attack_timer = maxf(0.0, attack_timer - delta)
	hit_react_timer = maxf(0.0, hit_react_timer - delta)
	if body_mesh:
		body_mesh.scale = body_mesh.scale.lerp(Vector3.ONE, clampf(delta * 14.0, 0.0, 1.0))

	_apply_gravity(delta)
	var desired_velocity: Vector3 = Vector3.ZERO

	if _can_engage_player():
		var to_player: Vector3 = tracked_player.global_position - global_position
		to_player.y = 0.0
		var distance_to_player: float = to_player.length()
		if distance_to_player > ideal_range:
			desired_velocity = to_player.normalized() * move_speed
		elif distance_to_player < retreat_range:
			desired_velocity = -to_player.normalized() * move_speed * 0.7
		else:
			_try_ranged_attack()
		_face_towards(global_position + to_player, delta)

	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	horizontal_velocity = horizontal_velocity.lerp(desired_velocity, clampf(acceleration * delta, 0.0, 1.0))
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	move_and_slide()

func apply_damage(raw_damage: float) -> void:
	if is_dead or raw_damage <= 0.0:
		return
	health = maxf(0.0, health - raw_damage)
	_enter_hit_react()
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

func _try_ranged_attack() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	var projectile: Node3D = PROJECTILE_SCENE.instantiate()
	projectile.global_position = muzzle.global_position
	projectile.look_at(tracked_player.global_position + Vector3.UP * 0.8, Vector3.UP)
	projectile.set("speed", projectile_speed)
	projectile.set("damage", attack_damage)
	projectile.set("shooter", self)
	get_tree().current_scene.add_child(projectile)

func _enter_hit_react() -> void:
	hit_react_timer = hit_react_duration
	if body_mesh:
		body_mesh.scale = Vector3(1.16, 0.85, 1.16)
	if _can_engage_player():
		var away: Vector3 = (global_position - tracked_player.global_position)
		away.y = 0.0
		if away.length_squared() > 0.001:
			velocity += away.normalized() * hit_react_knockback

func _face_towards(target_position: Vector3, delta: float) -> void:
	var to_target: Vector3 = target_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.001:
		return
	var yaw: float = atan2(to_target.x, to_target.z)
	rotation.y = lerp_angle(rotation.y, yaw, clampf(7.0 * delta, 0.0, 1.0))

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	awareness_area.monitoring = false
	if visual_root:
		visual_root.scale = Vector3(1.0, 0.25, 1.0)
	emit_signal("died", self)
	var timer: SceneTreeTimer = get_tree().create_timer(corpse_lifetime)
	timer.timeout.connect(queue_free)

func _on_awareness_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		tracked_player = body as CharacterBody3D

func _on_awareness_body_exited(body: Node) -> void:
	if body == tracked_player:
		tracked_player = null
