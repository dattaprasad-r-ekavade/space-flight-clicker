extends Control
## Top HUD overlay: company, life, revenue, income per second, record height, boost button.
## Updates from EventBus signals and a 0.5 s timer. Does not update in _process.

const INCOME_REFRESH_SECONDS: float = 0.5
const OUTLINE_SIZE: int = 8

var _company_label: Label
var _life_label: Label
var _revenue_label: Label
var _income_label: Label
var _record_label: Label
var _boost_button: Button
var _timer: Timer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_timer = Timer.new()
	_timer.wait_time = INCOME_REFRESH_SECONDS
	_timer.autostart = true
	_timer.timeout.connect(_refresh_income)
	add_child(_timer)
	EventBus.revenue_changed.connect(_on_revenue_changed)
	EventBus.record_height_changed.connect(_on_record_changed)
	EventBus.division_changed.connect(_on_division_changed)
	EventBus.state_loaded.connect(_refresh_all)
	EventBus.prestige_done.connect(_on_prestige_done)
	_boost_button.pressed.connect(_on_boost_pressed)
	_refresh_all()


## Formats an income value. `fmt` is a translated format with one %s, for example tr("+%s / s").
static func income_text(v: float, fmt: String) -> String:
	return fmt % NumFormat.money(v)


func _build() -> void:
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "Column"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.anchor_left = 0.0
	column.anchor_right = 1.0
	column.anchor_top = 0.0
	column.anchor_bottom = 0.0
	column.offset_left = UiTheme.PAD
	column.offset_right = -UiTheme.PAD
	column.offset_top = UiTheme.PAD
	column.offset_bottom = UiTheme.PAD
	add_child(column)

	var row_top: HBoxContainer = _row(column)
	_company_label = _make_label(UiTheme.FONT_SMALL, UiTheme.TEXT_DIM)
	_company_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_top.add_child(_company_label)
	_life_label = _make_label(UiTheme.FONT_SMALL, UiTheme.TEXT_DIM)
	row_top.add_child(_life_label)
	_boost_button = Button.new()
	_boost_button.name = "BoostButton"
	_boost_button.text = tr("Boost")
	_boost_button.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
	row_top.add_child(_boost_button)

	_revenue_label = _make_label(UiTheme.FONT_NUMBER, UiTheme.TEXT)
	column.add_child(_revenue_label)

	_income_label = _make_label(UiTheme.FONT_SMALL, UiTheme.GOOD)
	column.add_child(_income_label)

	var record_caption: Label = _make_label(UiTheme.FONT_SMALL, UiTheme.TEXT_DIM)
	record_caption.text = tr("Record height")
	column.add_child(record_caption)
	_record_label = _make_label(UiTheme.FONT_NUMBER, UiTheme.TEXT)
	column.add_child(_record_label)


func _row(parent: Control) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	return row


func _make_label(font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	return label


func _refresh_all() -> void:
	_company_label.text = GameState.company_name
	_life_label.text = tr("Life %d") % GameState.life
	_refresh_revenue(GameState.revenue)
	_refresh_income()
	_refresh_boost()
	_refresh_record(GameState.record_height)


func _refresh_revenue(value: float) -> void:
	_revenue_label.text = NumFormat.money(value)


func _refresh_income() -> void:
	_income_label.text = income_text(GameState.income_per_second(), tr("+%s / s"))
	_refresh_boost()


func _refresh_boost() -> void:
	var seconds_left: float = GameState.boost_2x_remaining
	if seconds_left > 0.0:
		_boost_button.text = tr("2× Boost: %s") % NumFormat.duration(seconds_left)
	else:
		_boost_button.text = tr("Boost")


func _on_boost_pressed() -> void:
	PopupHost.instance.show_popup(PopupBoosts.new())


func _refresh_record(value: float) -> void:
	_record_label.text = NumFormat.height(value)


func _on_revenue_changed(value: float) -> void:
	_refresh_revenue(value)


func _on_record_changed(value: float) -> void:
	_refresh_record(value)


func _on_division_changed(_id: String) -> void:
	_refresh_income()


func _on_prestige_done(_echoes_gained: int) -> void:
	_refresh_all()
