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
