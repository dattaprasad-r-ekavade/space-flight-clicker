extends Control
## First-time guidance. Five hint bubbles, one per step. Each step ends when the player does the action.

const SETTING_KEY: String = "tutorial_step"
const DIVISION_ID: String = "bottles"
const STEP_COUNT: int = 5
const STEP_MANAGER: int = 3
const LEVEL_GOAL: int = 2
const CHECK_INTERVAL: float = 0.3
const PUMP_CLEARANCE: int = 320
const BUBBLE_WIDTH: int = 860
const PULSE_SCALE: float = 1.06
const PULSE_TIME: float = 0.6

var _step: int = 0
var _launched: bool = false
var _dirty: bool = false
var _bubble: PanelContainer
var _label: Label
var _timer: Timer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_step = _saved_step()
	if GameState.life > 1 or _step >= STEP_COUNT:
		queue_free()
		return
	if _step == 0 and _level() == 0:
		GameState.buy_levels(DIVISION_ID, 1)
	_build_bubble()
	_build_timer()
	EventBus.division_changed.connect(_on_division_changed)
	EventBus.revenue_changed.connect(_on_revenue_changed)
	EventBus.launch_started.connect(_on_launch_started)
	EventBus.state_loaded.connect(_on_state_loaded)
	_check()


func _build_bubble() -> void:
	_bubble = PanelContainer.new()
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bubble.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bubble.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bubble.offset_top = -PUMP_CLEARANCE
	_bubble.offset_bottom = -PUMP_CLEARANCE
	_bubble.add_theme_stylebox_override("panel", _bubble_style())
	_bubble.resized.connect(_on_bubble_resized)
	add_child(_bubble)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.custom_minimum_size = Vector2(BUBBLE_WIDTH, 0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", UiTheme.TEXT)
	_bubble.add_child(_label)
	var pulse: Tween = _bubble.create_tween().set_loops()
	pulse.tween_property(_bubble, "scale", Vector2.ONE * PULSE_SCALE, PULSE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(_bubble, "scale", Vector2.ONE, PULSE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _bubble_style() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = UiTheme.PANEL
	box.border_color = UiTheme.ACCENT
	box.set_border_width_all(4)
	box.set_corner_radius_all(UiTheme.RADIUS)
	box.set_content_margin_all(UiTheme.PAD)
	return box


func _on_bubble_resized() -> void:
	_bubble.pivot_offset = _bubble.size * 0.5


func _build_timer() -> void:
	_timer = Timer.new()
	_timer.wait_time = CHECK_INTERVAL
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start()


func _on_timer_timeout() -> void:
	if _dirty:
		_check()


func _on_division_changed(_id: String) -> void:
	_dirty = true


func _on_revenue_changed(_value: float) -> void:
	_dirty = true


func _on_launch_started(_id: String) -> void:
	_launched = true
	_dirty = true


func _on_state_loaded() -> void:
	_step = _saved_step()
	if _step >= STEP_COUNT:
		queue_free()
		return
	_dirty = true


# Ends every step whose action is done, then refreshes the bubble.
func _check() -> void:
	_dirty = false
	while _step < STEP_COUNT and _is_done(_step):
		_end_step()
	if _step >= STEP_COUNT:
		return
	_refresh()


func _end_step() -> void:
	Analytics.event("tutorial_step", {"step": _step})
	_step += 1
	GameState.settings[SETTING_KEY] = _step
	if _step >= STEP_COUNT:
		_timer.stop()
		queue_free()


func _refresh() -> void:
	_label.text = _step_text(_step)
	_bubble.visible = _step != STEP_MANAGER or _revenue_ok()


func _is_done(step: int) -> bool:
	match step:
		0:
			return _taps() > 0 or _flying()
		1:
			return _launched
		2:
			return _level() >= LEVEL_GOAL
		3:
			return _has_manager()
		4:
			return not GameState.owned_research.is_empty()
	return true


func _step_text(step: int) -> String:
	match step:
		0:
			return tr("Tap Pump to fill the bottle with air")
		1:
			return tr("Tap Launch!")
		2:
			return tr("Spend your earnings: buy a level in Divisions")
		3:
			return tr("Hire a manager in the Managers tab to launch for you")
		4:
			return tr("Open Research to boost your revenue")
	return ""


func _saved_step() -> int:
	return int(GameState.settings.get(SETTING_KEY, 0))


func _division() -> Dictionary:
	return GameState.divisions.get(DIVISION_ID, {}) as Dictionary


func _level() -> int:
	return int(_division().get("level", 0))


func _taps() -> int:
	return int(_division().get("fuel_taps", 0))


func _flying() -> bool:
	return bool(_division().get("flying", false))


func _has_manager() -> bool:
	return bool(_division().get("has_manager", false))


func _revenue_ok() -> bool:
	return GameState.revenue >= GameState.manager_cost(DIVISION_ID) * 0.5
