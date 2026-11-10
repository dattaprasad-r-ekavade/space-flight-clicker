class_name CinematicPrestige
extends Node3D

## Prestige cinematic (6 s). The craft nears the black hole, the screen fades
## to white, and the "Life N" title shows. Skippable after the first viewing.
## This node does not change game state. The popup calls play() and waits
## for finished, then performs the prestige itself.

signal finished

const APPROACH_TIME: float = 2.0
const COLLAPSE_TIME: float = 1.5
const WHITE_TIME: float = 1.0
const LABEL_FADE_TIME: float = 0.5
const HOLD_END: float = 6.0
const FADE_OUT_TIME: float = 0.6
const RISE_HEIGHT: float = 14.0
const APPROACH_X: float = 2.5
const SHRINK_SCALE: float = 0.05
const GROWTH_MID: float = 0.6
const GROWTH_END: float = 1.0
const FOV_END: float = 25.0
const SEEN_KEY: String = "seen_cinematic"
const BLACK_HOLE_NAME: String = "BlackHole"
const LAYER_INDEX: int = 50

var _world: World = null
var _black_hole: Node = null
var _layer: CanvasLayer = null
var _rect: ColorRect = null
var _label: Label = null
var _tween: Tween = null
var _playing: bool = false
var _rest_pos: Vector3 = Vector3.ZERO
var _base_scale: Vector3 = Vector3.ONE
var _old_fov: float = 0.0


func _ready() -> void:
	_world = get_parent() as World
	var parent: Node = get_parent()
	if parent != null:
		_black_hole = parent.get_node_or_null(BLACK_HOLE_NAME)

	_layer = CanvasLayer.new()
	_layer.layer = LAYER_INDEX
	add_child(_layer)

	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.color = Color.WHITE
	_rect.modulate.a = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.gui_input.connect(_on_gui_input)
	_layer.add_child(_rect)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color.BLACK)
	_label.add_theme_font_size_override("font_size", UiTheme.FONT_TITLE)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.modulate.a = 0.0
	_layer.add_child(_label)


## Start the cinematic. Does nothing if it already runs.
func play() -> void:
	if _playing:
		return
	_playing = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_store_base_values()
	_set_growth(0.0)
	_show_black_hole(true)

	_tween = create_tween()
	_tween.tween_method(_approach, 0.0, 1.0, APPROACH_TIME)
	_tween.tween_method(_collapse, 0.0, 1.0, COLLAPSE_TIME)
	_tween.tween_property(_rect, "modulate:a", 1.0, WHITE_TIME)
	_tween.tween_callback(_apply_reset)
	_tween.tween_property(_label, "modulate:a", 1.0, LABEL_FADE_TIME)
	_tween.tween_interval(HOLD_END - APPROACH_TIME - COLLAPSE_TIME - WHITE_TIME - LABEL_FADE_TIME)
	_tween.tween_callback(_on_natural_end)


func _store_base_values() -> void:
	var veh: Node3D = _vehicle()
	if veh != null:
		_rest_pos = veh.position
		_base_scale = veh.scale
	var cam: Camera3D = _camera()
	if cam != null:
		_old_fov = cam.fov


# 0-2 s: rise, move toward the black hole, growth 0 -> 0.6.
func _approach(t: float) -> void:
	var veh: Node3D = _vehicle()
	if veh != null:
		veh.position = _rest_pos + Vector3(APPROACH_X * t, RISE_HEIGHT * t, 0.0)
	_set_growth(GROWTH_MID * t)


# 2-3.5 s: shrink, growth 0.6 -> 1.0, camera fov eases to 25.
func _collapse(t: float) -> void:
	var veh: Node3D = _vehicle()
	if veh != null:
		veh.scale = _base_scale.lerp(_base_scale * SHRINK_SCALE, t)
	_set_growth(lerpf(GROWTH_MID, GROWTH_END, t))
	var cam: Camera3D = _camera()
	if cam != null:
		cam.fov = lerpf(_old_fov, FOV_END, t)


# 4.5 s, under the white: restore the craft and camera, hide the black hole.
func _apply_reset() -> void:
	var veh: Node3D = _vehicle()
	if veh != null:
		veh.position = _rest_pos
		veh.scale = _base_scale
	var cam: Camera3D = _camera()
	if cam != null:
		cam.fov = _old_fov
	_show_black_hole(false)
	_set_growth(0.0)
	_label.text = tr("Life %d") % (GameState.life + 1)


func _on_natural_end() -> void:
	GameState.settings[SEEN_KEY] = true
	_end_play()


func _end_play() -> void:
	_playing = false
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finished.emit()
	_fade_out()


func _fade_out() -> void:
	var fade: Tween = create_tween()
	fade.set_parallel(true)
	fade.tween_property(_rect, "modulate:a", 0.0, FADE_OUT_TIME)
	fade.tween_property(_label, "modulate:a", 0.0, FADE_OUT_TIME)


func _on_gui_input(event: InputEvent) -> void:
	if not _playing:
		return
	if not bool(GameState.settings.get(SEEN_KEY, false)):
		return
	var pressed: bool = false
	if event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if pressed:
		_skip()


# Jump to the 4.5 s state at once.
func _skip() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_apply_reset()
	_rect.modulate.a = 1.0
	_label.modulate.a = 1.0
	_end_play()


func _show_black_hole(on: bool) -> void:
	if _black_hole != null and _black_hole.has_method("show_for_cinematic"):
		_black_hole.call("show_for_cinematic", on)


func _set_growth(t: float) -> void:
	if _black_hole != null and _black_hole.has_method("set_growth"):
		_black_hole.call("set_growth", t)


func _vehicle() -> Node3D:
	if _world == null:
		return null
	return _world.vehicle()


func _camera() -> Camera3D:
	if _world == null:
		return null
	return _world.camera()
