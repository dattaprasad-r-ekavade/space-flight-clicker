class_name PopupBoosts
extends PanelContainer
## Popup for optional rewarded revenue boosts.

var _boost_status: Label
var _warp_button: BigButton
var _warp_status: Label
var _refresh_timer: Timer


func _ready() -> void:
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTheme.PAD)
	add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTheme.PAD)
	margin.add_child(box)
	box.add_child(_make_label(tr("Boosts"), UiTheme.FONT_TITLE, UiTheme.TEXT))
	_boost_status = _make_label("", UiTheme.FONT_BODY, UiTheme.TEXT_DIM)
	box.add_child(_boost_status)
	_add_button(box, tr("Watch ad for 2× revenue"), _on_boost_pressed)
	_warp_status = _make_label("", UiTheme.FONT_BODY, UiTheme.TEXT_DIM)
	box.add_child(_warp_status)
	_warp_button = _add_button(box, tr("Watch ad for time warp"), _on_time_warp_pressed)
	_add_button(box, tr("Close"), _on_close_pressed)

	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 1.0
	_refresh_timer.autostart = true
	_refresh_timer.timeout.connect(_refresh_state)
	add_child(_refresh_timer)
	_refresh_state()


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


func _on_boost_pressed() -> void:
	AdService.show_rewarded("boost_2x", _on_boost_result)


func _on_boost_result(granted: bool) -> void:
	if granted:
		GameState.grant_boost_2x()
		_boost_status.text = tr("2× revenue: %s remaining") % NumFormat.duration(GameState.boost_2x_remaining)
	else:
		_boost_status.text = tr("No ad available")


func _on_time_warp_pressed() -> void:
	AdService.show_rewarded("time_warp", _on_time_warp_result)


func _on_time_warp_result(granted: bool) -> void:
	if not granted:
		_warp_status.text = tr("No ad available")
		return
	if not GameState.use_time_warp(TimeService.now_unix()):
		_refresh_state()
		return
	_warp_status.text = tr("Time warp paid 20 minutes of income")
	_refresh_state()


func _refresh_state() -> void:
	var boost_seconds: float = GameState.boost_2x_remaining
	if boost_seconds > 0.0:
		_boost_status.text = tr("2× revenue: %s remaining") % NumFormat.duration(boost_seconds)
	else:
		_boost_status.text = tr("No active boost")
	var cooldown: float = maxf(0.0, GameState.time_warp_cooldown_until - TimeService.now_unix())
	_warp_button.disabled = cooldown > 0.0
	if cooldown > 0.0:
		_warp_status.text = tr("Time warp ready in %s") % NumFormat.duration(cooldown)
	else:
		_warp_status.text = tr("Time warp ready")


func _on_close_pressed() -> void:
	PopupHost.instance.close_current()
