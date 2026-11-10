class_name World
extends Node3D

## 3D launch scene. Shows the site and the vehicle of the selected division.
## Built in _ready(). Models come from res://assets/models/.

const SITE_PATH_FORMAT: String = "res://assets/models/site_%s.glb"
const VEHICLE_PATH_FORMAT: String = "res://assets/models/vehicle_%s.glb"

# Camera. Side-on view along -Z. Tune these numbers here.
const CAM_POS: Vector3 = Vector3(0.0, 6.0, 34.0)
# Aim point so the launch point (origin) sits about 35 % from the top of the screen.
const CAM_LOOK_AT: Vector3 = Vector3(0.0, -4.0, 0.0)
## Vehicles are modelled 2 m tall. The sites are built for a larger vehicle, so scale it up.
const VEHICLE_SCALE: float = 2.2
const CAM_FOV: float = 40.0

const SKY_COLOR: Color = Color("87CEEB")
const AMBIENT_ENERGY: float = 0.7
const SUN_ROTATION_DEG: Vector3 = Vector3(-50.0, -30.0, 0.0)
const SUN_ENERGY: float = 1.2

# Grey placeholder boxes, used when a model file is missing.
const PLACEHOLDER_GREY: Color = Color(0.5, 0.5, 0.5)
const PLACEHOLDER_VEHICLE_SIZE: Vector3 = Vector3(1.0, 2.0, 1.0)
const PLACEHOLDER_SITE_SIZE: Vector3 = Vector3(12.0, 0.5, 6.0)

var _camera: Camera3D
var _site_root: Node3D
var _vehicle_root: Node3D
var _stage: String = ""


func _ready() -> void:
	_build_environment()
	_build_camera()
	_build_light()
	_site_root = Node3D.new()
	_site_root.name = "SiteRoot"
	add_child(_site_root)
	_vehicle_root = Node3D.new()
	_vehicle_root.name = "VehicleRoot"
	_vehicle_root.scale = Vector3.ONE * VEHICLE_SCALE
	add_child(_vehicle_root)
	set_stage(GameState.selected_division)
	EventBus.division_changed.connect(_on_division_event)
	EventBus.state_loaded.connect(_on_state_event)


func set_stage(id: String) -> void:
	_clear(_site_root)
	_clear(_vehicle_root)
	_stage = id
	_add_model(_site_root, SITE_PATH_FORMAT % id, false)
	_add_model(_vehicle_root, VEHICLE_PATH_FORMAT % id, true)


func vehicle() -> Node3D:
	return _vehicle_root


func camera() -> Camera3D:
	return _camera


func current_stage() -> String:
	return _stage


func _on_division_event(_id: String) -> void:
	_sync_stage()


func _on_state_event() -> void:
	_sync_stage()


func _sync_stage() -> void:
	var id: String = GameState.selected_division
	if id == _stage:
		return
	set_stage(id)


func _build_environment() -> void:
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = AMBIENT_ENERGY
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.fov = CAM_FOV
	add_child(_camera)
	_camera.position = CAM_POS
	_camera.look_at(CAM_LOOK_AT, Vector3.UP)
	_camera.current = true


func _build_light() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = SUN_ENERGY
	sun.shadow_enabled = false
	add_child(sun)
	sun.rotation_degrees = SUN_ROTATION_DEG


func _clear(root: Node3D) -> void:
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()


func _add_model(root: Node3D, path: String, is_vehicle: bool) -> void:
	if ResourceLoader.exists(path):
		var scene: PackedScene = load(path) as PackedScene
		if scene != null:
			root.add_child(scene.instantiate())
			return
	if is_vehicle:
		root.add_child(_placeholder_vehicle())
	else:
		root.add_child(_placeholder_site())


func _placeholder_vehicle() -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = PLACEHOLDER_VEHICLE_SIZE
	return _placeholder_box(box, Vector3(0.0, PLACEHOLDER_VEHICLE_SIZE.y * 0.5, 0.0))


func _placeholder_site() -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = PLACEHOLDER_SITE_SIZE
	return _placeholder_box(box, Vector3(0.0, PLACEHOLDER_SITE_SIZE.y * 0.5, 0.0))


func _placeholder_box(box: BoxMesh, pos: Vector3) -> MeshInstance3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = PLACEHOLDER_GREY
	box.material = mat
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "Placeholder"
	mi.mesh = box
	mi.position = pos
	return mi
