extends RefCounted
## Tests the first four Echo Shop effects at no ownership and maximum level.


func _new_state() -> Node:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	return gs


func test_head_start_at_level_zero_and_maximum() -> void:
	var gs: Node = _new_state()
	TestRunner.assert_eq(float(gs.call("head_start_revenue")), 0.0, "no item starts with no bonus Revenue")
	gs.set("echo_levels", {"head_start": 5})
	TestRunner.assert_eq(float(gs.call("head_start_revenue")), 1.0e13, "maximum head start uses configured growth")
	var divisions: Dictionary = gs.get("divisions")
	var order: Array = gs.get("division_order")
	divisions[str(order.back())]["level"] = 25
	gs.call("prestige", 1.0)
	TestRunner.assert_eq(float(gs.get("revenue")), 1.0e13, "new life starts with head start Revenue")
	TestRunner.assert_eq(float(gs.get("run_revenue")), 0.0, "starting Revenue is not earned run Revenue")
	gs.free()


func test_old_friends_at_level_zero_and_maximum() -> void:
	var gs: Node = _new_state()
	var first_id: String = str((gs.get("division_order") as Array)[0])
	var ordinary_cost: float = float(gs.call("manager_cost", first_id))
	TestRunner.assert_true(ordinary_cost > 0.0, "manager has normal cost without Old Friends")
	gs.set("echo_levels", {"old_friends": 1})
	TestRunner.assert_eq(float(gs.call("manager_cost", first_id)), 0.0, "first three divisions have free managers")
	var fourth_id: String = str((gs.get("division_order") as Array)[3])
	TestRunner.assert_true(float(gs.call("manager_cost", fourth_id)) > 0.0, "fourth division manager still costs Revenue")
	gs.free()


func test_muscle_memory_at_level_zero_and_maximum() -> void:
	var gs: Node = _new_state()
	var id: String = str((gs.get("division_order") as Array)[0])
	var base_taps: int = int(gs.call("_pump_taps", id))
	TestRunner.assert_eq(int(gs.call("_pump_taps", id)), base_taps, "no item leaves pump taps unchanged")
	gs.set("echo_levels", {"muscle_memory": 3})
	var reduced_taps: int = int(gs.call("_pump_taps", id))
	TestRunner.assert_true(reduced_taps >= 2, "muscle memory keeps the minimum of two taps")
	TestRunner.assert_true(reduced_taps < base_taps, "maximum muscle memory lowers pump taps")
	gs.free()


func test_long_nap_at_level_zero_and_maximum() -> void:
	var gs: Node = _new_state()
	TestRunner.assert_eq(float(gs.call("offline_cap_seconds")), 14400.0, "base offline cap is four hours")
	gs.set("echo_levels", {"long_nap": 4})
	TestRunner.assert_eq(float(gs.call("offline_cap_seconds")), 43200.0, "maximum Long Nap adds eight hours")
	gs.free()
