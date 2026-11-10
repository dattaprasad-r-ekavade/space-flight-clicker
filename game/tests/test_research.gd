extends RefCounted
## Tests for research data, research rules, and GameState research purchases.
## The autoload is not registered when tests compile, so each test makes its own instance.


func _new_state() -> Node:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	return gs


func test_file_has_29_nodes_with_unique_ids() -> void:
	var raw: Variant = DataLoader.load_json("res://data/research.json")
	TestRunner.assert_true(raw is Array, "research.json is an array")
	var nodes: Array = raw
	TestRunner.assert_eq(nodes.size(), 29, "29 research nodes")
	var seen: Dictionary = {}
	for node: Variant in nodes:
		seen[str(node["id"])] = true
	TestRunner.assert_eq(seen.size(), 29, "research ids are unique")


func test_division_node_multiplies_only_its_division() -> void:
	var owned: Dictionary = {"div_bottles_1": true}
	TestRunner.assert_near(Research.revenue_mult(owned, "bottles"), 3.0, 0.000001, "bottles x3")
	TestRunner.assert_near(Research.revenue_mult(owned, "model_rockets"), 1.0, 0.000001, "other division unchanged")


func test_global_node_multiplies_all_revenue() -> void:
	var owned: Dictionary = {"global_1": true}
	TestRunner.assert_near(Research.global_mult(owned), 2.0, 0.000001, "global x2")
	TestRunner.assert_near(Research.global_mult({}), 1.0, 0.000001, "no global research is neutral")


func test_flight_node_scales_flight_time() -> void:
	var owned: Dictionary = {"flight_1": true}
	TestRunner.assert_near(Research.flight_mult(owned), 0.85, 0.000001, "flight x0.85")


func test_pump_node_lowers_taps_with_minimum() -> void:
	var owned: Dictionary = {"pump_1": true}
	TestRunner.assert_eq(Research.pump_taps(10, owned), 8, "10 taps times 0.8 gives 8")
	var all_pump: Dictionary = {"pump_1": true, "pump_2": true, "pump_3": true}
	TestRunner.assert_eq(Research.pump_taps(3, all_pump), 2, "taps never fall below 2")


func test_buy_research_deducts_cost() -> void:
	var gs: Node = _new_state()
	gs.set("revenue", 1000000.0)
	var ok: bool = gs.call("buy_research", "div_bottles_1")
	TestRunner.assert_true(ok, "buy bottles research succeeds")
	TestRunner.assert_near(float(gs.get("revenue")), 997500.0, 0.000001, "cost 2500 deducted")
	var owned: Dictionary = gs.get("owned_research")
	TestRunner.assert_true(owned.has("div_bottles_1"), "node recorded as owned")
	gs.free()


func test_buy_research_fails_when_locked_or_poor() -> void:
	var gs: Node = _new_state()
	gs.set("revenue", 1000000000000.0)
	TestRunner.assert_true(not gs.call("buy_research", "div_sounding_1"), "locked stage fails")
	gs.set("revenue", 1.0)
	TestRunner.assert_true(not gs.call("buy_research", "div_bottles_1"), "too expensive fails")
	TestRunner.assert_true(not gs.call("buy_research", "no_such_node"), "unknown id fails")
	gs.free()


func test_buy_research_twice_fails() -> void:
	var gs: Node = _new_state()
	gs.set("revenue", 1000000.0)
	TestRunner.assert_true(gs.call("buy_research", "pump_1"), "first buy succeeds")
	TestRunner.assert_true(not gs.call("buy_research", "pump_1"), "second buy fails")
	gs.free()


func test_new_game_resets_research() -> void:
	var gs: Node = _new_state()
	gs.set("revenue", 1000000.0)
	gs.call("buy_research", "pump_1")
	gs.call("new_game")
	var owned: Dictionary = gs.get("owned_research")
	TestRunner.assert_eq(owned.size(), 0, "new game clears research")
	gs.free()
