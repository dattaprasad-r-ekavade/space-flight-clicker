class_name PopupStats
extends PanelContainer
## Read-only lifetime and run statistics popup.


func _ready() -> void:
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTheme.PAD)
	add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTheme.PAD)
	margin.add_child(box)
	box.add_child(_make_label(tr("Statistics"), UiTheme.FONT_TITLE, UiTheme.TEXT))
	_add_stat(box, tr("Life"), str(GameState.life))
	_add_stat(box, tr("Total launches"), str(GameState.total_launches))
	_add_stat(box, tr("Lifetime height"), NumFormat.height(GameState.lifetime_height))
	_add_stat(box, tr("Play time"), NumFormat.duration(GameState.play_time_seconds))
	_add_stat(box, tr("Best run time"), NumFormat.duration(GameState.best_run_time_seconds))
	var close_button: BigButton = BigButton.new()
	close_button.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
	close_button.set_title(tr("Close"))
	close_button.pressed.connect(_on_close_pressed)
	box.add_child(close_button)


func _add_stat(box: VBoxContainer, title: String, value: String) -> void:
	box.add_child(_make_label(tr("%s: %s") % [title, value], UiTheme.FONT_BODY, UiTheme.TEXT_DIM))


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_close_pressed() -> void:
	PopupHost.instance.close_current()
