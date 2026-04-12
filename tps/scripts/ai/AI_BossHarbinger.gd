extends CharacterBody3D

signal died(enemy: Node3D)

@export var max_health: float = 450.0
@export var move_speed: float = 2.4
@export var acceleration: float = 6.0
@export var gravity_scale: float = 1.0
@export var detection_radius: float = 36.0
@export var phase_two_threshold: float = 0.62
@export var phase_three_threshold: float = 0.28
@export var strike_damage: float = 16.0
@export var nova_damage: float = 22.0
@export var strike_cooldown: float = 1.3
@export var nova_cooldown: float = 4.6
@export var corpse_lifetime: float = 4.0

@onready var visual_root: Node3D = $VisualRoot
@onready var awareness_area: Area3D = $Awareness
@onready var body_mesh: MeshInstance3D = $VisualRoot/BodyMesh

var gravity: float = 24.0
var health: float = 450.0
var is_dead: bool = false
var tracked_player: CharacterBody3D = null
var strike_timer: float = 0.0
var nova_timer: float = 1.8
var _phase: int = 1

func _ready() -> void:
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 24.0) * gravity_scale
	health = max_health
	var awareness_shape: CollisionShape3D = awareness_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if awareness_shape and awareness_shape.shape is SphereShape3D:
		(awareness_shape.shape as SphereShape3D).radius = detection_radius
	awareness_area.body_entered.connect(_on_awareness_body_entered)
	awareness_area.body_exited.connect(_on_awareness_body_exited)
	GameState.push_event_message("Boss contact: Harbinger of Ruin")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	strike_timer = maxf(0.0, strike_timer - delta)
	nova_timer = maxf(0.0, nova_timer - delta)
	_apply_gravity(delta)
	_update_phase()
	if not _can_engage_player():
		move_and_slide()
		return

	var to_player: Vector3 = tracked_player.global_position - global_position
	to_player.y = 0.0
	var distance_to_player: float = to_player.length()
	var desired_velocity: Vector3 = Vector3.ZERO
	if distance_to_player > 2.9:
		desired_velocity = to_player.normalized() * (move_speed + 0.3 * float(_phase - 1))
		_face_towards(global_position + to_player, delta)
	else:
		_try_strike_attack()
	_try_nova_attack(distance_to_player)

	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	horizontal_velocity = horizontal_velocity.lerp(desired_velocity, clampf(acceleration * delta, 0.0, 1.0))
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	move_and_slide()

func apply_damage(raw_damage: float) -> void:
	if is_dead or raw_damage <= 0.0:
		return
	var reduction: float = 1.0 - (0.06 * float(_phase - 1))
	health = maxf(0.0, health - raw_damage * reduction)
	if body_mesh:
		var flash_scale: float = 1.08 + (0.02 * float(_phase))
		body_mesh.scale = Vector3(flash_scale, 0.9, flash_scale)
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

func _try_strike_attack() -> void:
	if strike_timer > 0.0:
		return
	strike_timer = maxf(0.6, strike_cooldown - 0.15 * float(_phase - 1))
	if tracked_player and tracked_player.has_method("apply_damage"):
		tracked_player.apply_damage(strike_damage + 2.0 * float(_phase - 1), global_position)
		GameState.push_event_message("Harbinger strike impact!")

func _try_nova_attack(distance_to_player: float) -> void:
	if nova_timer > 0.0:
		return
	if distance_to_player > 8.4:
		return
	nova_timer = maxf(2.8, nova_cooldown - 0.3 * float(_phase - 1))
	if tracked_player and tracked_player.has_method("apply_damage"):
		tracked_player.apply_damage(nova_damage + 2.0 * float(_phase - 1), global_position)
	GameState.push_event_message("Plague nova released.")

func _face_towards(target_position: Vector3, delta: float) -> void:
	var to_target: Vector3 = target_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.001:
		return
	var yaw: float = atan2(to_target.x, to_target.z)
	rotation.y = lerp_angle(rotation.y, yaw, clampf(5.0 * delta, 0.0, 1.0))

func _update_phase() -> void:
	if max_health <= 0.0:
		return
	var ratio: float = health / max_health
	var new_phase: int = 1
	if ratio <= phase_three_threshold:
		new_phase = 3
	elif ratio <= phase_two_threshold:
		new_phase = 2
	if new_phase == _phase:
		return
	_phase = new_phase
	match _phase:
		2:
			GameState.push_event_message("Harbinger phase II: rage surge.")
		3:
			GameState.push_event_message("Harbinger phase III: final frenzy.")
	if body_mesh:
		body_mesh.scale = Vector3(1.0 + 0.05 * float(_phase), 1.0, 1.0 + 0.05 * float(_phase))

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	awareness_area.monitoring = false
	if visual_root:
		visual_root.scale = Vector3(1.2, 0.2, 1.2)
	GameState.push_event_message("Boss neutralized.")
	emit_signal("died", self)
	var timer: SceneTreeTimer = get_tree().create_timer(corpse_lifetime)
	timer.timeout.connect(queue_free)

func _on_awareness_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		tracked_player = body as CharacterBody3D

func _on_awareness_body_exited(body: Node) -> void:
	if body == tracked_player:
		tracked_player = null
