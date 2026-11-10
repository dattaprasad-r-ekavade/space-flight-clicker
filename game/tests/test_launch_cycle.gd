extends RefCounted
## Tests for the launch cycle: pure rules in launch_cycle.gd and GameState pump, launch, tick.
## The autoload is not registered when tests compile, so each test makes its own instance.


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


func test_level_zero_cannot_pump_or_launch() -> void:
	var gs: Node = _new_state()
	TestRunner.assert_true(not gs.call("pump", "bottles"), "pump fails at level 0")
	TestRunner.assert_true(not gs.call("can_launch", "bottles"), "cannot launch at level 0")
	gs.free()


func test_launch_fails_before_bar_full() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	divisions["bottles"]["level"] = 1
	_pump_full(gs, "bottles")
	var division_data: Dictionary = gs.get("division_data")
	var taps: int = int(division_data["bottles"]["pump_taps"])
	var ok: bool = gs.call("launch", "bottles")
	TestRunner.assert_true(ok, "launch succeeds when bar is full")
	var short_gs: Node = _new_state()
	var short_divisions: Dictionary = short_gs.get("divisions")
	short_divisions["bottles"]["level"] = 1
	for i: int in range(taps - 1):
		short_gs.call("pump", "bottles")
	TestRunner.assert_true(not short_gs.call("launch", "bottles"), "launch fails one tap short")
	TestRunner.assert_eq(int(short_divisions["bottles"]["fuel_taps"]), taps - 1, "fuel kept at one short")
	short_gs.free()
	gs.free()


func test_launch_pays_after_flight_time_only() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	divisions["bottles"]["level"] = 1
	_pump_full(gs, "bottles")
	gs.call("launch", "bottles")
	var division_data: Dictionary = gs.get("division_data")
	var flight: float = Economy.flight_time(division_data["bottles"], 1, 1.0)
	gs.call("tick", flight * 0.5)
	TestRunner.assert_near(float(gs.get("revenue")), 0.0, 0.000001, "no pay before flight ends")
	gs.call("tick", flight * 0.6)
	var expected: float = Economy.launch_revenue(division_data["bottles"], 1, 1.0, 1.0)
	TestRunner.assert_near(float(gs.get("revenue")), expected, 0.000001, "pays after flight ends")
	TestRunner.assert_near(float(gs.get("run_revenue")), expected, 0.000001, "run revenue matches")
	TestRunner.assert_eq(float(divisions["bottles"]["fuel_taps"]), 0.0, "fuel cleared after flight")
	gs.free()


func test_lifetime_height_grows_by_apogee_per_launch() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	divisions["bottles"]["level"] = 1
	var division_data: Dictionary = gs.get("division_data")
	var apogee: float = Economy.apogee(division_data["bottles"], 1)
	var flight: float = Economy.flight_time(division_data["bottles"], 1, 1.0)
	_pump_full(gs, "bottles")
	gs.call("launch", "bottles")
	gs.call("tick", flight + 0.1)
	TestRunner.assert_near(float(gs.get("lifetime_height")), apogee, 0.000001, "lifetime after one launch")
	_pump_full(gs, "bottles")
	gs.call("launch", "bottles")
	gs.call("tick", flight + 0.1)
	TestRunner.assert_near(float(gs.get("lifetime_height")), apogee * 2.0, 0.000001, "lifetime after two launches")
	TestRunner.assert_near(float(gs.get("record_height")), apogee, 0.000001, "record height is the apogee")
	gs.free()


func test_large_tick_pays_every_managed_flight() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	divisions["bottles"]["level"] = 1
	divisions["bottles"]["has_manager"] = true
	_pump_full(gs, "bottles")
	gs.call("launch", "bottles")
	var division_data: Dictionary = gs.get("division_data")
	var flight: float = Economy.flight_time(division_data["bottles"], 1, 1.0)
	gs.call("tick", flight * 3.1)
	var per: float = Economy.launch_revenue(division_data["bottles"], 1, 1.0, 1.0)
	TestRunner.assert_near(float(gs.get("revenue")), per * 3.0, 0.000001, "three managed flights paid")
	TestRunner.assert_true(bool(divisions["bottles"]["flying"]), "managed division flies again")
	gs.free()


func test_new_game_resets_every_field() -> void:
	var gs: Node = _new_state()
	gs.set("revenue", 5.0)
	gs.set("run_revenue", 6.0)
	gs.set("record_height", 7.0)
	gs.set("lifetime_height", 8.0)
	gs.set("echoes", 9)
	gs.call("new_game")
	TestRunner.assert_near(float(gs.get("revenue")), 0.0, 0.000001, "revenue reset")
	TestRunner.assert_near(float(gs.get("run_revenue")), 0.0, 0.000001, "run revenue reset")
	TestRunner.assert_near(float(gs.get("record_height")), 0.0, 0.000001, "record height reset")
	TestRunner.assert_near(float(gs.get("lifetime_height")), 0.0, 0.000001, "lifetime height reset")
	TestRunner.assert_eq(int(gs.get("echoes")), 0, "echoes reset")
	gs.free()
