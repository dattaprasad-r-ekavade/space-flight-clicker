class_name FillBar
extends Control
## A horizontal bar that fills from 0 to 1, with centred text on top.
## Progress changes with a short tween when the node is in the tree.

const TWEEN_TIME: float = 0.12

var _progress: float = 0.0
var _shown: float = 0.0
var _fill_color: Color = UiTheme.GOOD
var _text: String = ""
var _label: Label = null
var _tween: Tween = null


func _init() -> void:
	custom_minimum_size = Vector2(0, UiTheme.PAD * 2)


func _ready() -> void:
	_build()
	resized.connect(queue_redraw)


## Sets the fill amount. Values outside 0..1 are clamped.
func set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	if not is_inside_tree():
		_shown = _progress
		queue_redraw()
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_shown, _shown, _progress, TWEEN_TIME)


func get_progress() -> float:
	return _progress


func set_fill_color(color: Color) -> void:
	_fill_color = color
	queue_redraw()


func set_label(text: String) -> void:
	_text = text
	if _label != null:
		_label.text = _text


func get_label() -> String:
	return _text


func _set_shown(value: float) -> void:
	_shown = value
	queue_redraw()


func _build() -> void:
	if _label != null:
		return
	_shown = _progress
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", UiTheme.FONT_SMALL)
	_label.add_theme_color_override("font_color", UiTheme.TEXT)
	_label.text = _text
	add_child(_label)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiTheme.PANEL_LIGHT)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _shown, size.y)), _fill_color)
