class_name DivisionRow
extends PanelContainer
## One row on the Divisions tab: stage name, level, next milestone, and a buy button.
## A locked division shows only its name and the unlock condition.

## Emitted when the player taps the left side of an unlocked row.
signal tapped(id: String)

var division_id: String = ""
var _buy_mode: int = 1
var _built: bool = false
var _select_button: Button = null
var _name_label: Label = null
var _detail_label: Label = null
var _lock_label: Label = null
var _bar: FillBar = null
var _buy_button: BigButton = null


func _init() -> void:
	custom_minimum_size = Vector2(0.0, UiTheme.TOUCH * 1.5)


func _ready() -> void:
	_build()
	refresh()


## Sets the division this row shows and refreshes it.
func setup(id: String) -> void:
	division_id = id
	refresh()


## Sets the buy mode: 1, 10, or -1 for Max. Call refresh() after this.
func set_buy_mode(mode: int) -> void:
	_buy_mode = mode


## Redraws the row from GameState. Cheap: reads values and sets text.
func refresh() -> void:
	if not _built or division_id == "":
		return
	var div: Dictionary = GameState.division_data[division_id]
	var unlocked: bool = GameState.is_unlocked(division_id)
	_name_label.text = tr(String(div["stage_name"]))
	_name_label.add_theme_color_override("font_color", UiTheme.TEXT if unlocked else UiTheme.TEXT_DIM)
	_select_button.disabled = not unlocked
	_lock_label.visible = not unlocked
	_detail_label.visible = unlocked
	_bar.visible = unlocked
	_buy_button.visible = unlocked
	_apply_selected(unlocked and GameState.selected_division == division_id)
	if not unlocked:
		_lock_label.text = tr("Reach level 25 in the stage before")
		return
	var level: int = int(GameState.divisions[division_id]["level"])
	_detail_label.text = tr("Lv %d · %s per launch · %s") % [
		level,
		NumFormat.money(GameState.revenue_per_launch(division_id)),
		NumFormat.duration(GameState.flight_time(division_id)),
	]
	var progress: float = _milestone_progress(level)
	if progress != _bar.get_progress():
		_bar.set_progress(progress)
	var count: int = _buy_count(level, div)
	var cost: float = Economy.bulk_cost(div, level, count)
	_buy_button.set_title(tr("Buy x%d") % count)
	_buy_button.set_subtitle(NumFormat.money(cost))
	_buy_button.set_affordable(cost <= GameState.revenue)


func _buy_count(level: int, div: Dictionary) -> int:
	if _buy_mode == -1:
		return maxi(1, Economy.max_affordable(div, level, GameState.revenue))
	return _buy_mode


## Fraction of the way from the previous level milestone to the next one.
func _milestone_progress(level: int) -> float:
	var previous: int = 0
	for milestone: int in Economy.LEVEL_MULT_THRESHOLDS:
		if level < milestone:
			return float(level - previous) / float(milestone - previous)
		previous = milestone
	return 1.0


func _apply_selected(on: bool) -> void:
	if not on:
		remove_theme_stylebox_override("panel")
		return
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = UiTheme.PANEL
	box.set_corner_radius_all(UiTheme.RADIUS)
	box.set_border_width_all(6)
	box.border_color = UiTheme.ACCENT
	add_theme_stylebox_override("panel", box)


func _on_select_pressed() -> void:
	if GameState.select_division(division_id):
		tapped.emit(division_id)


func _on_buy_pressed() -> void:
	var div: Dictionary = GameState.division_data[division_id]
	var level: int = int(GameState.divisions[division_id]["level"])
	GameState.buy_levels(division_id, _buy_count(level, div))
	refresh()


func _build() -> void:
	if _built:
		return
	_built = true
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	_select_button = Button.new()
	_select_button.flat = true
	_select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_select_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_select_button.pressed.connect(_on_select_pressed)
	row.add_child(_select_button)

	var left: VBoxContainer = VBoxContainer.new()
	left.set_anchors_preset(Control.PRESET_FULL_RECT)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_select_button.add_child(left)
	_name_label = _make_label(UiTheme.FONT_BODY, UiTheme.TEXT)
	_detail_label = _make_label(UiTheme.FONT_SMALL, UiTheme.TEXT_DIM)
	_lock_label = _make_label(UiTheme.FONT_SMALL, UiTheme.TEXT_DIM)
	_bar = FillBar.new()
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(_name_label)
	left.add_child(_detail_label)
	left.add_child(_lock_label)
	left.add_child(_bar)

	_buy_button = BigButton.new()
	_buy_button.custom_minimum_size = Vector2(UiTheme.TOUCH * 3, UiTheme.TOUCH)
	_buy_button.pressed.connect(_on_buy_pressed)
	row.add_child(_buy_button)


func _make_label(font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
