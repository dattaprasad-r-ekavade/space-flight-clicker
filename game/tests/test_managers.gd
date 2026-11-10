extends RefCounted
## Tests for managers, the tap speed-up, and the income rate.
## Pure rules live in launch_cycle.gd. GameState methods are tested through an instance.


func _new_state() -> Node:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	return gs


func _pump_full(gs: Node, id: String) -> void:
	var division_data: Dictionary = gs.get("division_data")
	var taps: int = int(division_data[id]["pump_taps"])
	for i: int in range(taps):
		gs.call("pump", id)


func test_buy_manager_fails_at_level_zero() -> void:
	var gs: Node = _new_state()
	gs.set("revenue", 1.0e12)
	TestRunner.assert_true(not gs.call("buy_manager", "bottles"), "no manager at level 0")
	gs.free()


func test_buy_manager_fails_when_revenue_too_low() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	divisions["bottles"]["level"] = 1
	gs.set("revenue", 0.0)
	TestRunner.assert_true(not gs.call("buy_manager", "bottles"), "no manager without revenue")
	TestRunner.assert_true(not bool(divisions["bottles"]["has_manager"]), "still unmanaged")
	gs.free()


func test_buy_manager_pays_cost_once() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	var division_data: Dictionary = gs.get("division_data")
	var cost: float = Economy.manager_cost(division_data["bottles"])
	divisions["bottles"]["level"] = 1
	gs.set("revenue", cost + 5.0)
	TestRunner.assert_true(gs.call("buy_manager", "bottles"), "manager bought")
	TestRunner.assert_near(float(gs.get("revenue")), 5.0, 0.000001, "manager cost paid")
	TestRunner.assert_true(bool(divisions["bottles"]["has_manager"]), "division is managed")
	TestRunner.assert_true(not gs.call("buy_manager", "bottles"), "second manager refused")
	TestRunner.assert_near(float(gs.get("revenue")), 5.0, 0.000001, "no second charge")
	gs.free()


func test_managed_division_completes_n_cycles() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	divisions["bottles"]["level"] = 1
	divisions["bottles"]["has_manager"] = true
	var division_data: Dictionary = gs.get("division_data")
	var flight: float = Economy.flight_time(division_data["bottles"], 1, 1.0)
	var per: float = Economy.launch_revenue(division_data["bottles"], 1, 1.0, 1.0)
	_pump_full(gs, "bottles")
	gs.call("launch", "bottles")
	for i: int in range(4):
		gs.call("tick", flight)
		TestRunner.assert_near(float(gs.get("revenue")), per * float(i + 1), 0.000001, "managed cycle %d paid" % (i + 1))
	TestRunner.assert_true(bool(divisions["bottles"]["flying"]), "managed division keeps flying")
	gs.free()


func test_one_big_tick_pays_ten_launches() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	divisions["bottles"]["level"] = 1
	divisions["bottles"]["has_manager"] = true
	var division_data: Dictionary = gs.get("division_data")
	var flight: float = Economy.flight_time(division_data["bottles"], 1, 1.0)
	var per: float = Economy.launch_revenue(division_data["bottles"], 1, 1.0, 1.0)
	_pump_full(gs, "bottles")
	gs.call("launch", "bottles")
	gs.call("tick", flight * 10.5)
	TestRunner.assert_near(float(gs.get("revenue")), per * 10.0, 0.000001, "one tick pays ten launches")
	gs.free()


func test_unmanaged_division_earns_nothing_from_ticks() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	divisions["bottles"]["level"] = 1
	var division_data: Dictionary = gs.get("division_data")
	var flight: float = Economy.flight_time(division_data["bottles"], 1, 1.0)
	_pump_full(gs, "bottles")
	gs.call("tick", flight * 10.0)
	TestRunner.assert_near(float(gs.get("revenue")), 0.0, 0.000001, "idle unmanaged division earns nothing")
	gs.free()


func test_pump_on_managed_division_speeds_up_flight() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	divisions["bottles"]["level"] = 1
	divisions["bottles"]["has_manager"] = true
	var division_data: Dictionary = gs.get("division_data")
	var flight: float = Economy.flight_time(division_data["bottles"], 1, 1.0)
	_pump_full(gs, "bottles")
	gs.call("launch", "bottles")
	gs.call("tick", flight * 0.5)
	TestRunner.assert_true(gs.call("pump", "bottles"), "speed-up tap accepted")
	# Remaining was 0.5 * flight. The tap removes 2 %, so elapsed = flight - 0.98 * 0.5 * flight.
	TestRunner.assert_near(float(divisions["bottles"]["cycle_elapsed"]), flight * 0.51, 0.000001, "2 % of remaining removed")
	gs.free()


func test_income_per_second_matches_hand_calculation() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	var division_data: Dictionary = gs.get("division_data")
	TestRunner.assert_near(float(gs.call("income_per_second")), 0.0, 0.000001, "no income without managers")
	divisions["bottles"]["level"] = 1
	divisions["bottles"]["has_manager"] = true
	var base_rev: float = float(division_data["bottles"]["base_rev"])
	var base_flight: float = float(division_data["bottles"]["base_flight_s"])
	# Level 1: revenue per launch = base_rev * 1 * level_mult(1) = base_rev * 1.
	var hand: float = base_rev * 1.0 / base_flight
	TestRunner.assert_near(float(gs.call("income_per_second")), hand, 0.000001, "income matches hand calculation")
	gs.free()


func test_income_rate_pure_rules() -> void:
	TestRunner.assert_near(LaunchCycle.income_rate(1, true, 10.0, 4.0), 2.5, 0.000001, "rate is revenue over flight")
	TestRunner.assert_near(LaunchCycle.income_rate(1, false, 10.0, 4.0), 0.0, 0.000001, "unmanaged rate is zero")
	TestRunner.assert_near(LaunchCycle.income_rate(0, true, 10.0, 4.0), 0.0, 0.000001, "level 0 rate is zero")
