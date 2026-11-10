extends Control
## Screenshot helper for the Lead. main.gd adds this as an overlay part.
## It does nothing unless the game starts with a user argument:
##   GODOT --path game -- --shot=<folder> [--state=mid]
## It then saves one PNG per bottom tab into <folder> and quits. Task T031 extends it with popups.

const SETTLE_FRAMES: int = 12


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var folder: String = _arg("--shot=")
	if folder.is_empty():
		return
	_run.call_deferred(folder)


func _run(folder: String) -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	if _arg("--state=") == "mid":
		_prepare_mid_state()
	elif _arg("--state=") == "new":
		_prepare_new_state()
	var main: Node = get_parent()
	var strip: Node = main.find_child("TabStrip", true, false)
	var tab_count: int = 5
	for i: int in range(tab_count):
		if strip != null:
			strip.select(i)
		if main.has_method("_show_tab"):
			main.call("_show_tab", i)
		await _settle()
		_save(folder.path_join("tab_%d.png" % i))
	get_tree().quit()


## A state in the middle of the first life: three stages, two managers, some money.
func _prepare_mid_state() -> void:
	GameState.new_game()
	GameState.revenue = 1.0e9
	GameState.buy_levels("bottles", 30)
	GameState.buy_manager("bottles")
	GameState.buy_levels("model_rockets", 26)
	GameState.buy_manager("model_rockets")
	GameState.buy_levels("sounding", 7)
	GameState.buy_research("pump_1")
	GameState.select_division("sounding")
	GameState.revenue = 123456.0
	for i: int in range(6):
		GameState.pump("sounding")
	EventBus.state_loaded.emit()
	EventBus.revenue_changed.emit(GameState.revenue)


## A fresh game, one bottle level, with a launch in progress.
func _prepare_new_state() -> void:
	GameState.new_game()
	GameState.buy_levels("bottles", 1)
	EventBus.state_loaded.emit()
	for i: int in range(5):
		GameState.pump("bottles")
	GameState.launch("bottles")


func _settle() -> void:
	for i: int in range(SETTLE_FRAMES):
		await get_tree().process_frame


func _save(path: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(path)
	print("SHOT ", path)


func _arg(prefix: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return ""
