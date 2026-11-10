extends RefCounted
## Tests for GameState buying and unlocking.
## The autoload is not registered when tests compile, so each test makes its own instance.


func _new_state() -> Node:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	return gs


func test_buy_fails_without_revenue() -> void:
	var gs: Node = _new_state()
	gs.set("revenue", 0.0)
	var ok: bool = gs.call("buy_levels", "model_rockets", 1)
	TestRunner.assert_true(not ok, "buy fails with no revenue")
	var divisions: Dictionary = gs.get("divisions")
	TestRunner.assert_eq(int(divisions["model_rockets"]["level"]), 0, "level unchanged")
	gs.free()


func test_buy_ten_costs_bulk_cost() -> void:
	var gs: Node = _new_state()
	gs.set("revenue", 1000000.0)
	var division_data: Dictionary = gs.get("division_data")
	var div: Dictionary = division_data["bottles"]
	var expected: float = Economy.bulk_cost(div, 0, 10)
	var before: float = gs.get("revenue")
	var ok: bool = gs.call("buy_levels", "bottles", 10)
	TestRunner.assert_true(ok, "buy 10 succeeds")
	var after: float = gs.get("revenue")
	TestRunner.assert_near(before - after, expected, 0.000001, "cost equals bulk_cost")
	var divisions: Dictionary = gs.get("divisions")
	TestRunner.assert_eq(int(divisions["bottles"]["level"]), 10, "level is 10")
	gs.free()


func test_division_two_unlocks_at_level_25() -> void:
	var gs: Node = _new_state()
	TestRunner.assert_true(not gs.call("is_unlocked", "model_rockets"), "division 2 locked at start")
	var divisions: Dictionary = gs.get("divisions")
	divisions["bottles"]["level"] = 24
	gs.set("revenue", 1000000.0)
	TestRunner.assert_true(not gs.call("is_unlocked", "model_rockets"), "still locked at level 24")
	var ok: bool = gs.call("buy_levels", "bottles", 1)
	TestRunner.assert_true(ok, "buy level 25 succeeds")
	TestRunner.assert_true(gs.call("is_unlocked", "model_rockets"), "division 2 unlocked at level 25")
	gs.free()


func test_locked_division_cannot_be_bought() -> void:
	var gs: Node = _new_state()
	gs.set("revenue", 1000000000.0)
	var ok: bool = gs.call("buy_levels", "sounding", 1)
	TestRunner.assert_true(not ok, "locked division buy fails")
	var divisions: Dictionary = gs.get("divisions")
	TestRunner.assert_eq(int(divisions["sounding"]["level"]), 0, "locked level unchanged")
	TestRunner.assert_true(not gs.call("select_division", "sounding"), "locked division cannot be selected")
	gs.free()
