extends Node
## Holds all mutable game state. UI reads this and calls its methods.
## Formulas live in game/core/economy.gd.

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


func _ready() -> void:
	_load_division_data()
	new_game()


## Reset the life state to a new game.
func new_game() -> void:
	if division_order.is_empty():
		_load_division_data()
	revenue = 0.0
	life = 1
	company_name = tr("Bottle Rocket Co.")
	selected_division = FIRST_DIVISION_ID
	divisions = {}
	for id: String in division_order:
		divisions[id] = _new_division_state()


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
	_emit_bus("division_changed", id)
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
	_emit_bus("revenue_changed", revenue)
	_emit_bus("division_changed", id)
	_emit_unlock_if_crossed(id, level, level + count)
	return true


func _emit_unlock_if_crossed(id: String, old_level: int, new_level: int) -> void:
	if old_level >= Economy.LEVEL_UNLOCK or new_level < Economy.LEVEL_UNLOCK:
		return
	var next_index: int = division_order.find(id) + 1
	if next_index < division_order.size():
		_emit_bus("stage_unlocked", division_order[next_index])


## Emit a one-argument signal on the EventBus autoload.
## Does nothing when this node is not in the scene tree (for example in tests).
func _emit_bus(signal_name: String, value: Variant) -> void:
	if not is_inside_tree():
		return
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.emit_signal(signal_name, value)


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
