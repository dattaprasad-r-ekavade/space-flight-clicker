extends Node
## Writes and reads the save file. Autosaves on a timer, on pause, and on close.
## Node lookups run only when this node is in the scene tree (for example in tests they do not).

const SAVE_VERSION: int = 1
const AUTOSAVE_SECONDS: float = 30.0

## Path of the save file. Tests change this to a file under user://test/.
var save_path: String = "user://save.json"

var _autosave_timer: Timer = null


func _ready() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_SECONDS
	_autosave_timer.timeout.connect(save)
	add_child(_autosave_timer)
	_autosave_timer.start()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_inside_tree():
			save()


## Save the current GameState. Returns false when GameState is missing or the write fails.
func save() -> bool:
	var gs: Node = _autoload("GameState")
	if gs == null:
		return false
	gs.set("last_seen_unix", _now())
	var state: Dictionary = gs.call("to_dict")
	return save_state(state)


## Load the saved state into GameState. Returns false when nothing can be loaded.
func load_game() -> bool:
	var gs: Node = _autoload("GameState")
	var state: Dictionary = load_state()
	if gs == null or state.is_empty():
		return false
	gs.call("from_dict", state)
	gs.call("compute_pending_offline", _now())
	return true


## Write `state` to a temp file, keep the old save as the backup, then rename the temp file.
## Returns false when a step fails. The old save stays in place if the temp write fails.
func save_state(state: Dictionary) -> bool:
	var payload: Dictionary = {"version": SAVE_VERSION, "saved_at": _now(), "state": state}
	var tmp_path: String = save_path + ".tmp"
	var bak_path: String = save_path + ".bak"
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload))
	file.close()
	if FileAccess.file_exists(save_path):
		if DirAccess.copy_absolute(save_path, bak_path) != OK:
			return false
		DirAccess.remove_absolute(save_path)
	return DirAccess.rename_absolute(tmp_path, save_path) == OK


## Read the save file. Uses the backup when the main file is missing or does not parse.
## Returns the saved "state" Dictionary, or an empty Dictionary when nothing can be loaded.
func load_state() -> Dictionary:
	var state: Dictionary = _read_state(save_path)
	if state.is_empty():
		state = _read_state(save_path + ".bak")
	return state


func _read_state(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var root: Dictionary = parsed
	if not root.has("state") or typeof(root["state"]) != TYPE_DICTIONARY:
		return {}
	var state: Dictionary = root["state"]
	return state


## Unix time for `saved_at`. Uses TimeService when it is available.
func _now() -> float:
	var ts: Node = _autoload("TimeService")
	if ts != null:
		return float(ts.call("now_unix"))
	return Time.get_unix_time_from_system()


## Find an autoload by name. Returns null outside the scene tree or when it is missing.
func _autoload(node_name: String) -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/" + node_name)
