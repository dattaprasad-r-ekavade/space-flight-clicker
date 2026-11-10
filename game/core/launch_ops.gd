class_name LaunchOps
extends RefCounted
## Launch-cycle operations on the GameState node (`gs`).
## GameState keeps one-line methods that call these. Pure rules stay in LaunchCycle and Economy.
## Pattern for every feature that needs state: static functions here take `gs` first.


## Add one pump tap. While a managed flight runs, a tap speeds it up instead.
static func pump(gs, id: String) -> bool:
	if not gs.divisions.has(id):
		return false
	var state: Dictionary = gs.divisions[id]
	if bool(state["has_manager"]) and bool(state["flying"]):
		return speed_up(gs, id)
	var taps: int = gs._pump_taps(id)
	if not LaunchCycle.can_pump(state, taps):
		return false
	gs._apply_state(id, LaunchCycle.pump(state, taps))
	gs._emit_bus("division_changed", [id])
	return true


## Cut the remaining time of a managed flight. Returns false when no flight is running.
static func speed_up(gs, id: String) -> bool:
	var state: Dictionary = gs.divisions[id]
	if not bool(state["flying"]):
		return false
	var flight: float = Economy.flight_time(gs.division_data[id], int(state["level"]), gs._flight_mult())
	gs._apply_state(id, LaunchCycle.speed_up(state, flight))
	gs._emit_bus("division_changed", [id])
	return true


static func can_launch(gs, id: String) -> bool:
	if not gs.divisions.has(id):
		return false
	return LaunchCycle.can_launch(gs.divisions[id], gs._pump_taps(id))


static func launch(gs, id: String) -> bool:
	if not can_launch(gs, id):
		return false
	gs._apply_state(id, LaunchCycle.launch(gs.divisions[id], gs._pump_taps(id)))
	gs._emit_bus("launch_started", [id])
	return true


## Buy the manager of a division. Fails at level 0, when already managed, or when revenue is too low.
static func buy_manager(gs, id: String) -> bool:
	if not gs.divisions.has(id):
		return false
	var cost: float = gs.manager_cost(id)
	if not LaunchCycle.can_buy_manager(gs.divisions[id], cost, gs.revenue):
		return false
	gs.revenue -= cost
	gs._apply_state(id, LaunchCycle.buy_manager(gs.divisions[id], gs._pump_taps(id)))
	gs._emit_bus("revenue_changed", [gs.revenue])
	gs._emit_bus("division_changed", [id])
	return true


## Revenue of one launch of a division at its current level, with all multipliers.
static func revenue_per_launch(gs, id: String) -> float:
	var level: int = int(gs.divisions[id]["level"])
	return Economy.launch_revenue(gs.division_data[id], level, gs._research_mult(id), gs._global_mult())


## Flight time of a division at its current level, with all multipliers.
static func flight_time(gs, id: String) -> float:
	return Economy.flight_time(gs.division_data[id], int(gs.divisions[id]["level"]), gs._flight_mult())


## Revenue per second summed over all managed divisions.
static func income_per_second(gs) -> float:
	var total: float = 0.0
	for id: String in gs.division_order:
		var state: Dictionary = gs.divisions[id]
		total += LaunchCycle.income_rate(
			int(state["level"]), bool(state["has_manager"]), revenue_per_launch(gs, id), flight_time(gs, id)
		)
	return total


## Advance all flights by `delta` seconds. Pays for every flight that finishes.
static func tick(gs, delta: float) -> void:
	for id: String in gs.division_order:
		if not bool(gs.divisions[id]["flying"]):
			continue
		var result: Dictionary = LaunchCycle.advance(gs.divisions[id], delta, flight_time(gs, id), gs._pump_taps(id))
		gs._apply_state(id, result["state"])
		var finished: int = int(result["finished"])
		if finished > 0:
			pay_flights(gs, id, finished)


## Pay for `count` finished flights of a division at its current level.
static func pay_flights(gs, id: String, count: int) -> void:
	var per_flight: float = revenue_per_launch(gs, id)
	var apogee: float = Economy.apogee(gs.division_data[id], int(gs.divisions[id]["level"]))
	gs.add_revenue(per_flight * float(count))
	gs.lifetime_height += apogee * float(count)
	for i: int in range(mini(count, 3)):
		gs._emit_bus("launch_finished", [id, per_flight, apogee])
	if apogee > gs.record_height:
		gs.record_height = apogee
		gs._emit_bus("record_height_changed", [gs.record_height])
