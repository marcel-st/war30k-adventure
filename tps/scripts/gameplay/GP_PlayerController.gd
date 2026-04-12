extends CharacterBody3D

@export var walk_speed: float = 4.6
@export var sprint_speed: float = 6.2
@export var acceleration: float = 11.0
@export var deceleration: float = 14.0
@export var rotation_speed: float = 14.0
@export var gravity_scale: float = 1.0
@export var mouse_sensitivity: float = 0.0019
@export var joy_look_sensitivity: float = 2.2
@export var max_health: float = 100.0
@export var max_armor: float = 100.0

@onready var camera_aim: Node3D = $CameraRig
@onready var boltgun: Node3D = $WeaponSocket/Boltgun
@onready var visual_root: Node3D = $VisualRoot

const TOXIC_HAZARD_SCENE: PackedScene = preload("res://scenes/gameplay/SCN_GP_ToxicHazard.tscn")

var gravity: float = 24.0
var health: float = 100.0
var armor: float = 100.0
var current_combat_move_speed_multiplier: float = 1.0
var _hit_reaction_timer: float = 0.0
var _hit_reaction_amount: float = 0.0
var _ability_speed_multiplier: float = 1.0
var _damage_reduction_ratio: float = 0.0
var _damage_reduction_timer: float = 0.0
var _hazard_resist_ratio: float = 0.0
var _hazard_resist_timer: float = 0.0
var _move_buff_bonus: float = 0.0
var _move_buff_timer: float = 0.0

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
	if AbilitySystem and AbilitySystem.has_method("set_player"):
		AbilitySystem.set_player(self)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_mission"):
		GameState.request_restart()
	if event.is_action_pressed("pause"):
		_toggle_mouse_capture()
	if event.is_action_pressed("ability_primary"):
		AbilitySystem.trigger_ability("resilience_surge")
	if event.is_action_pressed("ability_secondary"):
		AbilitySystem.trigger_ability("toxic_grenade")
	if event.is_action_pressed("ability_tertiary"):
		AbilitySystem.trigger_ability("rally_command")

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_tick_temporary_effects(delta)
	_process_movement(delta)
	_process_aim_rotation(delta)
	_process_combat()
	_update_hit_reaction_visual(delta)
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

	var target_speed: float = walk_speed
	if Input.is_action_pressed("sprint"):
		target_speed = sprint_speed
	target_speed *= current_combat_move_speed_multiplier
	target_speed *= (1.0 + _move_buff_bonus)

	var target_velocity: Vector3 = move_dir * target_speed
	var horiz_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var lerp_factor: float = clamp((acceleration if target_velocity.length_squared() > 0.01 else deceleration) * delta, 0.0, 1.0)
	horiz_velocity = horiz_velocity.lerp(target_velocity, lerp_factor)
	velocity.x = horiz_velocity.x
	velocity.z = horiz_velocity.z

func _process_aim_rotation(delta: float) -> void:
	var look_input: Vector2 = Vector2.ZERO
	look_input.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	look_input.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	if look_input.length_squared() > 0.0001:
		camera_aim.apply_stick_input(look_input * joy_look_sensitivity * delta)

	var move_vector: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if move_vector.length_squared() > 0.01:
		var target_yaw: float = atan2(move_vector.x, move_vector.z)
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

	current_combat_move_speed_multiplier = boltgun.get_move_speed_multiplier()
	_ability_speed_multiplier = AbilitySystem.get_move_speed_multiplier()
	current_combat_move_speed_multiplier *= _ability_speed_multiplier

func apply_damage(raw_damage: float, _source_position: Vector3 = Vector3.ZERO) -> void:
	if raw_damage <= 0.0 or health <= 0.0:
		return
	var mitigated_damage: float = raw_damage * (1.0 - _damage_reduction_ratio)
	var absorbed: float = min(armor, mitigated_damage * 0.65)
	armor -= absorbed
	health = max(0.0, health - (mitigated_damage - absorbed))
	_hit_reaction_timer = 0.12
	_hit_reaction_amount = minf(1.0, _hit_reaction_amount + 0.65)
	camera_aim.add_impact_shake(0.8)
	GameState.health = health
	GameState.armor = armor
	GameState.emit_player_stats()
	if health <= 0.0:
		GameState.mark_mission_failed()

