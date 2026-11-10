class_name PopupMilestones
extends PanelContainer
## Lists Lifetime Height milestones and shows which have been reached.


func _ready() -> void:
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTheme.PAD)
	add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTheme.PAD)
	margin.add_child(box)
	box.add_child(_make_label(tr("Lifetime milestones"), UiTheme.FONT_TITLE, UiTheme.TEXT))

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH * 4.0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", UiTheme.PAD / 2)
	scroll.add_child(list)
	var lifetime_height: float = float(GameState.lifetime_height)
	for milestone: Dictionary in Milestones.items():
		var status: String = tr("Reached") if Milestones.is_reached(milestone, lifetime_height) else tr("Not reached")
		var title: String = tr(str(milestone.get("name_key", "")))
		list.add_child(_make_label("%s — %s" % [title, status], UiTheme.FONT_BODY, UiTheme.TEXT))

	_add_button(box, tr("Close"), _on_close_pressed)


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


func _on_close_pressed() -> void:
	PopupHost.instance.close_current()
