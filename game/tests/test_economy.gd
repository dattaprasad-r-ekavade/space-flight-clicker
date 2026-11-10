extends RefCounted
## Tests for game/core/economy.gd (formulas from game_doc.md section 4).


static func _div(id: String, h_start: float, h_ceiling: float, base_cost: float, growth: float, base_rev: float, base_flight_s: float) -> Dictionary:
	return {
		"id": id,
		"h_start": h_start,
		"h_ceiling": h_ceiling,
		"base_cost": base_cost,
		"growth": growth,
		"base_rev": base_rev,
		"base_flight_s": base_flight_s,
	}


static func _rockets() -> Dictionary:
	return _div("model_rockets", 100.0, 1e4, 100.0, 1.14, 40.0, 3.0)


static func _bottles() -> Dictionary:
	return _div("bottles", 1.0, 100.0, 5.0, 1.08, 1.0, 1.5)


static func _loop_cost(div: Dictionary, level: int, count: int) -> float:
	var total: float = 0.0
	for k: int in range(count):
		total += Economy.level_cost(div, level + k)
	return total


func test_apogee_level_one_is_h_start() -> void:
	var div: Dictionary = _rockets()
	TestRunner.assert_near(Economy.apogee(div, 1), 100.0, 1e-9, "level 1 is h_start")


func test_apogee_level_25_is_ceiling() -> void:
	var div: Dictionary = _rockets()
	TestRunner.assert_near(Economy.apogee(div, 25), 1e4, 1e-9, "level 25 is h_ceiling")


func test_apogee_level_60_is_ceiling() -> void:
	var div: Dictionary = _rockets()
	TestRunner.assert_near(Economy.apogee(div, 60), 1e4, 1e-9, "level 60 is h_ceiling")


func test_bottles_level_zero_is_free() -> void:
	TestRunner.assert_near(Economy.level_cost(_bottles(), 0), 0.0, 1e-9, "bottles 0 -> 1 is free")


func test_bottles_level_one_has_price() -> void:
	TestRunner.assert_near(Economy.level_cost(_bottles(), 1), 5.0 * 1.08, 1e-9, "bottles 1 -> 2 costs base*growth")


func test_bulk_cost_ten_equals_loop_sum() -> void:
	var div: Dictionary = _rockets()
	TestRunner.assert_near(Economy.bulk_cost(div, 0, 10), _loop_cost(div, 0, 10), 1e-9, "bulk 10 from level 0")
	TestRunner.assert_near(Economy.bulk_cost(div, 7, 10), _loop_cost(div, 7, 10), 1e-9, "bulk 10 from level 7")


func test_bulk_cost_bottles_equals_loop_sum() -> void:
	var div: Dictionary = _bottles()
	TestRunner.assert_near(Economy.bulk_cost(div, 0, 10), _loop_cost(div, 0, 10), 1e-9, "bottles bulk 10 from 0 skips free level")
	TestRunner.assert_near(Economy.bulk_cost(div, 0, 1), 0.0, 1e-9, "bottles bulk 1 from 0 is free")


func test_bulk_cost_zero_count_is_zero() -> void:
	TestRunner.assert_near(Economy.bulk_cost(_rockets(), 3, 0), 0.0, 1e-9, "count 0 costs nothing")


func test_max_affordable_matches_bulk_cost() -> void:
	var div: Dictionary = _rockets()
	var budgets: Array[float] = [0.0, 50.0, 99.99, 100.0, 12345.6, 1e9]
	for budget: float in budgets:
		var m: int = Economy.max_affordable(div, 4, budget)
		TestRunner.assert_true(Economy.bulk_cost(div, 4, m) <= budget, "max_affordable fits budget %s" % str(budget))
		TestRunner.assert_true(Economy.bulk_cost(div, 4, m + 1) > budget, "max_affordable is maximal for %s" % str(budget))


func test_max_affordable_exact_at_boundary() -> void:
	var div: Dictionary = _rockets()
	var exact: float = Economy.bulk_cost(div, 2, 7)
	TestRunner.assert_eq(Economy.max_affordable(div, 2, exact), 7, "budget equal to bulk 7 buys 7")
	TestRunner.assert_eq(Economy.max_affordable(div, 2, exact * 0.999999), 6, "just under bulk 7 buys 6")


func test_max_affordable_bottles_free_level() -> void:
	var div: Dictionary = _bottles()
	TestRunner.assert_eq(Economy.max_affordable(div, 0, 0.0), 1, "free level buys with no revenue")
	var exact: float = Economy.bulk_cost(div, 0, 5)
	TestRunner.assert_eq(Economy.max_affordable(div, 0, exact), 5, "bottles budget equal to bulk 5 buys 5")


func test_level_mult_thresholds() -> void:
	TestRunner.assert_near(Economy.level_mult(9), 1.0, 1e-9, "level 9 mult 1")
	TestRunner.assert_near(Economy.level_mult(10), 2.0, 1e-9, "level 10 mult 2")
	TestRunner.assert_near(Economy.level_mult(25), 4.0, 1e-9, "level 25 mult 4")


func test_flight_time_halves_at_thresholds() -> void:
	var div: Dictionary = _rockets()
	TestRunner.assert_near(Economy.flight_time(div, 0, 1.0), 3.0, 1e-9, "level 0 base flight")
	TestRunner.assert_near(Economy.flight_time(div, 25, 1.0), 1.5, 1e-9, "level 25 halves once")
	TestRunner.assert_near(Economy.flight_time(div, 100, 2.0), 3.0 * 0.25 * 2.0, 1e-9, "level 100 halves twice, flight mult applied")


func test_launch_revenue_formula() -> void:
	var div: Dictionary = _rockets()
	TestRunner.assert_near(Economy.launch_revenue(div, 10, 1.5, 1.2), 1440.0, 1e-9, "40 * 10 * 2 * 1.5 * 1.2")


func test_manager_cost_formula() -> void:
	TestRunner.assert_near(Economy.manager_cost(_rockets()), 100.0 * 200.0, 1e-9, "manager cost is base_cost * 200")
