class_name PopupContracts
extends PanelContainer
## Daily contract progress popup.

var _contract_list: VBoxContainer
var _refresh_timer: Timer


func _ready() -> void:
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTheme.PAD)
	add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTheme.PAD)
	margin.add_child(box)
	box.add_child(_make_label(tr("Daily contracts"), UiTheme.FONT_TITLE, UiTheme.TEXT))
	_contract_list = VBoxContainer.new()
	_contract_list.add_theme_constant_override("separation", UiTheme.PAD / 2)
	box.add_child(_contract_list)
	var close_button: BigButton = BigButton.new()
	close_button.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
	close_button.set_title(tr("Close"))
	close_button.pressed.connect(_on_close_pressed)
	box.add_child(close_button)

	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 1.0
	_refresh_timer.autostart = true
	_refresh_timer.timeout.connect(_refresh_contracts)
	add_child(_refresh_timer)
	_refresh_contracts()


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _refresh_contracts() -> void:
	for child: Node in _contract_list.get_children():
		_contract_list.remove_child(child)
		child.queue_free()
	var contracts: Array[Dictionary] = GameState.contracts_status(TimeService.now_unix(), _utc_offset())
	for contract: Dictionary in contracts:
		var title: String = tr(str(contract["title"]))
		var progress_text: String = tr("%s: %d / %d") % [title, int(contract["progress"]), int(contract["target"])]
		if bool(contract["complete"]):
			progress_text = tr("%s: Complete · reward paid") % title
		_contract_list.add_child(_make_label(progress_text, UiTheme.FONT_BODY, UiTheme.TEXT))


func _utc_offset() -> int:
	var zone: Dictionary = Time.get_time_zone_from_system()
	return int(zone.get("bias", 0))


func _on_close_pressed() -> void:
	PopupHost.instance.close_current()
