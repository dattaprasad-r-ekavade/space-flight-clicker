extends RefCounted
## Tests for fresh GameState initialization.


func test_new_game_resets_saved_progress_fields() -> void:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	gs.set("boost_2x_remaining", 300.0)
	gs.set("daily_streak", 4)
	gs.set("total_launches", 12)
	gs.set("selected_bottle_skin", "bottle_skin_1")
	gs.new_game()
	TestRunner.assert_eq(float(gs.get("boost_2x_remaining")), 0.0, "fresh game clears active boost")
	TestRunner.assert_eq(int(gs.get("daily_streak")), 0, "fresh game clears daily streak")
	TestRunner.assert_eq(int(gs.get("total_launches")), 0, "fresh game clears launch count")
	TestRunner.assert_eq(str(gs.get("selected_bottle_skin")), "", "fresh game clears selected skin")
	gs.free()
