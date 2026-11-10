extends RefCounted
## Tests milestone data, permanent multipliers and GameState integration.


func _new_state() -> Node:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	return gs


func test_twelve_milestones_and_reach_status() -> void:
	var milestone_script: GDScript = load("res://core/milestones.gd") as GDScript
	var definitions: Array[Dictionary] = milestone_script.items()
	TestRunner.assert_eq(definitions.size(), 12, "twelve milestone definitions load")
	TestRunner.assert_eq(str(definitions[0]["name_key"]), "Higher than Everest", "first milestone has its name")
	TestRunner.assert_eq(str(definitions[1]["name_key"]), "Past the Moon", "second milestone has its name")
	TestRunner.assert_true(not milestone_script.is_reached(definitions[0], 999.0), "first milestone is unreached below its threshold")
	TestRunner.assert_true(milestone_script.is_reached(definitions[0], 1000.0), "first milestone is reached at its threshold")


func test_multiplier_grows_once_per_reached_milestone() -> void:
	var milestone_script: GDScript = load("res://core/milestones.gd") as GDScript
	TestRunner.assert_eq(float(milestone_script.mult(999.0)), 1.0, "no reached milestones gives multiplier one")
	TestRunner.assert_near(float(milestone_script.mult(1000.0)), 1.1, 0.000001, "one milestone gives one ten percent bonus")
	TestRunner.assert_near(float(milestone_script.mult(100000.0)), 1.21, 0.000001, "two milestones multiply together")
	TestRunner.assert_near(float(milestone_script.mult(1.0e25)), pow(1.1, 12.0), 0.000001, "all twelve milestone bonuses apply")


func test_milestone_bonus_flows_into_game_state_global_multiplier() -> void:
	var gs: Node = _new_state()
	gs.set("lifetime_height", 1000.0)
	TestRunner.assert_near(float(gs.call("_global_mult")), 1.1, 0.000001, "reached milestone multiplies all revenue")
	gs.set("echoes", 10)
	TestRunner.assert_near(float(gs.call("_global_mult")), 1.32, 0.000001, "milestone and Echo bonuses multiply together")
	gs.free()
