extends RefCounted
## Tests the final four Echo Shop effects at no ownership and maximum level.


func _new_state() -> Node:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	return gs


func test_deep_echo_at_level_zero_and_maximum() -> void:
	var gs: Node = _new_state()
	gs.set("echoes", 10)
	TestRunner.assert_eq(float(gs.call("echo_power")), 0.02, "base Echo power is two percent per Echo")
	TestRunner.assert_eq(float(gs.call("_global_mult")), 1.2, "unspent Echoes multiply all revenue")
	gs.set("echo_levels", {"deep_echo": 4})
	TestRunner.assert_eq(float(gs.call("echo_power")), 0.04, "maximum Deep Echo adds two percent per Echo")
	TestRunner.assert_eq(float(gs.call("_global_mult")), 1.4, "Deep Echo power flows into global revenue")
	gs.free()


func test_fast_hands_at_level_zero_and_maximum() -> void:
	var gs: Node = _new_state()
	TestRunner.assert_eq(float(gs.call("_flight_mult")), 1.0, "no item leaves flight time unchanged")
	gs.set("echo_levels", {"fast_hands": 5})
	TestRunner.assert_near(float(gs.call("_flight_mult")), 0.59049, 0.000001, "maximum Fast Hands reduces flight time")
	gs.free()


func test_lucky_bottle_at_level_zero_and_maximum() -> void:
	var gs: Node = _new_state()
	TestRunner.assert_true(not gs.call("lucky_launch_pays_ten", 0.0), "no Lucky Bottle level cannot trigger")
	gs.set("echo_levels", {"lucky_bottle": 3})
	TestRunner.assert_true(gs.call("lucky_launch_pays_ten", 0.05), "roll within maximum chance triggers")
	TestRunner.assert_true(not gs.call("lucky_launch_pays_ten", 0.1), "roll above maximum chance does not trigger")
	gs.free()


func test_memory_bottles_at_level_zero_and_maximum() -> void:
	var gs: Node = _new_state()
	var no_skins: Array[String] = gs.call("unlocked_skin_ids")
	TestRunner.assert_eq(no_skins.size(), 0, "no item unlocks no skins")
	gs.set("echo_levels", {"memory_bottles": 6})
	var all_skins: Array[String] = gs.call("unlocked_skin_ids")
	TestRunner.assert_eq(all_skins.size(), 6, "each Memory Bottles level unlocks one skin")
	TestRunner.assert_eq(all_skins[0], "memory_bottle_1", "skin ids are stable")
	gs.free()
