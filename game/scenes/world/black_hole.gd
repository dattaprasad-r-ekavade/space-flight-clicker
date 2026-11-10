extends Node3D

# Black hole backdrop. Shown in stage "black_hole" and in the cinematic.

const HOLE_POS: Vector3 = Vector3(2.5, 13.0, -14.0)
const QUAD_SIZE: float = 14.0
const SHADER_PATH: String = "res://scenes/world/black_hole.gdshader"
const STAGE_ID: String = "black_hole"

var _world: World = null
var _quad: MeshInstance3D = null
var _material: ShaderMaterial = null
var _forced: bool = false


func _ready() -> void:
	_world = get_parent() as World
	position = HOLE_POS
	_build_quad()
	EventBus.division_changed.connect(_on_division_changed)
	EventBus.state_loaded.connect(_on_state_loaded)
	call_deferred("_refresh")


func _build_quad() -> void:
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(QUAD_SIZE, QUAD_SIZE)
	var shader: Shader = load(SHADER_PATH) as Shader
	_material = ShaderMaterial.new()
	_material.shader = shader
	_quad = MeshInstance3D.new()
	_quad.mesh = mesh
	_quad.material_override = _material
	_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_quad)


func _process(_delta: float) -> void:
	if not visible or _quad == null or _world == null:
		return
	var cam: Camera3D = _world.camera()
	if cam == null:
		return
	var target: Vector3 = cam.global_position
	_quad.look_at(target)
	# QuadMesh faces +Z. After look_at, +Z points away from the camera.
	var to_cam: Vector3 = (target - _quad.global_position).normalized()
	if _quad.global_transform.basis.z.dot(to_cam) < 0.0:
		_quad.rotate_object_local(Vector3.UP, PI)


func _on_division_changed(_id: String) -> void:
	_refresh()


func _on_state_loaded() -> void:
	_refresh()


func _refresh() -> void:
	var want: bool = _forced
	if _world != null and _world.current_stage() == STAGE_ID:
		want = true
	if visible != want:
		visible = want


func show_for_cinematic(on: bool) -> void:
	_forced = on
	_refresh()


func set_growth(t: float) -> void:
	if _material == null:
		return
	_material.set_shader_parameter("growth", clampf(t, 0.0, 1.0))
