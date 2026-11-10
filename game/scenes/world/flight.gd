class_name Flight
extends Node

## Visual flight animation for the selected division. Listens to EventBus only.
## Never changes game state and never delays game logic.

signal lifted_off(id: String)
signal landed(id: String, revenue: float, apogee: float)

const LAUNCH_HEIGHT: float = 30.0
const LAUNCH_MIN_SECONDS: float = 0.4
const LAUNCH_MAX_SECONDS: float = 2.5
const QUICK_FLIGHT_LIMIT: float = 0.5
const HOP_HEIGHT: float = 0.5
const HOP_SECONDS: float = 0.2
const HOP_INTERVAL: float = 0.25
const POP_START_RATIO: float = 0.6
const POP_SECONDS: float = 0.15

var _world: World
var _vehicle: Node3D
var _base_scale: Vector3 = Vector3.ONE
var _move_tween: Tween
var _pop_tween: Tween
var _hop_cooldown: float = 0.0
var _last_stage: String = ""


func _ready() -> void:
	_world = get_parent() as World
	if _world != null:
		_last_stage = _world.current_stage()
	EventBus.launch_started.connect(_on_launch_started)
	EventBus.launch_finished.connect(_on_launch_finished)
	EventBus.division_changed.connect(_on_division_changed)


func _process(delta: float) -> void:
	_hop_cooldown = maxf(0.0, _hop_cooldown - delta)


func _on_launch_started(id: String) -> void:
	if id != GameState.selected_division:
		return
	lifted_off.emit(id)
	var veh: Node3D = _get_vehicle()
	if veh == null:
		return
	var flight: float = GameState.flight_time(id)
	if flight < QUICK_FLIGHT_LIMIT:
		_play_hop(veh)
		return
	_stop_all(veh)
	var seconds: float = clampf(flight, LAUNCH_MIN_SECONDS, LAUNCH_MAX_SECONDS)
	_move_tween = create_tween()
	_move_tween.tween_property(veh, "position:y", LAUNCH_HEIGHT, seconds) \
		.from(0.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _on_launch_finished(id: String, revenue: float, apogee: float) -> void:
	if id != GameState.selected_division:
		return
	var veh: Node3D = _get_vehicle()
	if veh != null:
		_stop_all(veh)
		veh.scale = _base_scale * POP_START_RATIO
		_pop_tween = create_tween()
		_pop_tween.tween_property(veh, "scale", _base_scale, POP_SECONDS)
	landed.emit(id, revenue, apogee)


func _on_division_changed(_id: String) -> void:
	if _world == null:
		return
	var stage: String = _world.current_stage()
	if stage == _last_stage:
		return
	_last_stage = stage
	var veh: Node3D = _get_vehicle()
	if veh != null:
		_stop_all(veh)


func _play_hop(veh: Node3D) -> void:
	if _hop_cooldown > 0.0:
		return
	_hop_cooldown = HOP_INTERVAL
	_stop_all(veh)
	var half: float = HOP_SECONDS * 0.5
	_move_tween = create_tween()
	_move_tween.tween_property(veh, "position:y", HOP_HEIGHT, half) \
		.from(0.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(veh, "position:y", 0.0, half) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


# Kills running tweens and puts the vehicle back on the pad.
func _stop_all(veh: Node3D) -> void:
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	veh.position.y = 0.0
	veh.scale = _base_scale


# World may not have built its vehicle yet when this node is ready.
# Bind on first use instead.
func _get_vehicle() -> Node3D:
	if _vehicle == null and _world != null:
		_vehicle = _world.vehicle()
		if _vehicle != null:
			_base_scale = _vehicle.scale
	return _vehicle
