class_name BigButton
extends Button
## A large touch button with a title line and an optional smaller subtitle line.
## Set the text before or after the node enters the tree.

var _title_text: String = ""
var _subtitle_text: String = ""
var _affordable: bool = true
var _box: VBoxContainer = null
var _title_label: Label = null
var _subtitle_label: Label = null


func _init() -> void:
	custom_minimum_size = Vector2(UiTheme.TOUCH, UiTheme.TOUCH)


func _ready() -> void:
	_build()


func set_title(text: String) -> void:
	_title_text = text
	_refresh()


func set_subtitle(text: String) -> void:
	_subtitle_text = text
	_refresh()


## Disables the button and dims its text when ok is false.
func set_affordable(ok: bool) -> void:
	_affordable = ok
	disabled = not ok
	_refresh()


func get_title() -> String:
	return _title_text


func get_subtitle() -> String:
	return _subtitle_text


func is_affordable() -> bool:
	return _affordable


func _build() -> void:
	if _box != null:
		return
	_box = VBoxContainer.new()
	_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_box)
	_title_label = _make_label()
	_subtitle_label = _make_label()
	_subtitle_label.add_theme_font_size_override("font_size", UiTheme.FONT_SMALL)
	_box.add_child(_title_label)
	_box.add_child(_subtitle_label)
	_refresh()


func _make_label() -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _refresh() -> void:
	if _title_label == null:
		return
	_title_label.text = _title_text
	_subtitle_label.text = _subtitle_text
	_subtitle_label.visible = _subtitle_text != ""
	var title_color: Color = UiTheme.TEXT if _affordable else UiTheme.TEXT_DIM
	_title_label.add_theme_color_override("font_color", title_color)
	_subtitle_label.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
