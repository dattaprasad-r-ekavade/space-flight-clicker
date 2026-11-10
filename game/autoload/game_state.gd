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
	for id: String in division_order:
		divisions[id] = _new_division_state()


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


## Add one pump tap to a division's fuel bar. While a managed flight runs, a tap speeds it up instead.
## Returns false when no tap was added.
func pump(id: String) -> bool:
	if not divisions.has(id):
		return false
	if bool(divisions[id]["has_manager"]) and bool(divisions[id]["flying"]):
		return _speed_up(id)
	var taps: int = _pump_taps(id)
	if not LaunchCycle.can_pump(divisions[id], taps):
		return false
	_apply_state(id, LaunchCycle.pump(divisions[id], taps))
	_emit_bus("division_changed", [id])
	return true


## Buy the manager of a division. Returns false and changes nothing when the division
## is at level 0, already managed, or revenue is too low.
func buy_manager(id: String) -> bool:
	if not divisions.has(id):
		return false
	var cost: float = Economy.manager_cost(division_data[id])
	if not LaunchCycle.can_buy_manager(divisions[id], cost, revenue):
		return false
	revenue -= cost
	_apply_state(id, LaunchCycle.buy_manager(divisions[id], _pump_taps(id)))
	_emit_bus("revenue_changed", [revenue])
	_emit_bus("division_changed", [id])
	return true


## Revenue per second summed over all managed divisions at their current levels.
func income_per_second() -> float:
	var total: float = 0.0
	for id: String in division_order:
		var state: Dictionary = divisions[id]
		var level: int = int(state["level"])
		var div: Dictionary = division_data[id]
		var per_launch: float = Economy.launch_revenue(div, level, _research_mult(id), _global_mult())
		var flight: float = Economy.flight_time(div, level, _flight_mult())
		total += LaunchCycle.income_rate(level, bool(state["has_manager"]), per_launch, flight)
	return total


## Cut the remaining time of a managed flight. Returns false when no flight is running.
func _speed_up(id: String) -> bool:
	if not bool(divisions[id]["flying"]):
		return false
	var flight: float = Economy.flight_time(division_data[id], int(divisions[id]["level"]), _flight_mult())
	_apply_state(id, LaunchCycle.speed_up(divisions[id], flight))
	_emit_bus("division_changed", [id])
	return true


## True when the fuel bar of a division is full and no flight is running.
func can_launch(id: String) -> bool:
	if not divisions.has(id):
		return false
	return LaunchCycle.can_launch(divisions[id], _pump_taps(id))


## Start a flight for a division. Returns false when the bar is not full.
func launch(id: String) -> bool:
	if not can_launch(id):
		return false
	_apply_state(id, LaunchCycle.launch(divisions[id], _pump_taps(id)))
	_emit_bus("launch_started", [id])
	return true


## Advance all flights by `delta` seconds. Pays for every flight that finishes.
func tick(delta: float) -> void:
	for id: String in division_order:
		if not bool(divisions[id]["flying"]):
			continue
		var level: int = int(divisions[id]["level"])
		var flight: float = Economy.flight_time(division_data[id], level, _flight_mult())
		var result: Dictionary = LaunchCycle.advance(divisions[id], delta, flight, _pump_taps(id))
		_apply_state(id, result["state"])
		var finished: int = int(result["finished"])
		if finished > 0:
			_pay_flights(id, finished)


## Pay for `count` finished flights of a division at its current level.
func _pay_flights(id: String, count: int) -> void:
	var div: Dictionary = division_data[id]
	var level: int = int(divisions[id]["level"])
	var per_flight: float = Economy.launch_revenue(div, level, _research_mult(id), _global_mult())
	var apogee: float = Economy.apogee(div, level)
	var earned: float = per_flight * float(count)
	revenue += earned
	run_revenue += earned
	lifetime_height += apogee * float(count)
	for i: int in range(count):
		_emit_bus("launch_finished", [id, per_flight, apogee])
	if apogee > record_height:
		record_height = apogee
		_emit_bus("record_height_changed", [record_height])
	_emit_bus("revenue_changed", [revenue])


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
