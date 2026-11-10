extends Node3D
## Exhaust trail behind the vehicle. One CPUParticles3D, world space.
## Trail kind and colour come from res://data/stages_visual.json.

const DATA_PATH: String = "res://data/stages_visual.json"
const MAX_PARTICLES: int = 150
const MAX_EMIT_TIME: float = 3.0
const DIRECTION: Vector3 = Vector3(0.0, -1.0, 0.0)
const FLAME_HOT: Color = Color(1.0, 1.0, 0.7, 1.0)

var _particles: CPUParticles3D
var _flight: Node = null
var _visual: Dictionary = {}
var _preset_stage: String = ""
var _emitting: bool = false
var _emit_left: float = 0.0


func _ready() -> void:
	_particles = CPUParticles3D.new()
	_particles.emitting = false
	_particles.local_coords = false
	_particles.one_shot = false
	_particles.gravity = Vector3.ZERO
	add_child(_particles)
	var raw: Variant = DataLoader.load_json(DATA_PATH)
	if raw is Dictionary:
		_visual = raw
	EventBus.division_changed.connect(_on_division_changed)
	EventBus.state_loaded.connect(_on_state_loaded)
	call_deferred("_find_flight")
	call_deferred("_refresh_stage")


func _process(delta: float) -> void:
	if not _emitting:
		return
	_emit_left -= delta
	if _emit_left <= 0.0:
		_stop()
		return
	var world: World = get_parent() as World
	if world == null:
		return
	var vehicle_node: Node3D = world.vehicle()
	if vehicle_node != null:
		_particles.global_position = vehicle_node.global_position


func apply_preset(preset: String, color: Color) -> void:
	_particles.scale_amount_curve = null
	match preset:
		"smoke":
			_setup(40, 1.2, 45.0, 0.5, 1.5, 0.8, 1.0, Vector2(0.8, 0.8), 0.1)
			_particles.scale_amount_curve = _grow_curve()
			_particles.color_ramp = _ramp(
				PackedColorArray([_alpha(color, 0.6), _alpha(color, 0.35), _alpha(color, 0.0)]),
				PackedFloat32Array([0.0, 0.5, 1.0]))
		"flame":
			_setup(60, 0.5, 8.0, 2.0, 3.0, 0.5, 0.7, Vector2(0.35, 0.35), 0.0)
			_particles.color_ramp = _ramp(
				PackedColorArray([FLAME_HOT, _alpha(color, 1.0), _alpha(color, 0.0)]),
				PackedFloat32Array([0.0, 0.4, 1.0]))
		"plasma":
			_setup(60, 0.6, 5.0, 1.5, 2.5, 0.8, 1.2, Vector2(0.2, 0.2), 0.0)
			_particles.color_ramp = _ramp(
				PackedColorArray([Color(1.0, 1.0, 1.0, 1.0), _alpha(color, 1.0), _alpha(color, 0.0)]),
				PackedFloat32Array([0.0, 0.4, 1.0]))
		"warp":
			_setup(30, 0.3, 2.0, 6.0, 9.0, 1.0, 1.0, Vector2(0.08, 0.5), 0.0)
			_particles.color_ramp = _ramp(
				PackedColorArray([_alpha(color, 1.0), _alpha(color, 0.0)]),
				PackedFloat32Array([0.0, 1.0]))
		_:
			# "puff" and any unknown name.
			_setup(12, 0.5, 25.0, 0.3, 0.6, 1.0, 1.4, Vector2(1.2, 1.2), 0.1)
			_particles.color_ramp = _ramp(
				PackedColorArray([_alpha(color, 0.8), _alpha(color, 0.4), _alpha(color, 0.0)]),
				PackedFloat32Array([0.0, 0.3, 1.0]))


func _setup(amount: int, lifetime: float, spread: float, vel_min: float, vel_max: float,
		scale_min: float, scale_max: float, size: Vector2, radius: float) -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var quad: QuadMesh = QuadMesh.new()
	quad.size = size
	quad.material = mat
	_particles.mesh = quad
	_particles.amount = mini(amount, MAX_PARTICLES)
	_particles.lifetime = lifetime
	_particles.direction = DIRECTION
	_particles.spread = spread
	_particles.initial_velocity_min = vel_min
	_particles.initial_velocity_max = vel_max
	_particles.scale_amount_min = scale_min
	_particles.scale_amount_max = scale_max
	_particles.color = Color.WHITE
	_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE if radius > 0.0 else CPUParticles3D.EMISSION_SHAPE_POINT
	_particles.emission_sphere_radius = radius


func _ramp(colors: PackedColorArray, offsets: PackedFloat32Array) -> Gradient:
	var gradient: Gradient = Gradient.new()
	gradient.colors = colors
	gradient.offsets = offsets
	return gradient


func _grow_curve() -> Curve:
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(1.0, 1.0))
	return curve


func _alpha(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


func _find_flight() -> void:
	var flight: Flight = get_parent().get_node_or_null("Flight") as Flight
	if flight == null:
		return
	if not flight.lifted_off.is_connected(_on_lifted_off):
		flight.lifted_off.connect(_on_lifted_off)
	if not flight.landed.is_connected(_on_landed):
		flight.landed.connect(_on_landed)


func _refresh_stage() -> void:
	var world: World = get_parent() as World
	if world == null:
		return
	var stage: String = world.current_stage()
	if stage == _preset_stage or not _visual.has(stage):
		return
	_preset_stage = stage
	var row: Dictionary = _visual[stage] as Dictionary
	var kind: String = str(row.get("trail", "puff"))
	var color: Color = Color.html(str(row.get("trail_color", "#FFFFFF")))
	apply_preset(kind, color)


func _start() -> void:
	_refresh_stage()
	_emitting = true
	_emit_left = MAX_EMIT_TIME
	_particles.emitting = true


func _stop() -> void:
	_emitting = false
	_particles.emitting = false


func _on_lifted_off(_id: String) -> void:
	_start()


func _on_landed(_id: String, _revenue: float, _apogee: float) -> void:
	_stop()


func _on_division_changed(_id: String) -> void:
	call_deferred("_refresh_stage")


func _on_state_loaded() -> void:
	call_deferred("_refresh_stage")
