extends Node3D

@export var max_magazine_size: int = 30
@export var fire_rate: float = 9.0
@export var reload_duration: float = 1.8
@export var damage: float = 20.0
@export var range: float = 180.0

@onready var muzzle_marker: Marker3D = $Muzzle

var _fire_cooldown: float = 0.0
var _reload_timer: float = 0.0
var _is_reloading: bool = false

func _ready() -> void:
	GameState.configure_ammo(max_magazine_size, 120)

func _physics_process(delta: float) -> void:
	_fire_cooldown = max(0.0, _fire_cooldown - delta)
	if _is_reloading:
		_reload_timer = max(0.0, _reload_timer - delta)
		if _reload_timer <= 0.0:
			_is_reloading = false
			GameState.reload_magazine(max_magazine_size)
		return
	if Input.is_action_just_pressed("reload"):
		start_reload()

func trigger_fire(camera: Camera3D) -> void:
	if _is_reloading or _fire_cooldown > 0.0:
		return
	if not GameState.consume_round():
		start_reload()
		return
	_fire_cooldown = 1.0 / max(0.1, fire_rate)
	var from: Vector3 = camera.global_position
	var to: Vector3 = from + (-camera.global_basis.z * range)
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var hit: Dictionary = space_state.intersect_ray(query)
	if hit.has("position"):
		var impact: Vector3 = hit["position"] as Vector3
		_spawn_debug_tracer(from, impact)
		var collider: Variant = hit.get("collider")
		if collider and collider.has_method("apply_damage"):
			collider.apply_damage(damage)
	else:
		_spawn_debug_tracer(from, to)

func start_reload() -> void:
	if _is_reloading:
		return
	if GameState.ammo_in_magazine >= max_magazine_size or GameState.ammo_reserve <= 0:
		return
	_is_reloading = true
	_reload_timer = reload_duration

func _spawn_debug_tracer(start: Vector3, finish: Vector3) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var tracer: ImmediateMesh = ImmediateMesh.new()
	tracer.surface_begin(Mesh.PRIMITIVE_LINES)
	tracer.surface_set_color(Color(1.0, 0.8, 0.3, 1.0))
	tracer.surface_add_vertex(to_local(start))
	tracer.surface_add_vertex(to_local(finish))
	tracer.surface_end()
	mesh_instance.mesh = tracer
	add_child(mesh_instance)
	var timer: SceneTreeTimer = get_tree().create_timer(0.08)
	timer.timeout.connect(mesh_instance.queue_free)
