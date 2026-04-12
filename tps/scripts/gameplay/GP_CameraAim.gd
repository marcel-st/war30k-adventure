extends Node3D

@export var mouse_sensitivity := 0.0025
@export var stick_sensitivity := 2.2
@export var min_pitch_deg := -55.0
@export var max_pitch_deg := 65.0
@export var default_arm_length := 4.4
@export var aim_arm_length := 2.2
@export var default_fov := 75.0
@export var aim_fov := 58.0
@export var transition_speed := 10.0

@onready var _pitch: Node3D = $Pivot
@onready var _spring_arm: SpringArm3D = $Pivot/SpringArm3D
@onready var _camera: Camera3D = $Pivot/SpringArm3D/Camera3D

var _pitch_radians := 0.0
var _is_aiming: bool = false

func _ready() -> void:
	_pitch_radians = _pitch.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		apply_mouse_input(event.relative * mouse_sensitivity)

func _process(delta: float) -> void:
	var stick_look := Vector2(
		Input.get_axis("look_left", "look_right"),
		Input.get_axis("look_up", "look_down")
	)
	if stick_look.length() > 0.01:
		rotation.y -= stick_look.x * stick_sensitivity * delta
		_pitch_radians = clamp(
			_pitch_radians + stick_look.y * stick_sensitivity * delta,
			deg_to_rad(min_pitch_deg),
			deg_to_rad(max_pitch_deg)
		)
		_pitch.rotation.x = _pitch_radians

	var aiming := _is_aiming or Input.is_action_pressed("aim")
	var target_length := aim_arm_length if aiming else default_arm_length
	var target_fov := aim_fov if aiming else default_fov
	_spring_arm.spring_length = lerp(_spring_arm.spring_length, target_length, delta * transition_speed)
	_camera.fov = lerp(_camera.fov, target_fov, delta * transition_speed)

func set_aiming(is_aiming: bool) -> void:
	_is_aiming = is_aiming

func apply_mouse_input(relative: Vector2) -> void:
	rotation.y -= relative.x
	_pitch_radians = clamp(
		_pitch_radians - relative.y,
		deg_to_rad(min_pitch_deg),
		deg_to_rad(max_pitch_deg)
	)
	_pitch.rotation.x = _pitch_radians

func apply_stick_input(look_delta: Vector2) -> void:
	rotation.y -= look_delta.x
	_pitch_radians = clamp(
		_pitch_radians + look_delta.y,
		deg_to_rad(min_pitch_deg),
		deg_to_rad(max_pitch_deg)
	)
	_pitch.rotation.x = _pitch_radians

func get_move_basis() -> Basis:
	# Movement is yaw-only so forward input remains stable on slopes.
	return Basis(Vector3.UP, rotation.y)

func get_aim_direction() -> Vector3:
	return -_camera.global_transform.basis.z.normalized()

func get_camera() -> Camera3D:
	return _camera
