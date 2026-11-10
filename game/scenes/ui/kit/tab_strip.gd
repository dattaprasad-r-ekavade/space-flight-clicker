class_name TabStrip
extends HBoxContainer
## A row of equal-width toggle tabs. The selected tab uses the accent colour.
## tab_selected is emitted when the player taps a tab. select() does not emit it.

signal tab_selected(index: int)

var _names: Array[String] = []
var _buttons: Array[Button] = []
var _selected: int = -1
var _built: bool = false


func _ready() -> void:
	_built = true
	_rebuild()


## Replaces all tabs. The first tab is selected.
func set_tabs(names: Array[String]) -> void:
	_names.clear()
	for name_text: String in names:
		_names.append(name_text)
	_selected = 0 if _names.size() > 0 else -1
	if _built:
		_rebuild()


## Highlights the tab at index. Does nothing when index is out of range.
func select(index: int) -> void:
	if index < 0 or index >= _names.size():
		return
	_selected = index
	_paint_all()


func get_selected() -> int:
	return _selected


func get_tab_count() -> int:
	return _names.size()


func _rebuild() -> void:
	for old: Button in _buttons:
		remove_child(old)
		old.queue_free()
	_buttons.clear()
	for i: int in range(_names.size()):
		var tab: Button = Button.new()
		tab.text = _names[i]
		tab.toggle_mode = true
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size = Vector2(UiTheme.TOUCH, UiTheme.TOUCH)
		tab.pressed.connect(_on_tab_pressed.bind(i))
		add_child(tab)
		_buttons.append(tab)
	_paint_all()


func _on_tab_pressed(index: int) -> void:
	select(index)
	tab_selected.emit(index)


func _paint_all() -> void:
	for i: int in range(_buttons.size()):
		_paint(_buttons[i], i == _selected)


func _paint(tab: Button, selected: bool) -> void:
	tab.button_pressed = selected
	if not selected:
		tab.remove_theme_stylebox_override("normal")
		tab.remove_theme_stylebox_override("hover")
		tab.remove_theme_stylebox_override("pressed")
		tab.remove_theme_color_override("font_color")
		return
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = UiTheme.ACCENT
	box.set_corner_radius_all(UiTheme.RADIUS)
	tab.add_theme_stylebox_override("normal", box)
	tab.add_theme_stylebox_override("hover", box)
	tab.add_theme_stylebox_override("pressed", box)
	tab.add_theme_color_override("font_color", UiTheme.BG)
