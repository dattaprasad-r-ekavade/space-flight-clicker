extends Node3D
## World part: the kid who works the pump in stage 1 (bottles).
## Shown only while World.current_stage() == "bottles".
## Each new fuel tap plays a short arm motion.

const MODEL_PATH: String = "res://assets/models/kid.glb"
const KID_POSITION: Vector3 = Vector3(-2.2, 0.0, 0.5)
const KID_SCALE: float = 2.2
const STAGE_ID: String = "bottles"
const DIVISION_ID: String = "bottles"
const TAPS_KEY: String = "fuel_taps"
const PUMP_TIME: float = 0.15
const PUMP_ANGLE_DEG: float = -70.0

var _world: World = null
var _model: Node3D = null
var _arm_l: Node3D = null
var _arm_r: Node3D = null
var _arm_l_base: float = 0.0
var _arm_r_base: float = 0.0
var _tween: Tween = null
var _last_taps: int = -1
var _last_visible: bool = false


func _ready() -> void:
	position = KID_POSITION
	scale = Vector3.ONE * KID_SCALE
	_world = get_parent() as World
	_load_model()
	EventBus.division_changed.connect(_on_division_changed)
	EventBus.state_loaded.connect(_on_state_loaded)
	_last_taps = _fuel_taps()
	_refresh_visibility()


func _load_model() -> void:
	if not ResourceLoader.exists(MODEL_PATH):
		return
	var scene: PackedScene = load(MODEL_PATH) as PackedScene
	if scene == null:
		return
	_model = scene.instantiate() as Node3D
	if _model == null:
		return
	add_child(_model)
	_arm_l = _model.find_child("arm_l", true, false) as Node3D
	_arm_r = _model.find_child("arm_r", true, false) as Node3D
	if _arm_l != null:
		_arm_l_base = _arm_l.rotation_degrees.x
	if _arm_r != null:
		_arm_r_base = _arm_r.rotation_degrees.x


func _is_bottles() -> bool:
	return _world != null and _world.current_stage() == STAGE_ID


func _refresh_visibility() -> void:
	var show_kid: bool = _is_bottles()
	if show_kid == _last_visible:
		return
	_last_visible = show_kid
	visible = show_kid


func _fuel_taps() -> int:
	var bottles: Dictionary = GameState.divisions.get(DIVISION_ID, {})
	var value: Variant = bottles.get(TAPS_KEY, 0)
	return int(value)


func _on_division_changed(id: String) -> void:
	_refresh_visibility()
	if id != DIVISION_ID:
		return
	var taps: int = _fuel_taps()
	if taps == _last_taps:
		return
	_last_taps = taps
	if _is_bottles():
		_play_pump()


func _on_state_loaded() -> void:
	_last_taps = _fuel_taps()
	_refresh_visibility()


func _play_pump() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_set_arm_angle(_arm_l, _arm_l_base)
	_set_arm_angle(_arm_r, _arm_r_base)
	if _arm_l == null and _arm_r == null:
		return
	var half: float = PUMP_TIME * 0.5
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween_arm(_arm_l, _arm_l_base + PUMP_ANGLE_DEG, half)
	_tween_arm(_arm_r, _arm_r_base + PUMP_ANGLE_DEG, half)
	_tween.chain()
	_tween_arm(_arm_l, _arm_l_base, half)
	_tween_arm(_arm_r, _arm_r_base, half)


func _tween_arm(arm: Node3D, angle: float, duration: float) -> void:
	if arm == null:
		return
	_tween.tween_property(arm, "rotation_degrees:x", angle, duration)


func _set_arm_angle(arm: Node3D, angle: float) -> void:
	if arm == null:
		return
	var rot: Vector3 = arm.rotation_degrees
	rot.x = angle
	arm.rotation_degrees = rot
