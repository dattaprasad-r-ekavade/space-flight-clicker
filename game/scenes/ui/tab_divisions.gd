extends Control
## Divisions tab: buy-mode toggle at the top, one DivisionRow per division below.

## Row refreshes triggered by revenue are at most this many seconds apart (5 per second).
const REFRESH_INTERVAL: float = 0.2
const MODES: Array[int] = [1, 10, -1]

var _mode: int = 1
var _rows: Array[DivisionRow] = []
var _list: VBoxContainer = null
var _dirty: bool = false
var _timer: Timer = null


func _ready() -> void:
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", UiTheme.PAD)
	add_child(root)
	root.add_child(_build_toolbar())

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", UiTheme.PAD)
	scroll.add_child(_list)

	_timer = Timer.new()
	_timer.wait_time = REFRESH_INTERVAL
	_timer.timeout.connect(_on_timer)
	add_child(_timer)
	_timer.start()

	EventBus.revenue_changed.connect(_on_revenue_changed)
	EventBus.division_changed.connect(_on_division_changed)
	EventBus.stage_unlocked.connect(_on_stage_unlocked)
	EventBus.state_loaded.connect(_rebuild_rows)
	_rebuild_rows()


func _build_toolbar() -> HBoxContainer:
	var toolbar: HBoxContainer = HBoxContainer.new()
	var group: ButtonGroup = ButtonGroup.new()
	for mode: int in MODES:
		var button: Button = Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.text = tr("Max") if mode == -1 else "x%d" % mode
		button.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.button_pressed = mode == _mode
		button.pressed.connect(_on_mode_pressed.bind(mode))
		toolbar.add_child(button)
	return toolbar


## Builds one row per division in GameState.division_order.
func _rebuild_rows() -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	_rows.clear()
	for id: String in GameState.division_order:
		var row: DivisionRow = DivisionRow.new()
		row.tapped.connect(_on_row_tapped)
		_list.add_child(row)
		row.set_buy_mode(_mode)
		row.setup(id)
		_rows.append(row)
	_refresh_rows()


## Shows each unlocked row, and only the first locked row. Refreshes the shown rows.
func _refresh_rows() -> void:
	var locked_shown: bool = false
	for row: DivisionRow in _rows:
		var unlocked: bool = GameState.is_unlocked(row.division_id)
		if not unlocked and locked_shown:
			row.visible = false
			continue
		if not unlocked:
			locked_shown = true
		row.visible = true
		row.refresh()


func _on_mode_pressed(mode: int) -> void:
	_mode = mode
	for row: DivisionRow in _rows:
		row.set_buy_mode(_mode)
	_refresh_rows()


func _on_row_tapped(_id: String) -> void:
	_refresh_rows()


func _on_revenue_changed(_value: float) -> void:
	_dirty = true


func _on_timer() -> void:
	if _dirty:
		_dirty = false
		_refresh_rows()


func _on_division_changed(_id: String) -> void:
	_refresh_rows()


func _on_stage_unlocked(_id: String) -> void:
	_refresh_rows()
