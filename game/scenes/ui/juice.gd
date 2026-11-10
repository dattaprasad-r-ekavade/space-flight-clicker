extends Control

## Juice overlay: floating revenue text, unit-change pop, button press feel,
## camera shake on launch (stage 3+), and haptics. Driven by EventBus signals only.

const MAX_REVENUE_LABELS: int = 6
const REVENUE_RISE_PX: float = 120.0
const REVENUE_TIME: float = 0.9
const REVENUE_X_MIN: float = 0.35
const REVENUE_X_MAX: float = 0.65
const REVENUE_Y_RATIO: float = 0.3
const UNIT_POP_TIME: float = 1.2
const UNIT_POP_FONT: int = 96
const PRESS_SCALE: float = 0.94
const PRESS_TIME: float = 0.1
const SHAKE_MIN_STAGE_INDEX: int = 2
const SHAKE_MAX: float = 0.08
const SHAKE_TIME: float = 0.25
const HAPTIC_MS: int = 20

var _live_revenue_labels: int = 0
var _last_unit: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.launch_finished.connect(_on_launch_finished)
	EventBus.launch_started.connect(_on_launch_started)
	EventBus.record_height_changed.connect(_on_record_height_changed)
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_connect_buttons", get_tree().root)


# ---- 1. Floating revenue text ----

func _on_launch_finished(id: String, revenue: float, _apogee: float) -> void:
	if id != GameState.selected_division:
		return
	if _live_revenue_labels >= MAX_REVENUE_LABELS:
		return
	var lbl: Label = _make_label(tr("+%s") % NumFormat.money(revenue), 48, UiTheme.GOOD)
	lbl.position = Vector2(
		size.x * randf_range(REVENUE_X_MIN, REVENUE_X_MAX),
		size.y * REVENUE_Y_RATIO)
	add_child(lbl)
	_live_revenue_labels += 1
	var tw: Tween = lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - REVENUE_RISE_PX, REVENUE_TIME)
	tw.tween_property(lbl, "modulate:a", 0.0, REVENUE_TIME)
	tw.finished.connect(_drop_revenue_label.bind(lbl))


func _drop_revenue_label(lbl: Label) -> void:
	_live_revenue_labels -= 1
	lbl.queue_free()


# ---- 2. Unit-change pop ----

func _on_record_height_changed(value: float) -> void:
	var text: String = NumFormat.height(value)
	var parts: PackedStringArray = text.split(" ")
	var unit: String = parts[parts.size() - 1]
	var changed: bool = _last_unit != "" and unit != _last_unit
	_last_unit = unit
	if changed:
		_show_unit_pop(text)


func _show_unit_pop(text: String) -> void:
	var lbl: Label = _make_label(text, UNIT_POP_FONT, UiTheme.TEXT)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.pivot_offset = size * 0.5
	lbl.scale = Vector2(0.5, 0.5)
	add_child(lbl)
	var scale_tw: Tween = lbl.create_tween()
	scale_tw.tween_property(lbl, "scale", Vector2(1.2, 1.2), UNIT_POP_TIME * 0.25)
	scale_tw.tween_property(lbl, "scale", Vector2.ONE, UNIT_POP_TIME * 0.125)
	var fade_tw: Tween = lbl.create_tween()
	fade_tw.tween_property(lbl, "modulate:a", 0.0, UNIT_POP_TIME)
	fade_tw.finished.connect(lbl.queue_free)


# ---- 3. Button press feel ----

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_hook_button(node as BaseButton)


func _connect_buttons(node: Node) -> void:
	if node is BaseButton:
		_hook_button(node as BaseButton)
	for child: Node in node.get_children():
		_connect_buttons(child)


func _hook_button(btn: BaseButton) -> void:
	if not btn.button_down.is_connected(_on_button_down.bind(btn)):
		btn.button_down.connect(_on_button_down.bind(btn))


func _on_button_down(btn: BaseButton) -> void:
	if not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.size * 0.5
	var tw: Tween = btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(PRESS_SCALE, PRESS_SCALE), PRESS_TIME * 0.5)
	tw.tween_property(btn, "scale", Vector2.ONE, PRESS_TIME * 0.5)


# ---- 4 and 5. Launch shake and haptics ----

func _on_launch_started(id: String) -> void:
	if id != GameState.selected_division:
		return
	if GameState.division_order.find(id) >= SHAKE_MIN_STAGE_INDEX:
		_shake_camera()
	var haptics_on: bool = GameState.settings.get("haptics", true)
	if haptics_on:
		Input.vibrate_handheld(HAPTIC_MS)


func _shake_camera() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var h_tw: Tween = cam.create_tween()
	h_tw.tween_property(cam, "h_offset", randf_range(-SHAKE_MAX, SHAKE_MAX), SHAKE_TIME / 3.0)
	h_tw.tween_property(cam, "h_offset", randf_range(-SHAKE_MAX, SHAKE_MAX), SHAKE_TIME / 3.0)
	h_tw.tween_property(cam, "h_offset", 0.0, SHAKE_TIME / 3.0)
	var v_tw: Tween = cam.create_tween()
	v_tw.tween_property(cam, "v_offset", randf_range(-SHAKE_MAX, SHAKE_MAX), SHAKE_TIME / 3.0)
	v_tw.tween_property(cam, "v_offset", randf_range(-SHAKE_MAX, SHAKE_MAX), SHAKE_TIME / 3.0)
	v_tw.tween_property(cam, "v_offset", 0.0, SHAKE_TIME / 3.0)


# ---- Helpers ----

func _make_label(text: String, font_size: int, colour: Color) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", colour)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 8)
	return lbl
