extends Control
## The More tab. Opens Settings and the other popups. Handles the Android back button.

const PATH_STATS: String = "res://scenes/ui/popup_stats.gd"
const PATH_MILESTONES: String = "res://scenes/ui/popup_milestones.gd"
const PATH_DAILY: String = "res://scenes/ui/popup_daily.gd"
const PATH_CONTRACTS: String = "res://scenes/ui/popup_contracts.gd"
const PATH_COSMETICS: String = "res://scenes/ui/popup_cosmetics.gd"


func _ready() -> void:
	get_tree().quit_on_go_back = false

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTheme.PAD)
	scroll.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", UiTheme.PAD)
	margin.add_child(box)

	_add_button(box, tr("Settings"), _open_settings)
	_add_button(box, tr("Stats"), _open_popup.bind(PATH_STATS))
	_add_button(box, tr("Milestones"), _open_popup.bind(PATH_MILESTONES))
	_add_button(box, tr("Daily reward"), _open_popup.bind(PATH_DAILY))
	_add_button(box, tr("Contracts"), _open_popup.bind(PATH_CONTRACTS))
	_add_button(box, tr("Cosmetics"), _open_popup.bind(PATH_COSMETICS))

	var version: String = str(ProjectSettings.get_setting("application/config/version", "0.1"))
	var version_label: Label = Label.new()
	version_label.text = "v" + version
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_font_size_override("font_size", UiTheme.FONT_SMALL)
	version_label.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
	box.add_child(version_label)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()


func _add_button(box: VBoxContainer, title: String, handler: Callable) -> void:
	var button: BigButton = BigButton.new()
	button.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
	box.add_child(button)
	button.set_title(title)
	button.pressed.connect(handler)


func _open_settings() -> void:
	PopupHost.instance.show_popup(PopupSettings.new())


## Show a placeholder popup when its script exists. Otherwise show a short message.
func _open_popup(path: String) -> void:
	if ResourceLoader.exists(path):
		var script: GDScript = load(path) as GDScript
		var popup: Control = script.new() as Control
		PopupHost.instance.show_popup(popup)
	else:
		PopupHost.instance.toast(tr("Coming soon"))


## Close an open popup first. Otherwise save and quit the app.
func _on_back_pressed() -> void:
	if PopupHost.instance != null and PopupHost.instance.visible:
		PopupHost.instance.close_current()
		return
	SaveService.save()
	get_tree().quit()
