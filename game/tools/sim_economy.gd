extends SceneTree
## Economy simulator. Headless. Run with:
##   GODOT --headless --path game -s res://tools/sim_economy.gd -- casual
## Drives a real GameState node and the real Economy, LaunchCycle and Research code.
## Prints stage unlocks, manager purchases, the black hole, and a summary.
## Profiles live in res://tools/sim_profiles.json.

const PROFILES_PATH: String = "res://tools/sim_profiles.json"
const MAX_DAYS: int = 30
const SECONDS_PER_DAY: int = 86400
const WAKING_SECONDS: int = 16 * 3600
const MAX_JUMP_SECONDS: int = 30
const RESEARCH_FRACTION: float = 0.2
const BLACK_HOLE_ID: String = "black_hole"
const MAX_BUYS_PER_STEP: int = 1000
const ECHO_REVENUE_UNIT: float = 1e12
const ECHO_FACTOR: float = 10.0

var gs = null
var t: int = 0
var flights: int = 0
var done: bool = false
var seen_unlock: Dictionary = {}
var seen_manager: Dictionary = {}
## Smoothed revenue per second, used by the buy policy to decide when to save for a manager.
var rate: float = 0.0
const SAVE_SECONDS: float = 120.0


func _init() -> void:
	var code: int = _run()
	quit(code)


## Run one profile. Returns the process exit code.
@warning_ignore("integer_division")
func _run() -> int:
	var profile_name: String = "casual"
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		profile_name = args[0]
	var profiles: Variant = DataLoader.load_json(PROFILES_PATH)
	if not (profiles is Dictionary) or not profiles.has(profile_name):
		print("ERROR unknown profile: %s" % profile_name)
		return 1
	var p: Dictionary = profiles[profile_name]
	var taps: int = int(p["taps_per_second"])
	var session_len: int = int(p["session_minutes"]) * 60
	var per_day: int = int(p["sessions_per_day"])
	var mult: float = float(p.get("revenue_mult", 1.0))
	var slot: int = WAKING_SECONDS / per_day
	var first_len: int = int(p.get("first_session_minutes", p["session_minutes"])) * 60

	gs = load("res://autoload/game_state.gd").new()
	gs.new_game()
	print("SIM profile=%s taps/s=%d session_min=%d sessions/day=%d revenue_mult=%.1f" % [
		profile_name, taps, session_len / 60, per_day, mult])
	_buy_policy()
	_check_events()
	for day: int in range(MAX_DAYS):
		for k: int in range(per_day):
			var start: int = day * SECONDS_PER_DAY + k * slot
			if start > t:
				_offline(start - t, mult)
				t = start
				_buy_policy()
				_check_events()
			if done:
				break
			_session(start + (first_len if (day == 0 and k == 0) else session_len), taps, mult)
			if done:
				break
		if done:
			break
	_print_summary(profile_name, mult)
	gs.free()
	return 0


## Play one session from the current time until `end`. Taps the newest unlocked
## division that has no manager. Steps 1 s, or up to 30 s when nothing can be tapped or bought.
func _session(end: int, taps: int, mult: float) -> void:
	var idle: bool = false
	while t < end and not done:
		var target: String = _tap_target()
		var step: int = 1
		if target.is_empty():
			if idle and _all_unlocked_managed():
				step = mini(MAX_JUMP_SECONDS, end - t)
		else:
			for i: int in range(taps):
				if gs.can_launch(target):
					gs.launch(target)
				else:
					gs.pump(target)
		_advance(step, mult)
		idle = not _buy_policy()
		_check_events()


## Advance the game by `step` seconds. Counts finished flights and applies the revenue multiplier.
func _advance(step: int, mult: float) -> void:
	var rev_before: float = gs.run_revenue
	for id: String in gs.division_order:
		var state: Dictionary = gs.divisions[id]
		if bool(state["flying"]):
			var needed: int = Research.pump_taps(int(gs.division_data[id]["pump_taps"]), gs.owned_research)
			var result: Dictionary = LaunchCycle.advance(state, float(step), gs.flight_time(id), needed)
			flights += int(result["finished"])
	gs.tick(float(step))
	var gained: float = gs.run_revenue - rev_before
	rate = 0.9 * rate + 0.1 * (gained * mult / float(step))
	if mult != 1.0:
		gs.add_revenue(gained * (mult - 1.0))
	t += step


## Offline earnings for a gap in seconds. Uses the same rule as the game: capped at 4 h.
func _offline(gap: int, mult: float) -> void:
	var secs: float = minf(float(gap), float(gs.offline_cap_seconds()))
	var amount: float = gs.income_per_second() * secs
	gs.add_revenue(amount)
	if mult != 1.0:
		gs.add_revenue(amount * (mult - 1.0))


## Buy things until nothing is affordable. Returns true when anything was bought.
func _buy_policy() -> bool:
	var any_bought: bool = false
	var guard: int = 0
	while _buy_once() and guard < MAX_BUYS_PER_STEP:
		any_bought = true
		guard += 1
	return any_bought