func apply_damage_from_hazard(raw_damage: float, source_position: Vector3 = Vector3.ZERO) -> void:
	var mitigated: float = raw_damage * (1.0 - _hazard_resist_ratio)
	apply_damage(mitigated, source_position)

func add_bonus_armor(amount: float) -> void:
	if amount <= 0.0:
		return
	armor = minf(max_armor, armor + amount)
	GameState.armor = armor
	GameState.emit_player_stats()

func add_bonus_health(amount: float) -> void:
	if amount <= 0.0:
		return
	health = minf(max_health, health + amount)
	GameState.health = health
	GameState.emit_player_stats()

func _toggle_mouse_capture() -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _update_hit_reaction_visual(delta: float) -> void:
	if _hit_reaction_timer <= 0.0 and _hit_reaction_amount <= 0.001:
		if visual_root and visual_root.scale != Vector3.ONE:
			visual_root.scale = visual_root.scale.lerp(Vector3.ONE, clampf(delta * 14.0, 0.0, 1.0))
		return
	_hit_reaction_timer = maxf(0.0, _hit_reaction_timer - delta)
	_hit_reaction_amount = maxf(0.0, _hit_reaction_amount - delta * 2.0)
	var pulse: float = 1.0 - (0.07 * _hit_reaction_amount)
	if visual_root:
		visual_root.scale = visual_root.scale.lerp(Vector3(pulse, pulse, pulse), clampf(delta * 22.0, 0.0, 1.0))

func apply_temporary_damage_reduction(ratio: float, duration: float, hazard_resist_ratio: float = 0.0) -> void:
	_damage_reduction_ratio = clampf(maxf(_damage_reduction_ratio, ratio), 0.0, 0.8)
	_damage_reduction_timer = maxf(_damage_reduction_timer, duration)
	_hazard_resist_ratio = clampf(maxf(_hazard_resist_ratio, hazard_resist_ratio), 0.0, 0.9)
	_hazard_resist_timer = maxf(_hazard_resist_timer, duration)

func apply_temporary_move_buff(move_speed_bonus: float, duration: float) -> void:
	_move_buff_bonus = clampf(maxf(_move_buff_bonus, move_speed_bonus), 0.0, 0.5)
	_move_buff_timer = maxf(_move_buff_timer, duration)

func spawn_toxic_grenade(radius: float, damage_per_tick: float, duration: float) -> void:
	if TOXIC_HAZARD_SCENE == null:
		return
	var hazard: Node3D = TOXIC_HAZARD_SCENE.instantiate() as Node3D
	if hazard == null:
		return
	var forward: Vector3 = -global_basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		forward = Vector3.FORWARD
	var spawn_position: Vector3 = global_position + forward.normalized() * 4.2
	spawn_position.y = maxf(0.1, global_position.y)
	hazard.global_position = spawn_position
	if hazard.has_method("configure"):
		hazard.configure(radius, damage_per_tick, duration)
	if hazard.has_method("set_owner_node"):
		hazard.set_owner_node(self)
	get_tree().current_scene.add_child(hazard)
	GameState.push_event_message("Toxic hazard deployed.")

func _tick_temporary_effects(delta: float) -> void:
	if _damage_reduction_timer > 0.0:
		_damage_reduction_timer = maxf(0.0, _damage_reduction_timer - delta)
		if _damage_reduction_timer <= 0.0:
			_damage_reduction_ratio = 0.0
	if _hazard_resist_timer > 0.0:
		_hazard_resist_timer = maxf(0.0, _hazard_resist_timer - delta)
		if _hazard_resist_timer <= 0.0:
			_hazard_resist_ratio = 0.0
	if _move_buff_timer > 0.0:
		_move_buff_timer = maxf(0.0, _move_buff_timer - delta)
		if _move_buff_timer <= 0.0:
			_move_buff_bonus = 0.0
