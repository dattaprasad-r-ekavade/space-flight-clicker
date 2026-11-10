class_name PopupDaily
extends PanelContainer
## Daily reward claim popup.

var _status_label: Label
var _claim_button: BigButton


func _ready() -> void:
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTheme.PAD)
	add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTheme.PAD)
	margin.add_child(box)
	box.add_child(_make_label(tr("Daily reward"), UiTheme.FONT_TITLE, UiTheme.TEXT))
	_status_label = _make_label("", UiTheme.FONT_BODY, UiTheme.TEXT_DIM)
	box.add_child(_status_label)
	_claim_button = _add_button(box, tr("Claim reward"), _on_claim_pressed)
	_add_button(box, tr("Close"), _on_close_pressed)
	_refresh_status()


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _add_button(box: VBoxContainer, title: String, handler: Callable) -> BigButton:
	var button: BigButton = BigButton.new()
	button.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
	box.add_child(button)
	button.set_title(title)
	button.pressed.connect(handler)
	return button


func _on_claim_pressed() -> void:
	GameState.claim_daily_reward(TimeService.now_unix(), _utc_offset())
	_refresh_status()


func _refresh_status() -> void:
	var result: Dictionary = GameState.daily_status(TimeService.now_unix(), _utc_offset())
	var day: int = int(result["streak"])
	var reward: String = tr("Day %d reward: %d minutes of current income") % [day, int(result["reward_minutes"])]
	if int(result["echoes"]) > 0:
		reward += tr(" + 3 Echoes")
	_status_label.text = reward
	_claim_button.disabled = not bool(result["can_claim"])
	_claim_button.set_title(tr("Claim reward") if bool(result["can_claim"]) else tr("Come back tomorrow"))


func _utc_offset() -> int:
	var zone: Dictionary = Time.get_time_zone_from_system()
	return int(zone.get("bias", 0))


func _on_close_pressed() -> void:
	PopupHost.instance.close_current()
