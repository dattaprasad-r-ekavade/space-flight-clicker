class_name DataLoader
extends RefCounted
## Loads JSON content files from res://data/ and caches the division list.
## Pure data access: no nodes, no autoloads, no clock.

const DIVISIONS_PATH: String = "res://data/divisions.json"

static var _divisions_cache: Array[Dictionary] = []
static var _divisions_loaded: bool = false


## Reads a JSON file and returns the parsed value (Array, Dictionary, ...).
## Returns null when the file is missing or the text is not valid JSON.
static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("DataLoader: missing file %s" % path)
		return null
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("DataLoader: invalid JSON in %s" % path)
	return parsed


## Returns the nine divisions in stage order. Parsed once, then cached.
## Every number is converted to float, except pump_taps, which is int.
static func divisions() -> Array[Dictionary]:
	if not _divisions_loaded:
		_divisions_loaded = true
		var raw: Variant = load_json(DIVISIONS_PATH)
		if raw is Array:
			for entry: Variant in raw:
				if entry is Dictionary:
					_divisions_cache.append(_normalise_division(entry))
	var out: Array[Dictionary] = []
	for division: Dictionary in _divisions_cache:
		out.append(division.duplicate())
	return out


static func _normalise_division(raw: Dictionary) -> Dictionary:
	return {
		"id": str(raw.get("id", "")),
		"name_key": str(raw.get("name_key", "")),
		"stage_name": str(raw.get("stage_name", "")),
		"h_start": float(raw.get("h_start", 0.0)),
		"h_ceiling": float(raw.get("h_ceiling", 0.0)),
		"base_cost": float(raw.get("base_cost", 0.0)),
		"growth": float(raw.get("growth", 1.0)),
		"base_rev": float(raw.get("base_rev", 0.0)),
		"base_flight_s": float(raw.get("base_flight_s", 0.0)),
		"pump_taps": int(raw.get("pump_taps", 0)),
	}
