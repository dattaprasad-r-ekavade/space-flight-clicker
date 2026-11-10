extends RefCounted
## Tests for rewarded boost state and its save behaviour.


func _new_state() -> Node:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	return gs


func test_boost_stacks_to_four_hours() -> void:
	var gs: Node = _new_state()
	TestRunner.assert_near(float(gs.call("grant_boost_2x")), 1800.0, 0.000001, "boost adds 30 minutes")
	for i: int in range(10):
		gs.call("grant_boost_2x")
	TestRunner.assert_near(float(gs.get("boost_2x_remaining")), 14400.0, 0.000001, "boost caps at four hours")
	gs.free()


func test_boost_time_advances_only_during_game_ticks() -> void:
	var gs: Node = _new_state()
	gs.call("grant_boost_2x")
	var saved: Dictionary = gs.call("to_dict")
	gs.call("from_dict", saved)
	TestRunner.assert_near(float(gs.get("boost_2x_remaining")), 1800.0, 0.000001, "saved remaining time is unchanged while closed")
	gs.call("tick", 60.0)
	TestRunner.assert_near(float(gs.get("boost_2x_remaining")), 1740.0, 0.000001, "active game tick drains boost time")
	gs.free()


func test_boost_doubles_global_revenue_multiplier() -> void:
	var gs: Node = _new_state()
	var base_mult: float = float(gs.call("_global_mult"))
	gs.call("grant_boost_2x")
	TestRunner.assert_near(float(gs.call("_global_mult")), base_mult * 2.0, 0.000001, "boost flows into global multiplier")
	gs.free()


func test_time_warp_pays_income_and_enforces_cooldown() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	var bottle_state: Dictionary = divisions["bottles"]
	bottle_state["level"] = 1
	bottle_state["has_manager"] = true
	var expected: float = float(gs.call("income_per_second")) * 1200.0
	TestRunner.assert_true(expected > 0.0, "managed division has income")
	TestRunner.assert_true(bool(gs.call("use_time_warp", 1000.0)), "time warp succeeds when ready")
	TestRunner.assert_near(float(gs.get("revenue")), expected, 0.000001, "time warp pays 20 minutes of income")
	TestRunner.assert_true(not bool(gs.call("can_time_warp", 1899.0)), "time warp is unavailable during cooldown")
	TestRunner.assert_true(bool(gs.call("can_time_warp", 1900.0)), "time warp is ready after cooldown")
	gs.free()
