class_name PopupSettings
extends PanelContainer
## Settings popup: company name, sound and vibration toggles, privacy links, reset save.

const PRIVACY_URL: String = "https://example.com/privacy"
const COMPANY_NAME_MAX: int = 20
const RESET_CONFIRM_SECONDS: float = 3.0

var _name_edit: LineEdit = null
var _reset_button: BigButton = null
var _reset_timer: Timer = null
var _reset_armed: bool = false


func _ready() -> void:
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTheme.PAD)
	add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTheme.PAD)
	margin.add_child(box)

	box.add_child(_make_label(tr("Settings"), UiTheme.FONT_TITLE, UiTheme.TEXT))
	box.add_child(_make_label(tr("Company name"), UiTheme.FONT_BODY, UiTheme.TEXT_DIM))
	_name_edit = LineEdit.new()
	_name_edit.max_length = COMPANY_NAME_MAX
	_name_edit.text = GameState.company_name
	_name_edit.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
	box.add_child(_name_edit)
	_add_button(box, tr("Save name"), _on_save_name_pressed)
	box.add_child(_make_toggle(tr("Music"), "music"))
	box.add_child(_make_toggle(tr("Sound effects"), "sfx"))
	box.add_child(_make_toggle(tr("Vibration"), "haptics"))
	_add_button(box, tr("Privacy policy"), _on_privacy_pressed)
	_add_button(box, tr("Privacy options"), _on_privacy_options_pressed)
	_reset_button = _add_button(box, tr("Reset save"), _on_reset_pressed)
	_add_button(box, tr("Close"), _on_close_pressed)

	_reset_timer = Timer.new()
	_reset_timer.one_shot = true
	_reset_timer.wait_time = RESET_CONFIRM_SECONDS
	_reset_timer.timeout.connect(_disarm_reset)
	add_child(_reset_timer)


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


func _make_toggle(title: String, key: String) -> CheckButton:
	var toggle: CheckButton = CheckButton.new()
	toggle.text = title
	toggle.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
	toggle.button_pressed = bool(GameState.settings.get(key, true))
	toggle.toggled.connect(_on_toggled.bind(key))
	return toggle


func _on_toggled(on: bool, key: String) -> void:
	GameState.set_setting(key, on)


## Ignore empty names. Otherwise rename the company and refresh the HUD.
func _on_save_name_pressed() -> void:
	var text: String = _name_edit.text.strip_edges()
	if text.is_empty():
		return
	GameState.set_company_name(text)
	EventBus.state_loaded.emit()


func _on_privacy_pressed() -> void:
	OS.shell_open(PRIVACY_URL)


func _on_privacy_options_pressed() -> void:
	if AdService.has_method("show_privacy_options"):
		AdService.show_privacy_options()


## The first tap arms the reset. A second tap within the time limit erases the save.
func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_button.set_title(tr("Tap again to erase everything"))
		_reset_timer.start()
		return
	_reset_timer.stop()
	GameState.new_game()
	SaveService.save()
	EventBus.state_loaded.emit()
	PopupHost.instance.close_current()


func _disarm_reset() -> void:
	_reset_armed = false
	_reset_button.set_title(tr("Reset save"))


func _on_close_pressed() -> void:
	PopupHost.instance.close_current()
