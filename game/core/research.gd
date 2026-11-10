class_name Research
extends RefCounted
## Research rules: node lookup, buy check, and the multipliers used by GameState.
## Pure logic. Owned research is passed in as a Dictionary (id -> true).
## Node data lives in game/data/research.json.

const PATH: String = "res://data/research.json"
const MIN_PUMP_TAPS: int = 2

static var _cache: Array[Dictionary] = []
static var _loaded: bool = false


## Returns the 29 research nodes in file order. Parsed once, then cached.
static func nodes() -> Array[Dictionary]:
	if not _loaded:
		_loaded = true
		var raw: Variant = DataLoader.load_json(PATH)
		if raw is Array:
			for item: Variant in raw:
				if item is Dictionary:
					var entry: Dictionary = item
					_cache.append(entry)
	return _cache


## Returns the node with this id, or an empty Dictionary when none matches.
static func find(id: String) -> Dictionary:
	for node: Dictionary in nodes():
		if str(node["id"]) == id:
			return node
	return {}


## True when the node exists, is not owned, its stage is unlocked, and revenue covers its cost.
static func can_buy(node: Dictionary, owned: Dictionary, stage_unlocked: bool, revenue: float) -> bool:
	if node.is_empty() or owned.has(node["id"]):
		return false
	if not stage_unlocked:
		return false
	return float(node["cost"]) <= revenue


## Product of owned division nodes for one division. Neutral (1.0) when none are owned.
static func revenue_mult(owned: Dictionary, division_id: String) -> float:
	var result: float = 1.0
	for node: Dictionary in nodes():
		if str(node["group"]) == "division" and str(node["division"]) == division_id and owned.has(node["id"]):
			result *= float(node["value"])
	return result


## Product of owned global nodes. Applies to all revenue.
static func global_mult(owned: Dictionary) -> float:
	return _group_product(owned, "global")


## Product of owned flight nodes. Applies to flight time of all divisions.
static func flight_mult(owned: Dictionary) -> float:
	return _group_product(owned, "flight")


## Product of owned pump nodes. Applies to pump taps of all divisions.
static func pump_mult(owned: Dictionary) -> float:
	return _group_product(owned, "pump")


## Pump taps needed for one launch after research. Never below MIN_PUMP_TAPS.
static func pump_taps(base_taps: int, owned: Dictionary) -> int:
	return maxi(MIN_PUMP_TAPS, roundi(float(base_taps) * pump_mult(owned)))


static func _group_product(owned: Dictionary, group: String) -> float:
	var result: float = 1.0
	for node: Dictionary in nodes():
		if str(node["group"]) == group and owned.has(node["id"]):
			result *= float(node["value"])
	return result
