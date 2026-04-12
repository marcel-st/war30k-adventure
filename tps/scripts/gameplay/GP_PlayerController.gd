extends CharacterBody3D

@export var walk_speed: float = 5.2
@export var sprint_speed: float = 7.8
@export var acceleration: float = 18.0
@export var rotation_speed: float = 14.0
@export var gravity_scale: float = 1.0
@export var mouse_sensitivity: float = 0.0019
@export var joy_look_sensitivity: float = 2.2
@export var max_health: float = 100.0
@export var max_armor: float = 100.0

@onready var camera_aim: Node3D = $CameraRig
@onready var boltgun: Node3D = $WeaponSocket/Boltgun

var gravity: float = 24.0
var health: float = 100.0
var armor: float = 100.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 24.0) * gravity_scale
	health = max_health
	armor = max_armor
	add_to_group("player")
	GameState.health = health
	GameState.armor = armor
	GameState.configure_ammo(30, 120)
	GameState.emit_player_stats()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_mouse_capture()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_process_movement(delta)
	_process_aim_rotation(delta)
	_process_combat()
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

func _process_movement(delta: float) -> void:
	var input_2d: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var basis: Basis = camera_aim.get_move_basis()
	var move_dir: Vector3 = (basis.x * input_2d.x + -basis.z * input_2d.y)
	move_dir.y = 0.0
	move_dir = move_dir.normalized()

	var target_speed := walk_speed
	if Input.is_action_pressed("sprint"):
		target_speed = sprint_speed

	var target_velocity: Vector3 = move_dir * target_speed
	var horiz_velocity := Vector3(velocity.x, 0.0, velocity.z)
	horiz_velocity = horiz_velocity.lerp(target_velocity, clamp(acceleration * delta, 0.0, 1.0))
	velocity.x = horiz_velocity.x
	velocity.z = horiz_velocity.z

func _process_aim_rotation(delta: float) -> void:
	var look_input := Vector2.ZERO
	look_input.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	look_input.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	if look_input.length_squared() > 0.0001:
		camera_aim.apply_stick_input(look_input * joy_look_sensitivity * delta)

	var move_vector := Vector3(velocity.x, 0.0, velocity.z)
	if move_vector.length_squared() > 0.01:
		var target_yaw := atan2(move_vector.x, move_vector.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, clamp(rotation_speed * delta, 0.0, 1.0))

func _process_combat() -> void:
	if Input.is_action_pressed("aim"):
		camera_aim.set_aiming(true)
	else:
		camera_aim.set_aiming(false)

	if Input.is_action_pressed("fire"):
		boltgun.trigger_fire(camera_aim.get_camera())

	if Input.is_action_just_pressed("reload"):
		boltgun.start_reload()

func apply_damage(raw_damage: float) -> void:
	if raw_damage <= 0.0 or health <= 0.0:
		return
	var absorbed: float = min(armor, raw_damage * 0.65)
	armor -= absorbed
	health = max(0.0, health - (raw_damage - absorbed))
	GameState.health = health
	GameState.armor = armor
	GameState.emit_player_stats()

func _toggle_mouse_capture() -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
