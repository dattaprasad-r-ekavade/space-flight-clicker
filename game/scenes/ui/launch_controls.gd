class_name LaunchControls
extends Control
## Pump and Launch controls for the selected division.
## Shows a fuel bar, which turns into a flight progress bar while the division flies.

## Pump taps per second while the Pump button is held.
const PUMP_HOLD_RATE: float = 6.0

var _stage_label: Label = null
var _fuel_bar: FillBar = null
var _pump_button: BigButton = null
var _launch_button: BigButton = null
var _pump_timer: Timer = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	EventBus.division_changed.connect(_on_division_changed)
	EventBus.launch_started.connect(_on_division_changed)
	EventBus.launch_finished.connect(_on_launch_finished)
	EventBus.state_loaded.connect(_on_state_loaded)
	_refresh()


## One pump tap for the selected division.
func do_pump() -> void:
	var id: String = GameState.selected_division
	if not _pump_allowed(id):
		return
	GameState.pump(id)
	_refresh()


## Launches the selected division when its fuel is full.
func do_launch() -> void:
	var id: String = GameState.selected_division
	if not GameState.divisions.has(id):
		return
	if bool(GameState.divisions[id]["has_manager"]):
		return
	if not GameState.can_launch(id):
		return
	GameState.launch(id)
	_refresh()


func _process(_delta: float) -> void:
	var id: String = GameState.selected_division
	if not GameState.divisions.has(id) or not bool(GameState.divisions[id]["flying"]):
		_refresh()
		return
	_update_flight_bar(id)


func _build() -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, UiTheme.PAD)
	box.add_theme_constant_override("separation", UiTheme.PAD)
	add_child(box)

	_stage_label = Label.new()
	_stage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_label.add_theme_font_size_override("font_size", UiTheme.FONT_SMALL)
	_stage_label.add_theme_color_override("font_color", UiTheme.TEXT)
	_stage_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_stage_label.add_theme_constant_override("outline_size", 8)
	box.add_child(_stage_label)

	_fuel_bar = FillBar.new()
	_fuel_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_fuel_bar)

	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UiTheme.PAD)
	box.add_child(row)

	_pump_button = BigButton.new()
	_pump_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pump_button.set_title(tr("Pump"))
	_pump_button.button_down.connect(_on_pump_down)
	_pump_button.button_up.connect(_on_pump_up)
	row.add_child(_pump_button)

	_launch_button = BigButton.new()
	_launch_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_launch_button.set_title(tr("Launch"))
	_launch_button.pressed.connect(do_launch)
	row.add_child(_launch_button)

	_pump_timer = Timer.new()
	_pump_timer.wait_time = 1.0 / PUMP_HOLD_RATE
	_pump_timer.timeout.connect(do_pump)
	add_child(_pump_timer)


func _refresh() -> void:
	var id: String = GameState.selected_division
	if not GameState.divisions.has(id):
		return
	var state: Dictionary = GameState.divisions[id]
	var level: int = int(state["level"])
	var managed: bool = bool(state["has_manager"])
	var flying: bool = bool(state["flying"])

	_stage_label.text = tr(str(GameState.division_data[id]["stage_name"]))
	_pump_button.set_title(tr("Speed up") if managed else tr("Pump"))
	var pump_ok: bool = _pump_allowed(id)
	_pump_button.set_affordable(pump_ok)
	if not pump_ok:
		_pump_timer.stop()

	_launch_button.visible = not managed
	_launch_button.set_affordable(level > 0 and GameState.can_launch(id))

	set_process(flying)
	if level == 0:
		_fuel_bar.set_fill_color(UiTheme.GOOD)
		_fuel_bar.set_progress(0.0)
		_fuel_bar.set_label(tr("Buy level 1 first"))
	elif flying:
		_update_flight_bar(id)
	else:
		_update_fuel_bar(id)


func _update_fuel_bar(id: String) -> void:
	var needed: int = maxi(GameState._pump_taps(id), 1)
	var done: int = int(GameState.divisions[id]["fuel_taps"])
	_fuel_bar.set_fill_color(UiTheme.GOOD)
	_fuel_bar.set_progress(float(done) / float(needed))
	_fuel_bar.set_label(tr("Ready!") if GameState.can_launch(id) else tr("Fuel"))


func _update_flight_bar(id: String) -> void:
	var total: float = GameState.flight_time(id)
	var elapsed: float = float(GameState.divisions[id]["cycle_elapsed"])
	_fuel_bar.set_fill_color(UiTheme.ACCENT_2)
	_fuel_bar.set_progress(elapsed / total if total > 0.0 else 0.0)
	_fuel_bar.set_label(tr("In flight"))


## A pump is allowed when the level is above 0 and the division is not flying,
## or when the division has a manager (a manager can speed up a flight).
func _pump_allowed(id: String) -> bool:
	if not GameState.divisions.has(id):
		return false
	var state: Dictionary = GameState.divisions[id]
	if int(state["level"]) <= 0:
		return false
	return bool(state["has_manager"]) or not bool(state["flying"])


func _on_pump_down() -> void:
	do_pump()
	if _pump_allowed(GameState.selected_division):
		_pump_timer.start()


func _on_pump_up() -> void:
	_pump_timer.stop()


func _on_division_changed(_id: String) -> void:
	_refresh()


func _on_launch_finished(_id: String, _revenue: float, _apogee: float) -> void:
	_refresh()


func _on_state_loaded() -> void:
	_refresh()