## One purchase by the buy policy. Returns false when nothing was bought.
func _buy_once() -> bool:
	var order: Array[String] = gs.division_order
	# 1. Manager for any division with level >= 1.
	for id: String in order:
		var state: Dictionary = gs.divisions[id]
		if int(state["level"]) >= 1 and not bool(state["has_manager"]) and gs.buy_manager(id):
			return true
	# 1b. Save for a manager that about two minutes of income can pay for.
	for id: String in order:
		var st: Dictionary = gs.divisions[id]
		if int(st["level"]) >= 1 and not bool(st["has_manager"]) and gs.manager_cost(id) <= maxf(rate, gs.income_per_second()) * SAVE_SECONDS:
			return false
	# 2. Level 1 of a newly unlocked division.
	for id: String in order:
		if gs.is_unlocked(id) and int(gs.divisions[id]["level"]) == 0 and gs.buy_levels(id, 1):
			return true
	# 3. Any research node costing less than 20 % of revenue.
	for node: Dictionary in Research.nodes():
		var rid: String = str(node["id"])
		if gs.owned_research.has(rid):
			continue
		if float(node["cost"]) < RESEARCH_FRACTION * gs.revenue and gs.buy_research(rid):
			return true
	# 4. Levels of the newest unlocked division, up to LEVEL_UNLOCK.
	var newest: String = _newest_unlocked()
	var level: int = int(gs.divisions[newest]["level"])
	if level < Economy.LEVEL_UNLOCK:
		var n: int = mini(
			Economy.max_affordable(gs.division_data[newest], level, gs.revenue),
			Economy.LEVEL_UNLOCK - level)
		if n > 0 and gs.buy_levels(newest, n):
			return true
	# 5. One level of the unlocked division with the lowest level cost.
	var best: String = ""
	var best_cost: float = INF
	for id: String in order:
		if not gs.is_unlocked(id):
			continue
		var cost: float = Economy.level_cost(gs.division_data[id], int(gs.divisions[id]["level"]))
		if cost < best_cost:
			best_cost = cost
			best = id
	if not best.is_empty() and best_cost <= gs.revenue and gs.buy_levels(best, 1):
		return true
	return false


## The newest unlocked division with level 1 or more and no manager. Empty when there is none.
## A level 0 division cannot be pumped, so the player taps the division below it.
func _tap_target() -> String:
	var order: Array[String] = gs.division_order
	for i: int in range(order.size() - 1, -1, -1):
		var id: String = order[i]
		var state: Dictionary = gs.divisions[id]
		if gs.is_unlocked(id) and int(state["level"]) >= 1 and not bool(state["has_manager"]):
			return id
	return ""


## True when every unlocked division has a manager.
func _all_unlocked_managed() -> bool:
	for id: String in gs.division_order:
		if gs.is_unlocked(id) and not bool(gs.divisions[id]["has_manager"]):
			return false
	return true


## The newest unlocked division. Always at least the first division.
func _newest_unlocked() -> String:
	var order: Array[String] = gs.division_order
	var best: String = order[0]
	for id: String in order:
		if gs.is_unlocked(id):
			best = id
	return best


## Print one line for each new unlock, manager, or black hole level 25. Stops the run at black hole.
func _check_events() -> void:
	var order: Array[String] = gs.division_order
	for i: int in range(order.size()):
		var id: String = order[i]
		if i > 0 and not seen_unlock.has(id) and gs.is_unlocked(id):
			seen_unlock[id] = true
			print("%s  UNLOCK %s" % [_stamp(), id])
		if bool(gs.divisions[id]["has_manager"]) and not seen_manager.has(id):
			seen_manager[id] = true
			print("%s  MANAGER %s" % [_stamp(), id])
	if not done and int(gs.divisions[BLACK_HOLE_ID]["level"]) >= Economy.LEVEL_UNLOCK:
		done = true
		print("%s  BLACK_HOLE" % _stamp())


func _print_summary(profile_name: String, mult: float) -> void:
	var reason: String = "30 days reached"
	if done:
		reason = "black hole level %d" % Economy.LEVEL_UNLOCK
	var echoes: int = int(floor(ECHO_FACTOR * sqrt(gs.run_revenue / ECHO_REVENUE_UNIT)))
	print("SUMMARY profile=%s stop=%s (%s)" % [profile_name, _stamp(), reason])
	print("  launches (completed flights): %d" % flights)
	print("  run_revenue: %s" % NumFormat.money(gs.run_revenue))
	print("  echoes that would be gained: %d" % echoes)
	print("  revenue_mult applied: %.1f" % mult)


## Format the simulated time as DDd HHh MMm.
@warning_ignore("integer_division")
func _stamp() -> String:
	return "%02dd %02dh %02dm" % [t / SECONDS_PER_DAY, (t % SECONDS_PER_DAY) / 3600, (t % 3600) / 60]
