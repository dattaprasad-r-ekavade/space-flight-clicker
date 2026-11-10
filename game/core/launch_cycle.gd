class_name LaunchCycle
extends RefCounted
## Pure launch-cycle rules from game_doc.md sections 2 and 5.
## A division state is one Dictionary: {level, has_manager, fuel_taps, cycle_elapsed, flying}.
## Every function returns a new Dictionary and does not change its input.
## A division at level 0 cannot pump or launch.


## True when one more pump tap is allowed.
static func can_pump(state: Dictionary, pump_taps: int) -> bool:
	return int(state["level"]) >= 1 and not bool(state["flying"]) and int(state["fuel_taps"]) < pump_taps


## Add one pump tap to the fuel bar. Does nothing when the bar is full or the division cannot pump.
static func pump(state: Dictionary, pump_taps: int) -> Dictionary:
	var next: Dictionary = state.duplicate()
	if can_pump(state, pump_taps):
		next["fuel_taps"] = int(state["fuel_taps"]) + 1
	return next


## True when the fuel bar is full and no flight is running.
static func can_launch(state: Dictionary, pump_taps: int) -> bool:
	return int(state["level"]) >= 1 and not bool(state["flying"]) and int(state["fuel_taps"]) >= pump_taps


## Start a flight. Does nothing when the bar is not full.
static func launch(state: Dictionary, pump_taps: int) -> Dictionary:
	var next: Dictionary = state.duplicate()
	if can_launch(state, pump_taps):
		next["flying"] = true
		next["cycle_elapsed"] = 0.0
	return next


## Advance the flight by `delta` seconds.
## Each finished flight clears the fuel. A managed division refuels and flies again at once.
## Returns {"state": Dictionary, "finished": int} where "finished" counts the paid flights.
static func advance(state: Dictionary, delta: float, flight_time: float, pump_taps: int) -> Dictionary:
	var next: Dictionary = state.duplicate()
	var finished: int = 0
	if not bool(state["flying"]) or delta <= 0.0 or flight_time <= 0.0:
		return {"state": next, "finished": finished}
	var elapsed: float = float(state["cycle_elapsed"]) + delta
	var flying: bool = true
	while flying and elapsed >= flight_time:
		elapsed -= flight_time
		finished += 1
		if bool(state["has_manager"]):
			next["fuel_taps"] = pump_taps
		else:
			flying = false
	if not flying:
		next["fuel_taps"] = 0
		elapsed = 0.0
	next["flying"] = flying
	next["cycle_elapsed"] = elapsed
	return {"state": next, "finished": finished}


## Share of the remaining cycle time that one tap removes on a managed division.
const TAP_CUT: float = 0.02


## True when a manager can be bought: level 1 or more, not yet managed, and revenue covers the cost.
static func can_buy_manager(state: Dictionary, cost: float, revenue: float) -> bool:
	return int(state["level"]) >= 1 and not bool(state["has_manager"]) and cost <= revenue


## Give a division a manager. A running flight keeps its time. An idle division starts a flight at once.
static func buy_manager(state: Dictionary, pump_taps: int) -> Dictionary:
	var next: Dictionary = state.duplicate()
	next["has_manager"] = true
	if not bool(state["flying"]):
		next["flying"] = true
		next["cycle_elapsed"] = 0.0
		next["fuel_taps"] = pump_taps
	return next


## Remove TAP_CUT of the remaining cycle time. Only a managed, flying division changes.
static func speed_up(state: Dictionary, flight_time: float) -> Dictionary:
	var next: Dictionary = state.duplicate()
	if bool(state["has_manager"]) and bool(state["flying"]) and flight_time > 0.0:
		var remaining: float = flight_time - float(state["cycle_elapsed"])
		next["cycle_elapsed"] = flight_time - remaining * (1.0 - TAP_CUT)
	return next


## Revenue per second of one division. Zero unless it is at level 1 or more and managed.
static func income_rate(level: int, has_manager: bool, revenue_per_launch: float, flight_time: float) -> float:
	if level < 1 or not has_manager or flight_time <= 0.0:
		return 0.0
	return revenue_per_launch / flight_time
