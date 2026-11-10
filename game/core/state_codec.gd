class_name StateCodec
extends RefCounted
## Converts GameState values to and from a plain Dictionary for saving.
## Holds no state. It only reads and writes the properties of the GameState node it is given.

const FLOAT_KEYS: PackedStringArray = ["revenue", "run_revenue", "record_height", "lifetime_height", "last_seen_unix"]
const INT_KEYS: PackedStringArray = ["echoes", "life"]
const DIVISION_INT_KEYS: PackedStringArray = ["level", "fuel_taps"]
const DIVISION_FLOAT_KEYS: PackedStringArray = ["cycle_elapsed"]
const DIVISION_BOOL_KEYS: PackedStringArray = ["has_manager", "flying"]


## Build the save Dictionary from the GameState node `gs`.
static func to_dict(gs: Node) -> Dictionary:
	var data: Dictionary = {}
	for key: String in FLOAT_KEYS:
		data[key] = float(gs.get(key))
	for key: String in INT_KEYS:
		data[key] = int(gs.get(key))
	data["company_name"] = str(gs.get("company_name"))
	data["echo_levels"] = (gs.get("echo_levels") as Dictionary).duplicate()
	data["selected_division"] = str(gs.get("selected_division"))
	data["owned_research"] = (gs.get("owned_research") as Dictionary).duplicate()
	data["settings"] = (gs.get("settings") as Dictionary).duplicate()
	data["divisions"] = _divisions_to_dict(gs)
	return data


## Replace the state of the GameState node `gs` with values from `data`.
## Starts from new_game() defaults. Unknown keys are ignored. Missing keys keep defaults.
static func apply_dict(gs: Node, data: Dictionary) -> void:
	gs.call("new_game")
	for key: String in FLOAT_KEYS:
		if data.has(key):
			gs.set(key, float(data[key]))
	for key: String in INT_KEYS:
		if data.has(key):
			gs.set(key, int(data[key]))
	if data.has("company_name"):
		gs.set("company_name", str(data["company_name"]))
	if data.has("echo_levels") and typeof(data["echo_levels"]) == TYPE_DICTIONARY:
		gs.set("echo_levels", (data["echo_levels"] as Dictionary).duplicate())
	if data.has("owned_research") and typeof(data["owned_research"]) == TYPE_DICTIONARY:
		gs.set("owned_research", (data["owned_research"] as Dictionary).duplicate())
	if data.has("settings") and typeof(data["settings"]) == TYPE_DICTIONARY:
		_apply_settings(gs, data["settings"] as Dictionary)
	if data.has("selected_division"):
		_apply_selected(gs, str(data["selected_division"]))
	if data.has("divisions") and typeof(data["divisions"]) == TYPE_DICTIONARY:
		_apply_divisions(gs, data["divisions"] as Dictionary)


## Copy saved setting values onto the defaults. Only keys that already exist are used.
static func _apply_settings(gs: Node, saved: Dictionary) -> void:
	var current: Dictionary = (gs.get("settings") as Dictionary).duplicate()
	for key: String in current.keys():
		if saved.has(key):
			current[key] = bool(saved[key])
	gs.set("settings", current)


static func _divisions_to_dict(gs: Node) -> Dictionary:
	var out: Dictionary = {}
	var states: Dictionary = gs.get("divisions")
	for id: String in states.keys():
		out[id] = (states[id] as Dictionary).duplicate()
	return out


## Keep the saved selection only when the division exists in this build's data.
static func _apply_selected(gs: Node, id: String) -> void:
	var order: Array = gs.get("division_order")
	if order.has(id):
		gs.set("selected_division", id)


## Copy saved division values onto the defaults. Only ids in the data file are used.
static func _apply_divisions(gs: Node, saved: Dictionary) -> void:
	var states: Dictionary = gs.get("divisions")
	var order: Array = gs.get("division_order")
	for id: String in order:
		if not saved.has(id) or typeof(saved[id]) != TYPE_DICTIONARY:
			continue
		var src: Dictionary = saved[id]
		var state: Dictionary = states[id]
		for key: String in DIVISION_INT_KEYS:
			if src.has(key):
				state[key] = int(src[key])
		for key: String in DIVISION_FLOAT_KEYS:
			if src.has(key):
				state[key] = float(src[key])
		for key: String in DIVISION_BOOL_KEYS:
			if src.has(key):
				state[key] = bool(src[key])
