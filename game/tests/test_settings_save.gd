extends RefCounted
## Tests that the settings survive to_dict / from_dict and new_game().


func _new_state() -> Node:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	return gs


func test_settings_survive_to_dict_and_from_dict() -> void:
	var gs: Node = _new_state()
	gs.call("set_setting", "music", false)
	gs.call("set_setting", "haptics", false)
	var data: Dictionary = gs.call("to_dict")

	var gs2: Node = _new_state()
	gs2.call("from_dict", data)
	var settings: Dictionary = gs2.get("settings")
	TestRunner.assert_eq(bool(settings["music"]), false, "music off kept")
	TestRunner.assert_eq(bool(settings["sfx"]), true, "sfx on kept")
	TestRunner.assert_eq(bool(settings["haptics"]), false, "haptics off kept")

	gs.free()
	gs2.free()


func test_settings_survive_new_game() -> void:
	var gs: Node = _new_state()
	gs.call("set_setting", "sfx", false)
	gs.call("new_game")
	var settings: Dictionary = gs.get("settings")
	TestRunner.assert_eq(bool(settings["sfx"]), false, "sfx off kept after new game")
	gs.free()
