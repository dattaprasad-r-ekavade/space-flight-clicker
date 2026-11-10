class_name PanelCard
extends PanelContainer
## A rounded panel. Add child controls to content(). content() works before the node enters the tree.

var _margin: MarginContainer = null
var _box: VBoxContainer = null


func _ready() -> void:
	_build()


## Returns the box where callers add their children.
func content() -> VBoxContainer:
	_build()
	return _box


func _build() -> void:
	if _box != null:
		return
	_margin = MarginContainer.new()
	add_child(_margin)
	_box = VBoxContainer.new()
	_margin.add_child(_box)
