extends Node3D
## Sky backdrop for the 3D world. A quad fixed to the camera shows a gradient and stars.
## Colours and star amount come from res://data/stages_visual.json.
## On start and on a stage change, the shader values tween over 1 s.

const DATA_PATH: String = "res://data/stages_visual.json"
const SHADER_PATH: String = "res://scenes/world/sky.gdshader"
const CAMERA_FAR: float = 2000.0
# Distance of the quad from the camera. It must be less than CAMERA_FAR.
const QUAD_DISTANCE: float = 900.0
# The quad is this much larger than the view, so no edge shows.
const QUAD_MARGIN: float = 1.2
const TWEEN_TIME: float = 1.0
const DEFAULT_TOP: String = "#4FA8E0"
const DEFAULT_BOTTOM: String = "#BFE6F7"

var _world: World
var _mat: ShaderMaterial
var _data: Dictionary = {}
var _shown_stage: String = ""
var _tween: Tween


func _ready() -> void:
	_world = get_parent() as World
	_data = _load_data()
	var cam: Camera3D = _world.camera()
	cam.far = CAMERA_FAR
	_mat = ShaderMaterial.new()
	_mat.shader = load(SHADER_PATH)
	_mat.set_shader_parameter("top_color", Color(DEFAULT_TOP))
	_mat.set_shader_parameter("bottom_color", Color(DEFAULT_BOTTOM))
	_mat.set_shader_parameter("star_amount", 0.0)
	_add_quad(cam)
	EventBus.division_changed.connect(_on_division_event)
	EventBus.state_loaded.connect(_on_state_event)
	_sync_sky()


func _on_division_event(_id: String) -> void:
	_sync_sky()


func _on_state_event() -> void:
	_sync_sky()


func _load_data() -> Dictionary:
	var raw: Variant = DataLoader.load_json(DATA_PATH)
	if raw is Dictionary:
		return raw
	return {}


func _add_quad(cam: Camera3D) -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = _quad_size(cam)
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "SkyQuad"
	mi.mesh = quad
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0.0, 0.0, -QUAD_DISTANCE)
	cam.add_child(mi)


# Size of the quad at QUAD_DISTANCE, so that it covers the whole view.
func _quad_size(cam: Camera3D) -> Vector2:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var aspect: float = view.x / view.y
	var half_fov: float = deg_to_rad(cam.fov) * 0.5
	var half_h: float = 0.0
	var half_w: float = 0.0
	if cam.keep_aspect == Camera3D.KEEP_WIDTH:
		half_w = QUAD_DISTANCE * tan(half_fov)
		half_h = half_w / aspect
	else:
		half_h = QUAD_DISTANCE * tan(half_fov)
		half_w = half_h * aspect
	return Vector2(half_w, half_h) * 2.0 * QUAD_MARGIN


func _sync_sky() -> void:
	var stage: String = _world.current_stage()
	if stage == _shown_stage:
		return
	_shown_stage = stage
	var entry: Dictionary = _data.get(stage, {})
	if entry.is_empty():
		push_warning("sky: no visual data for stage %s" % stage)
		return
	var top: Color = Color(str(entry.get("sky_top", DEFAULT_TOP)))
	var bottom: Color = Color(str(entry.get("sky_bottom", DEFAULT_BOTTOM)))
	var stars: float = float(entry.get("star_amount", 0.0))
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_mat, "shader_parameter/top_color", top, TWEEN_TIME)
	_tween.tween_property(_mat, "shader_parameter/bottom_color", bottom, TWEEN_TIME)
	_tween.tween_property(_mat, "shader_parameter/star_amount", stars, TWEEN_TIME)
