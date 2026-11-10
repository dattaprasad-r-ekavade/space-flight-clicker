extends Control
## Research tab: a grouped, scrolling list of research nodes.
## Reads state from GameState and buys through GameState.buy_research().

const REFRESH_SECONDS: float = 0.2

var _scroll: ScrollContainer = null
var _list: VBoxContainer = null
var _empty_label: Label = null
var _timer: Timer = null
var _dirty: bool = false
var _offers: Array[Dictionary] = []
var _stage_names: Dictionary = {}


func _ready() -> void:
	for division: Dictionary in DataLoader.divisions():
		_stage_names[str(division["id"])] = str(division["stage_name"])
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	_empty_label = Label.new()
	_empty_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_empty_label.text = tr("Research unlocks soon")
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_empty_label.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
	_empty_label.add_theme_font_size_override("font_size", UiTheme.FONT_BODY)
	_empty_label.visible = false
	add_child(_empty_label)
	_timer = Timer.new()
	_timer.wait_time = REFRESH_SECONDS
	_timer.autostart = true
	_timer.timeout.connect(_on_refresh_tick)
	add_child(_timer)
	EventBus.stage_unlocked.connect(_on_stage_unlocked)
	EventBus.state_loaded.connect(_on_state_loaded)
	EventBus.prestige_done.connect(_on_prestige_done)
	EventBus.revenue_changed.connect(_on_revenue_changed)
	_rebuild()


## Rebuilds the whole list. Owned nodes go to the bottom under "Completed".
func _rebuild() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_offers.clear()
	var owned: Array[Dictionary] = []
	var open: Array[Dictionary] = []
	for node: Dictionary in Research.nodes():
		if GameState.owned_research.has(str(node["id"])):
			owned.append(node)
		elif GameState.is_unlocked(str(node["requires_stage"])):
			open.append(node)
	open.sort_custom(_by_cost)
	for group: String in ["global", "division", "flight", "pump"]:
		var rows: Array[Dictionary] = []
		for node: Dictionary in open:
			if str(node["group"]) == group:
				rows.append(node)
		if rows.is_empty():
			continue
		_add_header(_group_title(group))
		for node: Dictionary in rows:
			_add_row(node)
	if not owned.is_empty():
		_add_header(tr("Completed"))
		for node: Dictionary in owned:
			_add_done_label(node)
	var none_visible: bool = open.is_empty() and owned.is_empty()
	_empty_label.visible = none_visible
	_scroll.visible = not none_visible


func _add_header(text: String) -> void:
	var label: Label = _dim_label(text)
	label.add_theme_font_size_override("font_size", UiTheme.FONT_BODY)
	_list.add_child(label)


func _add_row(node: Dictionary) -> void:
	var card: PanelCard = PanelCard.new()
	var box: VBoxContainer = card.content()
	var line: HBoxContainer = HBoxContainer.new()
	box.add_child(line)
	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(text_box)
	var name_label: Label = Label.new()
	name_label.text = tr(str(node["name"]))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(name_label)
	text_box.add_child(_dim_label(_effect_text(node)))
	var cost: float = float(node["cost"])
	var button: BigButton = BigButton.new()
	button.custom_minimum_size = Vector2(280, UiTheme.TOUCH)
	button.set_title(tr("Research"))
	button.set_subtitle(NumFormat.money(cost))
	button.set_affordable(cost <= GameState.revenue)
	button.pressed.connect(_on_buy_pressed.bind(str(node["id"])))
	line.add_child(button)
	_list.add_child(card)
	_offers.append({"button": button, "cost": cost})


func _add_done_label(node: Dictionary) -> void:
	var label: Label = _dim_label(tr(str(node["name"])))
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_list.add_child(label)


func _dim_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
	label.add_theme_font_size_override("font_size", UiTheme.FONT_SMALL)
	return label


func _effect_text(node: Dictionary) -> String:
	var value: float = float(node["value"])
	match str(node["group"]):
		"division":
			var division_id: String = str(node["division"])
			var stage: String = str(_stage_names.get(division_id, division_id))
			return tr("x%s revenue for %s") % [_num(value), tr(stage)]
		"global":
			return tr("x%s all revenue") % _num(value)
		"flight":
			return tr("-%d%% flight time") % roundi((1.0 - value) * 100.0)
		"pump":
			return tr("-%d%% pump taps") % roundi((1.0 - value) * 100.0)
	return ""


func _group_title(group: String) -> String:
	match group:
		"global":
			return tr("Company-wide")
		"division":
			return tr("Divisions")
		"flight":
			return tr("Faster flights")
		"pump":
			return tr("Easier pumping")
	return ""


static func _num(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(value))
	return str(value)


static func _by_cost(a: Dictionary, b: Dictionary) -> bool:
	return float(a["cost"]) < float(b["cost"])


func _on_buy_pressed(id: String) -> void:
	if GameState.buy_research(id):
		call_deferred("_rebuild")


## Affordability is refreshed at most REFRESH_SECONDS apart.
func _on_refresh_tick() -> void:
	if not _dirty:
		return
	_dirty = false
	for entry: Dictionary in _offers:
		var button: BigButton = entry["button"] as BigButton
		if is_instance_valid(button):
			button.set_affordable(float(entry["cost"]) <= GameState.revenue)


func _on_revenue_changed(_value: float) -> void:
	_dirty = true


func _on_stage_unlocked(_id: String) -> void:
	_rebuild()


func _on_state_loaded() -> void:
	_rebuild()


func _on_prestige_done(_echoes_gained: int) -> void:
	_rebuild()
