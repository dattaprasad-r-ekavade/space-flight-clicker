extends Control
## Managers tab. One row per division with level 1 or more.
## Hire buys a manager through GameState. This script never changes state.

const REFRESH_SECONDS: float = 0.2
const RIGHT_WIDTH: int = 280

var _content: Control = null
var _timer: Timer = null
var _dirty: bool = false
## Division id -> BigButton, for rows that still need a Hire button.
var _hire_buttons: Dictionary = {}


func _ready() -> void:
	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_content)
	_timer = Timer.new()
	_timer.wait_time = REFRESH_SECONDS
	_timer.timeout.connect(_on_refresh_timer)
	add_child(_timer)
	_timer.start()
	EventBus.revenue_changed.connect(_on_revenue_changed)
	EventBus.division_changed.connect(_on_division_changed)
	EventBus.stage_unlocked.connect(_on_stage_unlocked)
	EventBus.state_loaded.connect(_on_state_loaded)
	EventBus.prestige_done.connect(_on_prestige_done)
	_rebuild()


func _on_division_changed(_id: String) -> void:
	_rebuild()


func _on_stage_unlocked(_id: String) -> void:
	_rebuild()


func _on_state_loaded() -> void:
	_rebuild()


func _on_prestige_done(_echoes_gained: int) -> void:
	_rebuild()


func _on_revenue_changed(_value: float) -> void:
	_dirty = true


func _on_refresh_timer() -> void:
	if not _dirty:
		return
	_dirty = false
	_update_affordability()


func _update_affordability() -> void:
	for id: String in _hire_buttons.keys():
		var button: BigButton = _hire_buttons[id]
		button.set_affordable(GameState.manager_cost(id) <= GameState.revenue)


func _rebuild() -> void:
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_hire_buttons.clear()
	var has_rows: bool = false
	for id: String in GameState.division_order:
		if int(GameState.divisions[id]["level"]) >= 1:
			has_rows = true
	if not has_rows:
		_add_empty_label()
		return
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UiTheme.PAD)
	scroll.add_child(list)
	for index: int in range(GameState.division_order.size()):
		var id: String = GameState.division_order[index]
		if int(GameState.divisions[id]["level"]) >= 1:
			list.add_child(_make_row(index, id))


func _add_empty_label() -> void:
	var label: Label = Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.text = tr("Buy your first level to hire managers")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
	_content.add_child(label)


func _make_row(index: int, id: String) -> PanelCard:
	var card: PanelCard = PanelCard.new()
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTheme.PAD)
	card.content().add_child(row)

	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(_make_label(_manager_title(index), UiTheme.TEXT))
	var stage_name: String = str(GameState.division_data[id]["stage_name"])
	left.add_child(_make_label(tr("Pumps and launches %s for you") % tr(stage_name), UiTheme.TEXT_DIM))

	if bool(GameState.divisions[id]["has_manager"]):
		var hired: Label = Label.new()
		hired.text = tr("Hired")
		hired.custom_minimum_size = Vector2(RIGHT_WIDTH, UiTheme.TOUCH)
		hired.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hired.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hired.add_theme_color_override("font_color", UiTheme.GOOD)
		row.add_child(hired)
	else:
		var button: BigButton = BigButton.new()
		button.custom_minimum_size = Vector2(RIGHT_WIDTH, UiTheme.TOUCH)
		var cost: float = GameState.manager_cost(id)
		button.set_title(tr("Hire"))
		button.set_subtitle(NumFormat.money(cost))
		button.set_affordable(cost <= GameState.revenue)
		button.pressed.connect(_on_hire_pressed.bind(id))
		row.add_child(button)
		_hire_buttons[id] = button
	return card


func _on_hire_pressed(id: String) -> void:
	if GameState.buy_manager(id):
		_rebuild()


func _make_label(text: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	return label


func _manager_title(index: int) -> String:
	match index:
		0:
			return tr("Pump Pal")
		1:
			return tr("Rocket Club Captain")
		2:
			return tr("Range Officer")
		3:
			return tr("Flight Director")
		4:
			return tr("Station Chief")
		5:
			return tr("Lunar Foreman")
		6:
			return tr("Fleet Dispatcher")
		7:
			return tr("Gate Keeper")
		8:
			return tr("Horizon Pilot")
	return ""
