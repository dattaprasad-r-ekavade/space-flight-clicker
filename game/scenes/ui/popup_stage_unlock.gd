class_name PopupStageUnlock
extends PanelContainer
## Shows a newly unlocked stage. Offers Go, which buys the first level if needed and selects the stage.

var _id: String = ""


## Set the division id before the popup is added to the tree.
func setup(id: String) -> void:
	_id = id


func _ready() -> void:
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTheme.PAD)
	add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTheme.PAD)
	margin.add_child(box)

	box.add_child(_make_label(tr("New stage unlocked"), UiTheme.FONT_BODY, UiTheme.TEXT_DIM))
	box.add_child(_make_label(tr(_stage_name()), UiTheme.FONT_TITLE, UiTheme.ACCENT))
	box.add_child(_make_label(_fantasy_line(), UiTheme.FONT_BODY, UiTheme.TEXT))
	_add_button(box, tr("Go"), _on_go_pressed)


func _stage_name() -> String:
	if not GameState.division_data.has(_id):
		return ""
	return str(GameState.division_data[_id]["stage_name"])


func _fantasy_line() -> String:
	match _id:
		"bottles":
			return tr("Pure childhood wonder")
		"model_rockets":
			return tr("Your first real engineering")
		"sounding":
			return tr("The edge of space")
		"orbital":
			return tr("A real space company")
		"station":
			return tr("A permanent home in orbit")
		"moon":
			return tr("Another world")
		"solar":
			return tr("A network across the planets")
		"galaxy":
			return tr("Between the stars")
		"black_hole":
			return tr("The edge of everything")
	return ""


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _add_button(box: VBoxContainer, title: String, handler: Callable) -> void:
	var button: BigButton = BigButton.new()
	button.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
	box.add_child(button)
	button.set_title(title)
	button.pressed.connect(handler)


func _on_go_pressed() -> void:
	if GameState.divisions.has(_id) and int(GameState.divisions[_id]["level"]) == 0:
		# May fail when revenue is low. That is fine.
		GameState.buy_levels(_id, 1)
	GameState.select_division(_id)
	PopupHost.instance.close_current()
	# Design section 11: an interstitial may show after a stage unlock, from stage 4 on. AdService applies the time rules.
	if GameState.division_order.find(_id) >= 3:
		AdService.maybe_show_interstitial("stage_unlock")
