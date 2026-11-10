class_name PopupHost
extends Control
## Shows one popup at a time over a dimmed background. Also shows toasts.

signal popup_closed

static var instance: PopupHost = null

const DIM_ALPHA: float = 0.6
const POPUP_WIDTH_RATIO: float = 0.85
const TOAST_HOLD_SECONDS: float = 2.0
const TOAST_FADE_SECONDS: float = 0.5

var _dim: ColorRect = null
var _center: CenterContainer = null
var _toast: Label = null
var _toast_tween: Tween = null
var _current: Control = null
var _queue: Array[Control] = []
var _offline_key: String = ""


func _ready() -> void:
	instance = self
	mouse_filter = MOUSE_FILTER_IGNORE
	_build()
	visible = false
	EventBus.state_loaded.connect(_check_offline)
	EventBus.toast_requested.connect(toast)
	call_deferred("_check_offline")


func _exit_tree() -> void:
	if instance == self:
		instance = null


## Show the popup now if none is open. Otherwise queue it.
func show_popup(popup: Control) -> void:
	if _current == null:
		_show(popup)
	else:
		_queue.append(popup)


## Free the current popup. Show the next queued popup, or hide the host.
func close_current() -> void:
	if _current == null:
		return
	_center.remove_child(_current)
	_current.queue_free()
	_current = null
	popup_closed.emit()
	if _queue.is_empty():
		_refresh_visibility()
	else:
		_show(_queue.pop_front())


## Show a short message at the top. It fades out and does not block input.
func toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast.visible = true
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_HOLD_SECONDS)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, TOAST_FADE_SECONDS)
	_toast_tween.tween_callback(_on_toast_done)
	_refresh_visibility()


func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.0, DIM_ALPHA)
	_dim.mouse_filter = MOUSE_FILTER_STOP
	_dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_dim)

	_center = CenterContainer.new()
	_center.mouse_filter = MOUSE_FILTER_IGNORE
	_center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_center)

	_toast = Label.new()
	_toast.mouse_filter = MOUSE_FILTER_IGNORE
	_toast.visible = false
	_toast.add_theme_font_size_override("font_size", UiTheme.FONT_SMALL)
	_toast.add_theme_color_override("font_color", UiTheme.TEXT)
	_toast.set_anchors_and_offsets_preset(PRESET_CENTER_TOP, PRESET_MODE_MINSIZE, UiTheme.PAD * 2)
	_toast.grow_horizontal = GROW_DIRECTION_BOTH
	add_child(_toast)

	_dim.visible = false
	_center.visible = false


func _show(popup: Control) -> void:
	_current = popup
	popup.custom_minimum_size.x = get_viewport_rect().size.x * POPUP_WIDTH_RATIO
	_center.add_child(popup)
	_refresh_visibility()


func _refresh_visibility() -> void:
	var has_popup: bool = _current != null
	_dim.visible = has_popup
	_center.visible = has_popup
	visible = has_popup or _toast.visible


func _on_toast_done() -> void:
	_toast.visible = false
	_refresh_visibility()


## Show the offline popup once for each new pending value.
func _check_offline() -> void:
	var pending: Dictionary = GameState.pending_offline
	var revenue: float = float(pending.get("revenue", 0.0))
	if revenue <= 0.0:
		return
	var seconds: float = float(pending.get("seconds_counted", 0.0))
	var key: String = "%s|%s" % [seconds, revenue]
	if key == _offline_key:
		return
	_offline_key = key
	var popup: PopupOffline = PopupOffline.new()
	popup.setup(seconds, revenue)
	show_popup(popup)
