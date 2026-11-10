extends RefCounted
## Tests for offline earnings. Pure maths lives in offline.gd. GameState methods are tested through an instance.


func _new_state() -> Node:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	return gs


func test_compute_pays_rate_times_time() -> void:
	var r: Dictionary = Offline.compute(10.0, 100.0, 14400.0)
	TestRunner.assert_near(float(r["seconds_counted"]), 100.0, 0.000001, "counted seconds")
	TestRunner.assert_near(float(r["revenue"]), 1000.0, 0.000001, "revenue is rate times time")


func test_compute_caps_time_away() -> void:
	var r: Dictionary = Offline.compute(10.0, 100000.0, 14400.0)
	TestRunner.assert_near(float(r["seconds_counted"]), 14400.0, 0.000001, "counted seconds capped")
	TestRunner.assert_near(float(r["revenue"]), 144000.0, 0.000001, "revenue uses capped time")


func test_compute_negative_time_gives_zero() -> void:
	var r: Dictionary = Offline.compute(10.0, -500.0, 14400.0)
	TestRunner.assert_near(float(r["seconds_counted"]), 0.0, 0.000001, "negative time counts nothing")
	TestRunner.assert_near(float(r["revenue"]), 0.0, 0.000001, "negative time pays nothing")


func test_compute_below_sixty_seconds_gives_zero() -> void:
	var r: Dictionary = Offline.compute(10.0, 59.0, 14400.0)
	TestRunner.assert_near(float(r["revenue"]), 0.0, 0.000001, "59 s pays nothing")
	TestRunner.assert_near(float(r["seconds_counted"]), 0.0, 0.000001, "59 s counts nothing")


func test_compute_at_sixty_seconds_pays() -> void:
	var r: Dictionary = Offline.compute(10.0, 60.0, 14400.0)
	TestRunner.assert_near(float(r["revenue"]), 600.0, 0.000001, "60 s pays")


func test_new_game_has_no_pending_offline() -> void:
	var gs: Node = _new_state()
	TestRunner.assert_near(float(gs.get("last_seen_unix")), 0.0, 0.000001, "new game has no last seen time")
	TestRunner.assert_true((gs.get("pending_offline") as Dictionary).is_empty(), "no pending offline on new game")
	gs.free()


func test_cap_is_four_hours() -> void:
	var gs: Node = _new_state()
	TestRunner.assert_near(float(gs.call("offline_cap_seconds")), 14400.0, 0.000001, "base cap is 4 h")
	gs.free()


func test_compute_pending_uses_income_and_cap() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	divisions["bottles"]["level"] = 1
	divisions["bottles"]["has_manager"] = true
	var income: float = float(gs.call("income_per_second"))
	gs.set("last_seen_unix", 1000.0)
	gs.call("compute_pending_offline", 1000.0 + 100000.0)
	var pending: Dictionary = gs.get("pending_offline")
	TestRunner.assert_near(float(pending["seconds_counted"]), 14400.0, 0.000001, "pending time is capped")
	TestRunner.assert_near(float(pending["revenue"]), income * 14400.0, 0.000001, "pending revenue uses income")
	gs.free()


func test_compute_pending_zero_when_no_last_seen() -> void:
	var gs: Node = _new_state()
	gs.call("compute_pending_offline", 1.0e9)
	TestRunner.assert_true((gs.get("pending_offline") as Dictionary).is_empty(), "no last seen time means no pending")
	gs.free()


func test_compute_pending_zero_when_clock_went_back() -> void:
	var gs: Node = _new_state()
	gs.set("last_seen_unix", 5000.0)
	gs.call("compute_pending_offline", 4000.0)
	TestRunner.assert_true((gs.get("pending_offline") as Dictionary).is_empty(), "clock earlier than save pays nothing")
	gs.free()


func test_claim_pays_with_multiplier_and_clears() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	divisions["bottles"]["level"] = 1
	divisions["bottles"]["has_manager"] = true
	var income: float = float(gs.call("income_per_second"))
	gs.set("last_seen_unix", 1000.0)
	gs.call("compute_pending_offline", 1000.0 + 600.0)
	var paid: float = float(gs.call("claim_offline", 2.0))
	TestRunner.assert_near(paid, income * 600.0 * 2.0, 0.000001, "claim pays revenue times multiplier")
	TestRunner.assert_near(float(gs.get("revenue")), paid, 0.000001, "claim adds revenue")
	TestRunner.assert_true((gs.get("pending_offline") as Dictionary).is_empty(), "claim clears pending")
	TestRunner.assert_near(float(gs.call("claim_offline", 1.0)), 0.0, 0.000001, "second claim pays nothing")
	gs.free()
