extends RefCounted
## Tests for save and load: round trip, backup fallback, missing keys.
## Each test writes files under user://test/ and removes them at the end.

const TEST_DIR: String = "user://test"


func _new_state() -> Node:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	return gs


func _new_service(file_name: String) -> Node:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var script: GDScript = load("res://autoload/save_service.gd") as GDScript
	var svc: Node = script.new() as Node
	svc.set("save_path", TEST_DIR + "/" + file_name)
	return svc


func _remove_files(svc: Node) -> void:
	var path: String = str(svc.get("save_path"))
	for suffix: String in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)


func test_round_trip_keeps_all_fields() -> void:
	var gs: Node = _new_state()
	gs.set("revenue", 12345.5)
	gs.set("run_revenue", 200.25)
	gs.set("record_height", 1500.0)
	gs.set("lifetime_height", 9999.0)
	gs.set("echoes", 3)
	gs.set("life", 2)
	gs.set("company_name", "Test Co")
	gs.set("selected_division", "bottles")
	gs.set("owned_research", {"some_node": true})
	var divisions: Dictionary = gs.get("divisions")
	var bottles: Dictionary = divisions["bottles"]
	bottles["level"] = 12
	bottles["has_manager"] = true
	bottles["fuel_taps"] = 2
	bottles["cycle_elapsed"] = 1.5
	bottles["flying"] = true

	var svc: Node = _new_service("round_trip.json")
	TestRunner.assert_true(svc.call("save_state", gs.call("to_dict")), "save succeeds")
	var loaded: Dictionary = svc.call("load_state")

	var gs2: Node = _new_state()
	gs2.call("from_dict", loaded)
	TestRunner.assert_near(float(gs2.get("revenue")), 12345.5, 0.000001, "revenue kept")
	TestRunner.assert_near(float(gs2.get("run_revenue")), 200.25, 0.000001, "run revenue kept")
	TestRunner.assert_near(float(gs2.get("record_height")), 1500.0, 0.000001, "record height kept")
	TestRunner.assert_near(float(gs2.get("lifetime_height")), 9999.0, 0.000001, "lifetime height kept")
	TestRunner.assert_eq(int(gs2.get("echoes")), 3, "echoes kept")
	TestRunner.assert_eq(int(gs2.get("life")), 2, "life kept")
	TestRunner.assert_eq(str(gs2.get("company_name")), "Test Co", "company name kept")
	TestRunner.assert_eq(str(gs2.get("selected_division")), "bottles", "selection kept")
	var research: Dictionary = gs2.get("owned_research")
	TestRunner.assert_true(research.has("some_node"), "research kept")
	var divisions2: Dictionary = gs2.get("divisions")
	var state: Dictionary = divisions2["bottles"]
	TestRunner.assert_eq(int(state["level"]), 12, "division level kept as int")
	TestRunner.assert_eq(bool(state["has_manager"]), true, "manager flag kept")
	TestRunner.assert_eq(int(state["fuel_taps"]), 2, "fuel taps kept")
	TestRunner.assert_near(float(state["cycle_elapsed"]), 1.5, 0.000001, "cycle time kept")
	TestRunner.assert_eq(bool(state["flying"]), true, "flying flag kept")

	_remove_files(svc)
	svc.free()
	gs.free()
	gs2.free()


func test_load_with_no_file_returns_empty() -> void:
	var svc: Node = _new_service("none.json")
	_remove_files(svc)
	var loaded: Dictionary = svc.call("load_state")
	TestRunner.assert_true(loaded.is_empty(), "no file gives empty dictionary")
	svc.free()


func test_corrupt_main_file_loads_backup() -> void:
	var gs: Node = _new_state()
	var svc: Node = _new_service("corrupt.json")
	_remove_files(svc)
	gs.set("revenue", 100.0)
	svc.call("save_state", gs.call("to_dict"))
	gs.set("revenue", 200.0)
	svc.call("save_state", gs.call("to_dict"))

	var main_path: String = str(svc.get("save_path"))
	var file: FileAccess = FileAccess.open(main_path, FileAccess.WRITE)
	file.store_string("{not valid json")
	file.close()

	var loaded: Dictionary = svc.call("load_state")
	var gs2: Node = _new_state()
	gs2.call("from_dict", loaded)
	TestRunner.assert_near(float(gs2.get("revenue")), 100.0, 0.000001, "backup holds previous save")

	_remove_files(svc)
	svc.free()
	gs.free()
	gs2.free()


func test_missing_keys_load_with_defaults() -> void:
	var gs: Node = _new_state()
	gs.set("revenue", 500.0)
	gs.set("life", 4)
	var data: Dictionary = gs.call("to_dict")
	data.erase("revenue")
	data.erase("life")
	data["unknown_key"] = 42
	var divisions: Dictionary = data["divisions"]
	divisions["not_a_division"] = {"level": 99}
	var bottles: Dictionary = divisions["bottles"]
	bottles.erase("fuel_taps")

	var svc: Node = _new_service("missing.json")
	_remove_files(svc)
	svc.call("save_state", data)
	var loaded: Dictionary = svc.call("load_state")

	var gs2: Node = _new_state()
	gs2.set("revenue", 777.0)
	gs2.call("from_dict", loaded)
	TestRunner.assert_near(float(gs2.get("revenue")), 0.0, 0.000001, "missing revenue is default")
	TestRunner.assert_eq(int(gs2.get("life")), 1, "missing life is default")
	var divisions2: Dictionary = gs2.get("divisions")
	TestRunner.assert_true(not divisions2.has("not_a_division"), "unknown division dropped")
	var state: Dictionary = divisions2["bottles"]
	TestRunner.assert_eq(int(state["fuel_taps"]), 0, "missing division key is default")

	_remove_files(svc)
	svc.free()
	gs.free()
	gs2.free()
