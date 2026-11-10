class_name PopupCosmetics
extends PanelContainer
## Choose an unlocked bottle skin or trail colour.

var _box: VBoxContainer
var _status_label: Label


func _ready() -> void:
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTheme.PAD)
	add_child(margin)

	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", UiTheme.PAD)
	margin.add_child(_box)
	_box.add_child(_make_label(tr("Cosmetics"), UiTheme.FONT_TITLE, UiTheme.TEXT))
	_status_label = _make_label("", UiTheme.FONT_BODY, UiTheme.TEXT_DIM)
	_box.add_child(_status_label)
	_refresh_options()


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _add_button(title: String, handler: Callable) -> void:
	var button: BigButton = BigButton.new()
	button.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
	_box.add_child(button)
	button.set_title(title)
	button.pressed.connect(handler)


func _refresh_options() -> void:
	for child: Node in _box.get_children():
		if child != _box.get_child(0) and child != _status_label:
			_box.remove_child(child)
			child.queue_free()
	_status_label.text = tr("Bottle skin and trail choices stay through prestige")
	_add_button(tr("Default bottle"), _on_skin_selected.bind(""))
	var skin_ids: Array[String] = GameState.unlocked_skin_ids()
	if skin_ids.is_empty():
		_box.add_child(_make_label(tr("No bottle skins unlocked yet"), UiTheme.FONT_SMALL, UiTheme.TEXT_DIM))
	for skin_id: String in skin_ids:
		_add_button(_skin_title(skin_id), _on_skin_selected.bind(skin_id))
	_add_button(tr("Default trail"), _on_trail_selected.bind("default"))
	for trail_id: String in GameState.unlocked_trail_ids():
		if trail_id == "default":
			continue
		_add_button(_trail_title(trail_id), _on_trail_selected.bind(trail_id))
	_add_button(tr("Close"), _on_close_pressed)


func _skin_title(id: String) -> String:
	var number: String = id.get_slice("_", id.get_slice_count("_") - 1)
	return tr("Bottle skin %s") % number


func _trail_title(id: String) -> String:
	match id:
		"blue": return tr("Blue trail")
		"orange": return tr("Orange trail")
		"cyan": return tr("Cyan trail")
		"purple": return tr("Purple trail")
	return tr("Default trail")


func _on_skin_selected(id: String) -> void:
	if GameState.choose_bottle_skin(id):
		_refresh_options()


func _on_trail_selected(id: String) -> void:
	if GameState.choose_trail_color(id):
		_refresh_options()


func _on_close_pressed() -> void:
	PopupHost.instance.close_current()
