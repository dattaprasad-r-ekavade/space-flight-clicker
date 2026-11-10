extends Control
## Echoes tab: owned Echoes, their bonus, the black hole entry, and the Echo Shop.
## Reads state from GameState and buys through GameState.buy_echo_item().

const PRESTIGE_DIVISION_ID: String = "black_hole"
## Same level as PrestigeOps.can_prestige().
const PRESTIGE_LEVEL: int = 25

var _scroll: ScrollContainer = null
var _list: VBoxContainer = null
var _echo_label: Label = null
var _bonus_label: Label = null
var _enter_button: BigButton = null
var _locked_label: Label = null
var _progress: FillBar = null
var _shop_rows: Array[Dictionary] = []


func _ready() -> void:
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	EventBus.state_loaded.connect(_rebuild)
	EventBus.prestige_done.connect(_on_prestige_done)
	EventBus.division_changed.connect(_on_division_changed)
	_rebuild()


## Rebuilds the whole tab. Shop rows and the header are then set by _update_status().
func _rebuild() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_shop_rows.clear()
	if GameState.life == 1 and GameState.echoes == 0:
		_list.add_child(_make_explain_card())
	_list.add_child(_make_header_card())
	_list.add_child(_make_prestige_card())
	_list.add_child(_dim_label(tr("Echo Shop")))
	for item: Dictionary in EchoShop.items():
		_list.add_child(_make_shop_row(item))
	_update_status()


func _make_explain_card() -> PanelCard:
	var card: PanelCard = PanelCard.new()
	var box: VBoxContainer = card.content()
	box.add_child(_label(tr("Echoes are memories of your past lives. Each one makes every launch earn more."), UiTheme.FONT_BODY, UiTheme.TEXT))
	return card


func _make_header_card() -> PanelCard:
	var card: PanelCard = PanelCard.new()
	var box: VBoxContainer = card.content()
	_echo_label = _label("", UiTheme.FONT_TITLE, UiTheme.TEXT)
	_bonus_label = _dim_label("")
	box.add_child(_echo_label)
	box.add_child(_bonus_label)
	return card


func _make_prestige_card() -> PanelCard:
	var card: PanelCard = PanelCard.new()
	var box: VBoxContainer = card.content()
	_enter_button = BigButton.new()
	_enter_button.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
	_enter_button.set_title(tr("Enter the Black Hole"))
	_enter_button.pressed.connect(_on_enter_pressed)
	box.add_child(_enter_button)
	_locked_label = _dim_label(tr("Reach level 25 in the last stage to enter the black hole"))
	box.add_child(_locked_label)
	_progress = FillBar.new()
	box.add_child(_progress)
	return card


func _make_shop_row(item: Dictionary) -> PanelCard:
	var card: PanelCard = PanelCard.new()
	var box: VBoxContainer = card.content()
	box.add_child(_label(tr(str(item["name_key"])), UiTheme.FONT_BODY, UiTheme.TEXT))
	var level_label: Label = _dim_label("")
	box.add_child(level_label)
	var button: BigButton = BigButton.new()
	button.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
	button.pressed.connect(_on_buy_pressed.bind(str(item["id"])))
	box.add_child(button)
	var max_label: Label = _dim_label(tr("Max"))
	box.add_child(max_label)
	_shop_rows.append({"item": item, "level_label": level_label, "button": button, "max_label": max_label})
	return card


## Sets all live text, button states, and visibility from GameState. Cheap enough to run often.
func _update_status() -> void:
	_echo_label.text = tr("Echoes: %d") % GameState.echoes
	var bonus_pct: int = roundi(float(GameState.echoes) * GameState.echo_power() * 100.0)
	_bonus_label.text = tr("+%d%% all revenue") % bonus_pct
	var can: bool = GameState.can_prestige()
	_enter_button.visible = can
	_locked_label.visible = not can
	_progress.visible = not can
	var level: int = _black_hole_level()
	_progress.set_progress(float(level) / float(PRESTIGE_LEVEL))
	_progress.set_label(tr("Level %d / %d") % [level, PRESTIGE_LEVEL])
	_update_shop_rows()


func _update_shop_rows() -> void:
	for row: Dictionary in _shop_rows:
		var item: Dictionary = row["item"]
		var id: String = str(item["id"])
		var level: int = int(GameState.echo_levels.get(id, 0))
		var max_level: int = int(item.get("max_level", 0))
		var level_label: Label = row["level_label"]
		var button: BigButton = row["button"]
		var max_label: Label = row["max_label"]
		level_label.text = tr("Level %d / %d") % [level, max_level]
		var at_max: bool = level >= max_level
		button.visible = not at_max
		max_label.visible = at_max
		var cost: float = EchoShop.cost(item, level)
		button.set_title(tr("Buy"))
		button.set_subtitle(tr("%d Echoes") % int(cost))
		button.set_affordable(float(GameState.echoes) >= cost)


func _black_hole_level() -> int:
	var division: Dictionary = GameState.divisions.get(PRESTIGE_DIVISION_ID, {})
	return int(division.get("level", 0))


func _label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _dim_label(text: String) -> Label:
	return _label(text, UiTheme.FONT_SMALL, UiTheme.TEXT_DIM)


func _on_enter_pressed() -> void:
	if PopupHost.instance != null:
		PopupHost.instance.show_popup(PopupPrestige.new())


func _on_buy_pressed(item_id: String) -> void:
	if GameState.buy_echo_item(item_id):
		call_deferred("_rebuild")


func _on_division_changed(_id: String) -> void:
	_update_status()


func _on_prestige_done(_echoes_gained: int) -> void:
	_rebuild()
