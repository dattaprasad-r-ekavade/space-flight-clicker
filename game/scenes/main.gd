extends Control
## Root scene. Children are built in code (see conventions.md, "Scene rules").
## Top 55 % is the 3D world with the HUD area on top. Bottom 45 % is the tab panel.

const SKY_COLOR: Color = Color("#87CEEB")
const CAMERA_POS: Vector3 = Vector3(0.0, 3.0, 12.0)
const LOOK_AT: Vector3 = Vector3(0.0, 3.0, 0.0)
const SPLIT: float = 0.55
const TAB_IDS: Array[String] = ["Divisions", "Managers", "Research", "Echoes", "More"]

## UI parts that are added when their script file exists. A UI card only creates its file; it does not edit main.gd.
## Each script extends Control and builds itself in _ready().
const HUD_PARTS: Array[String] = [
	"res://scenes/ui/hud.gd",
	"res://scenes/ui/launch_controls.gd",
	"res://scenes/ui/tutorial.gd",
]
## Full-screen layers above everything, in this order.
const OVERLAY_PARTS: Array[String] = [
	"res://scenes/ui/juice.gd",
	"res://scenes/ui/popup_host.gd",
	"res://scenes/ui/debug_panel.gd",
	"res://tools/screenshot.gd",
]
const TAB_PARTS: Array[String] = [
	"res://scenes/ui/tab_divisions.gd",
	"res://scenes/ui/tab_managers.gd",
	"res://scenes/ui/tab_research.gd",
	"res://scenes/ui/tab_echoes.gd",
	"res://scenes/ui/tab_more.gd",
]

var _world: Node3D
var _hud_area: Control
var _tab_content: Control
var _tab_strip: TabStrip
var _tabs: Array[Control] = []


func _ready() -> void:
	theme = UiTheme.build()
	SaveService.load_game()
	_build_world()
	_build_hud_area()
	_build_bottom_panel()
	_apply_safe_area()
	_add_parts()
	_tab_strip.select(0)
	_show_tab(0)


func _process(delta: float) -> void:
	GameState.tick(delta)


func hud_area() -> Control:
	return _hud_area


func world() -> Node3D:
	return _world


## Replaces the placeholder of one tab with content. The content fills the tab.
func set_tab_content(index: int, content: Control) -> void:
	if index < 0 or index >= _tabs.size():
		return
	var tab: Control = _tabs[index]
	for child: Node in tab.get_children():
		tab.remove_child(child)
		child.queue_free()
	if content.get_parent() != null:
		content.get_parent().remove_child(content)
	tab.add_child(content)
	_set_anchors(content, 0.0, 1.0)


func _build_world() -> void:
	_world = Node3D.new()
	_world.name = "World"
	add_child(_world)
	var cam: Camera3D = Camera3D.new()
	cam.name = "Camera"
	_world.add_child(cam)
	cam.position = CAMERA_POS
	cam.look_at(LOOK_AT)
	cam.current = true
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY_COLOR
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	_world.add_child(world_env)


func _build_hud_area() -> void:
	_hud_area = Control.new()
	_hud_area.name = "HudArea"
	_hud_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_anchors(_hud_area, 0.0, SPLIT)
	add_child(_hud_area)


func _build_bottom_panel() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "BottomPanel"
	_set_anchors(panel, SPLIT, 1.0)
	add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "Column"
	panel.add_child(column)
	_tab_content = Control.new()
	_tab_content.name = "TabContent"
	_tab_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_tab_content)
	var titles: Array[String] = _tab_titles()
	for i: int in TAB_IDS.size():
		_add_tab(i, titles[i])
	_tab_strip = TabStrip.new()
	_tab_strip.name = "TabStrip"
	_tab_strip.set_tabs(titles)
	_tab_strip.tab_selected.connect(_show_tab)
	column.add_child(_tab_strip)


func _add_tab(index: int, title: String) -> void:
	var tab: Control = Control.new()
	tab.name = "Tab" + TAB_IDS[index]
	_tab_content.add_child(tab)
	_set_anchors(tab, 0.0, 1.0)
	var placeholder: Label = Label.new()
	placeholder.text = title
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tab.add_child(placeholder)
	_set_anchors(placeholder, 0.0, 1.0)
	_tabs.append(tab)


func _tab_titles() -> Array[String]:
	return [tr("Divisions"), tr("Managers"), tr("Research"), tr("Echoes"), tr("More")]


func _show_tab(index: int) -> void:
	for i: int in _tabs.size():
		_tabs[i].visible = i == index


func _apply_safe_area() -> void:
	_hud_area.offset_top = _top_inset_viewport()


## Returns the notch height in viewport units. Returns 0 when the window has no size.
func _top_inset_viewport() -> float:
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var window_h: int = DisplayServer.window_get_size().y
	if safe.size == Vector2i.ZERO or window_h <= 0:
		return 0.0
	var inset_px: float = float(safe.position.y)
	return inset_px * get_viewport_rect().size.y / float(window_h)


## Sets left and right to the parent edges, and top and bottom to fractions of the parent height.
func _set_anchors(c: Control, top: float, bottom: float) -> void:
	c.anchor_left = 0.0
	c.anchor_right = 1.0
	c.anchor_top = top
	c.anchor_bottom = bottom
	c.offset_left = 0.0
	c.offset_right = 0.0
	c.offset_top = 0.0
	c.offset_bottom = 0.0


## Adds every UI part whose script exists. HUD parts fill the HUD area; tab parts replace the placeholders.
func _add_parts() -> void:
	for path: String in HUD_PARTS:
		var part: Control = _make_part(path)
		if part != null:
			_hud_area.add_child(part)
			_set_anchors(part, 0.0, 1.0)
	for i: int in TAB_PARTS.size():
		var tab_part: Control = _make_part(TAB_PARTS[i])
		if tab_part != null:
			set_tab_content(i, tab_part)
	for path: String in OVERLAY_PARTS:
		var layer: Control = _make_part(path)
		if layer != null:
			add_child(layer)
			_set_anchors(layer, 0.0, 1.0)


func _make_part(path: String) -> Control:
	if not ResourceLoader.exists(path):
		return null
	var part: Control = load(path).new() as Control
	if part != null:
		part.name = path.get_file().get_basename().to_pascal_case()
	return part
