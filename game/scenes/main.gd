extends Control
## Root scene. Children are built in code (see conventions.md, "Scene rules").


func _ready() -> void:
	var title: Label = Label.new()
	title.text = "Idle Space Company"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(title)
