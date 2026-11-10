extends RefCounted
## Tests for the prestige formula and state reset.


func _new_state() -> Node:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	return gs


func test_echoes_for_uses_run_revenue_and_bonus_multiplier() -> void:
	var prestige_script: GDScript = load("res://core/prestige.gd") as GDScript
	TestRunner.assert_eq(prestige_script.echoes_for(0.0, 1.0), 0, "zero revenue gives no echoes")
	TestRunner.assert_eq(prestige_script.echoes_for(1.0e12, 1.0), 10, "one trillion gives ten echoes")
	TestRunner.assert_eq(prestige_script.echoes_for(2.0e12, 1.0), 14, "fractional echo result is floored")
	TestRunner.assert_eq(prestige_script.echoes_for(1.0e12, 1.5), 15, "bonus multiplier scales echoes")
	TestRunner.assert_eq(prestige_script.echoes_for(-1.0, 1.0), 0, "negative revenue gives no echoes")


func test_prestige_requires_division_nine_level_25() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	var order: Array = gs.get("division_order")
	var final_id: String = str(order.back())
	TestRunner.assert_true(not gs.call("can_prestige"), "prestige unavailable at level 0")
	divisions[final_id]["level"] = 24
	TestRunner.assert_true(not gs.call("can_prestige"), "prestige unavailable at level 24")
	divisions[final_id]["level"] = 25
	TestRunner.assert_true(gs.call("can_prestige"), "prestige available at level 25")
	gs.free()


func test_prestige_resets_run_progress_and_keeps_permanent_progress() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	var order: Array = gs.get("division_order")
	var final_id: String = str(order.back())
	for id: String in order:
		divisions[id]["level"] = 3
		divisions[id]["has_manager"] = true
		divisions[id]["fuel_taps"] = 2
		divisions[id]["cycle_elapsed"] = 1.5
		divisions[id]["flying"] = true
	divisions[final_id]["level"] = 25
	gs.set("revenue", 250.0)
	gs.set("run_revenue", 2.0e12)
	gs.set("record_height", 1000.0)
	gs.set("lifetime_height", 9000.0)
	gs.set("echoes", 7)
	gs.set("life", 4)
	gs.set("company_name", "Permanent Company")
	gs.set("selected_division", final_id)
	gs.set("owned_research", {"bigger_bottles": true})
	gs.set("pending_offline", {"seconds_counted": 300.0, "revenue": 12.0})
	var settings: Dictionary = {"music": false, "sfx": true, "haptics": false}
	gs.set("settings", settings.duplicate(true))
	gs.call("prestige", 1.0)

	TestRunner.assert_eq(float(gs.get("revenue")), 0.0, "revenue resets")
	TestRunner.assert_eq(float(gs.get("run_revenue")), 0.0, "run revenue resets")
	TestRunner.assert_eq(float(gs.get("record_height")), 0.0, "record height resets")
	TestRunner.assert_eq((gs.get("owned_research") as Dictionary).size(), 0, "research resets")
	TestRunner.assert_eq((gs.get("pending_offline") as Dictionary).size(), 0, "pending earnings reset")
	TestRunner.assert_eq(str(gs.get("selected_division")), str(order[0]), "selected division resets")
	var reset_divisions: Dictionary = gs.get("divisions")
	for id: String in order:
		var state: Dictionary = reset_divisions[id]
		TestRunner.assert_eq(int(state["level"]), 0, "division level resets: " + id)
		TestRunner.assert_true(not bool(state["has_manager"]), "manager resets: " + id)
		TestRunner.assert_eq(int(state["fuel_taps"]), 0, "pump taps reset: " + id)
		TestRunner.assert_eq(float(state["cycle_elapsed"]), 0.0, "flight timer resets: " + id)
		TestRunner.assert_true(not bool(state["flying"]), "active flight resets: " + id)
	TestRunner.assert_eq(int(gs.get("echoes")), 21, "echoes are retained and gained")
	TestRunner.assert_eq(float(gs.get("lifetime_height")), 9000.0, "lifetime height stays")
	TestRunner.assert_eq(int(gs.get("life")), 5, "life count increments")
	TestRunner.assert_eq(str(gs.get("company_name")), "Permanent Company", "company name stays")
	TestRunner.assert_eq(gs.get("settings"), settings, "settings stay")
	gs.free()


func test_prestige_at_level_24_changes_nothing() -> void:
	var gs: Node = _new_state()
	var divisions: Dictionary = gs.get("divisions")
	var final_id: String = str((gs.get("division_order") as Array).back())
	divisions[final_id]["level"] = 24
	gs.set("revenue", 10.0)
	gs.set("run_revenue", 1.0e12)
	gs.set("echoes", 3)
	gs.call("prestige", 1.0)
	TestRunner.assert_eq(float(gs.get("revenue")), 10.0, "revenue remains below requirement")
	TestRunner.assert_eq(int(gs.get("echoes")), 3, "echoes remain below requirement")
	TestRunner.assert_eq(int(gs.get("life")), 1, "life count remains below requirement")
	gs.free()
