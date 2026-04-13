extends CharacterBody3D

signal died(enemy: Node3D)

@export var max_health: float = 140.0
@export var move_speed: float = 2.6
@export var acceleration: float = 7.0
@export var gravity_scale: float = 1.0
@export var detection_radius: float = 30.0
@export var attack_radius: float = 3.0
@export var attack_damage: float = 16.0
@export var attack_cooldown: float = 1.8
@export var corpse_lifetime: float = 3.2
@export var hit_react_scale: float = 1.08

@onready var visual_root: Node3D = $VisualRoot
@onready var awareness_area: Area3D = $Awareness
@onready var body_mesh: MeshInstance3D = $VisualRoot/BodyMesh
@onready var command_aura: Area3D = get_node_or_null("CommandAura") as Area3D

var gravity: float = 24.0
var health: float = 140.0
var is_dead: bool = false
var attack_timer: float = 0.0
var tracked_player: CharacterBody3D = null
var _hit_flash_timer: float = 0.0
var _is_commander_active: bool = false

func _ready() -> void:
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 24.0) * gravity_scale
	health = max_health
	var awareness_shape: CollisionShape3D = awareness_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if awareness_shape and awareness_shape.shape is SphereShape3D:
		(awareness_shape.shape as SphereShape3D).radius = detection_radius
	awareness_area.body_entered.connect(_on_awareness_body_entered)
	awareness_area.body_exited.connect(_on_awareness_body_exited)
	if command_aura:
		command_aura.body_entered.connect(_on_command_aura_body_entered)
		command_aura.body_exited.connect(_on_command_aura_body_exited)
	add_to_group("traitor_commander")

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	attack_timer = maxf(0.0, attack_timer - delta)
	_update_hit_flash(delta)
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
			_try_slam_attack()

	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	horizontal_velocity = horizontal_velocity.lerp(desired_velocity, clampf(acceleration * delta, 0.0, 1.0))
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	move_and_slide()

func apply_damage(raw_damage: float) -> void:
	if is_dead or raw_damage <= 0.0:
		return
	health = maxf(0.0, health - raw_damage)
	_trigger_hit_flash()
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

func _try_slam_attack() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	if EventBus:
		EventBus.emit_event("combat.enemy_melee", {"enemy_type": "champion"})
	if tracked_player and tracked_player.has_method("apply_damage"):
		tracked_player.apply_damage(attack_damage, global_position)

func _face_towards(target_position: Vector3, delta: float) -> void:
	var to_target: Vector3 = target_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.001:
		return
	var yaw: float = atan2(to_target.x, to_target.z)
	rotation.y = lerp_angle(rotation.y, yaw, clampf(6.0 * delta, 0.0, 1.0))

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	awareness_area.monitoring = false
	if command_aura:
		command_aura.monitoring = false
	if visual_root:
		visual_root.scale = Vector3(1.15, 0.22, 1.15)
	if EventBus:
		EventBus.emit_event("combat.enemy_died", {"enemy_type": "champion"})
	emit_signal("died", self)
	var timer: SceneTreeTimer = get_tree().create_timer(corpse_lifetime)
	timer.timeout.connect(queue_free)

func _trigger_hit_flash() -> void:
	_hit_flash_timer = 0.14
	if body_mesh:
		body_mesh.scale = Vector3(hit_react_scale, 0.9, hit_react_scale)

func _update_hit_flash(delta: float) -> void:
	if _hit_flash_timer <= 0.0 or body_mesh == null:
		return
	_hit_flash_timer = maxf(0.0, _hit_flash_timer - delta)
	var blend: float = clampf(_hit_flash_timer / 0.14, 0.0, 1.0)
	body_mesh.scale = Vector3.ONE.lerp(Vector3(hit_react_scale, 0.9, hit_react_scale), blend)

func _on_awareness_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		tracked_player = body as CharacterBody3D

func _on_awareness_body_exited(body: Node) -> void:
	if body == tracked_player:
		tracked_player = null

func _on_command_aura_body_entered(body: Node) -> void:
	if not body or body == self:
		return
	if body.has_method("set_commander_aura_bonus"):
		body.set_commander_aura_bonus(1.12)
		_is_commander_active = true

func _on_command_aura_body_exited(body: Node) -> void:
	if not body or body == self:
		return
	if body.has_method("set_commander_aura_bonus"):
		body.set_commander_aura_bonus(1.0)
