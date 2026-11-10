extends Node
## Holds all mutable game state. UI reads this and calls its methods.
## Formulas live in game/core/economy.gd. Launch cycle rules live in game/core/launch_cycle.gd.

const FIRST_DIVISION_ID: String = "bottles"

var revenue: float = 0.0
var run_revenue: float = 0.0
var record_height: float = 0.0
var lifetime_height: float = 0.0
var echoes: int = 0
var life: int = 1
var company_name: String = ""
var selected_division: String = FIRST_DIVISION_ID

## Division data from DataLoader, keyed by division id.
var division_data: Dictionary = {}
## Division ids in stage order.
var division_order: Array[String] = []
## Per-division state, keyed by division id.
## Each value: {level, has_manager, fuel_taps, cycle_elapsed, flying}
var divisions: Dictionary = {}
## Research bought this life, id -> true. Reset on new game.
var owned_research: Dictionary = {}
## Unix time of the last save. Offline earnings count from this time. Saved.
var last_seen_unix: float = 0.0
## Offline earnings waiting to be claimed. Not saved. Keys: seconds_counted, revenue.
var pending_offline: Dictionary = {}
## Player settings: music, sfx, haptics. Saved. Not reset in new_game().
var settings: Dictionary = {"music": true, "sfx": true, "haptics": true}


func _ready() -> void:
	_load_division_data()
	new_game()


## Reset all state to a fresh-install value.
func new_game() -> void:
	if division_order.is_empty():
		_load_division_data()
	revenue = 0.0
	run_revenue = 0.0
	record_height = 0.0
	lifetime_height = 0.0
	echoes = 0
	life = 1
	company_name = tr("Bottle Rocket Co.")
	selected_division = FIRST_DIVISION_ID
	divisions = {}
	owned_research = {}
	last_seen_unix = 0.0
	pending_offline = {}
	for id: String in division_order:
		divisions[id] = _new_division_state()


## Snapshot of all saved state as a Dictionary. The conversion lives in StateCodec.
func to_dict() -> Dictionary:
	return StateCodec.to_dict(self)


## Replace all state with values from a saved Dictionary. Missing keys keep defaults.
func from_dict(data: Dictionary) -> void:
	StateCodec.apply_dict(self, data)


## Store one setting value. Keys: music, sfx, haptics.
func set_setting(key: String, on: bool) -> void:
	settings[key] = on


## Rename the company. The caller trims and checks the text.
func set_company_name(name_text: String) -> void:
	company_name = name_text


## Buy a research node with revenue. Returns false and changes nothing when the node
## is unknown, owned, locked by stage, or too expensive.
func buy_research(id: String) -> bool:
	var node: Dictionary = Research.find(id)
	var stage_ok: bool = not node.is_empty() and is_unlocked(str(node["requires_stage"]))
	if not Research.can_buy(node, owned_research, stage_ok, revenue):
		return false
	revenue -= float(node["cost"])
	owned_research[id] = true
	_emit_bus("revenue_changed", [revenue])
	return true


## True when the division can be bought. The first division is always unlocked.
func is_unlocked(id: String) -> bool:
	var index: int = division_order.find(id)
	if index < 0:
		return false
	if index == 0:
		return true
	var previous_id: String = division_order[index - 1]
	return int(divisions[previous_id]["level"]) >= Economy.LEVEL_UNLOCK


## Make a division the selected one. Returns false when it is locked.
func select_division(id: String) -> bool:
	if not is_unlocked(id):
		return false
	selected_division = id
	_emit_bus("division_changed", [id])
	return true


## Buy `count` levels of a division. Returns false and changes nothing
## when the division is locked, `count` is not positive, or revenue is too low.
func buy_levels(id: String, count: int) -> bool:
	if count <= 0 or not is_unlocked(id):
		return false
	var state: Dictionary = divisions[id]
	var level: int = int(state["level"])
	var cost: float = Economy.bulk_cost(division_data[id], level, count)
	if cost > revenue:
		return false
	revenue -= cost
	state["level"] = level + count
	_emit_bus("revenue_changed", [revenue])
	_emit_bus("division_changed", [id])
	_emit_unlock_if_crossed(id, level, level + count)
	return true


## --- Launch cycle. The logic is in game/core/launch_ops.gd. ---

func pump(id: String) -> bool:
	return LaunchOps.pump(self, id)


func can_launch(id: String) -> bool:
	return LaunchOps.can_launch(self, id)


func launch(id: String) -> bool:
	return LaunchOps.launch(self, id)


func tick(delta: float) -> void:
	LaunchOps.tick(self, delta)


func buy_manager(id: String) -> bool:
	return LaunchOps.buy_manager(self, id)


func manager_cost(id: String) -> float:
	return Economy.manager_cost(division_data[id])


func income_per_second() -> float:
	return LaunchOps.income_per_second(self)


func revenue_per_launch(id: String) -> float:
	return LaunchOps.revenue_per_launch(self, id)


func flight_time(id: String) -> float:
	return LaunchOps.flight_time(self, id)


## Add earned revenue. Every income source must use this, so run_revenue stays correct.
func add_revenue(amount: float) -> void:
	revenue += amount
	run_revenue += amount
	_emit_bus("revenue_changed", [revenue])


## Offline earnings. Logic lives in game/core/offline_ops.gd.
func offline_cap_seconds() -> float:
	return 4 * 3600.0

func compute_pending_offline(now_unix: float) -> void:
	OfflineOps.compute_pending(self, now_unix)

func claim_offline(multiplier: float) -> float:
	return OfflineOps.claim(self, multiplier)

func can_prestige() -> bool:
	return PrestigeOps.can_prestige(self)

func prestige(bonus_mult: float) -> void:
	PrestigeOps.prestige(self, bonus_mult)

## Pump taps needed for one launch. Research may lower this later.
func _pump_taps(id: String) -> int:
	return Research.pump_taps(int(division_data[id]["pump_taps"]), owned_research)


## Research multiplier for a division.
func _research_mult(id: String) -> float:
	return Research.revenue_mult(owned_research, id)


## Multiplier for all revenue from owned global research.
func _global_mult() -> float:
	return Research.global_mult(owned_research)


## Multiplier for flight time from owned faster-flight research.
func _flight_mult() -> float:
	return Research.flight_mult(owned_research)


func _apply_state(id: String, next: Dictionary) -> void:
	divisions[id].merge(next, true)


func _emit_unlock_if_crossed(id: String, old_level: int, new_level: int) -> void:
	if old_level >= Economy.LEVEL_UNLOCK or new_level < Economy.LEVEL_UNLOCK:
		return
	var next_index: int = division_order.find(id) + 1
	if next_index < division_order.size():
		_emit_bus("stage_unlocked", [division_order[next_index]])


## Emit a signal on the EventBus autoload with the given arguments.
## Does nothing when this node is not in the scene tree (for example in tests).
func _emit_bus(signal_name: String, args: Array) -> void:
	if not is_inside_tree():
		return
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.callv("emit_signal", [signal_name] + args)


func _new_division_state() -> Dictionary:
	return {
		"level": 0,
		"has_manager": false,
		"fuel_taps": 0,
		"cycle_elapsed": 0.0,
		"flying": false,
	}


func _load_division_data() -> void:
	division_data = {}
	division_order = []
	for division: Dictionary in DataLoader.divisions():
		var id: String = division["id"]
		division_data[id] = division
		division_order.append(id)
