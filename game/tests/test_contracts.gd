extends RefCounted
## Tests for deterministic daily contract selection and progress.

const DAY_SECONDS: float = 86400.0


func _templates() -> Array:
	return DataLoader.load_json("res://data/contracts.json")


func test_selection_is_deterministic_for_the_date() -> void:
	var first: Array[Dictionary] = Contracts.select(_templates(), 20670, 3)
	var second: Array[Dictionary] = Contracts.select(_templates(), 20670, 3)
	TestRunner.assert_eq(first, second, "same date selects the same contracts")
	TestRunner.assert_eq(first.size(), 3, "three contracts are selected")


func test_targets_scale_with_highest_stage() -> void:
	var templates: Array = _templates()
	var early: Array[Dictionary] = Contracts.select(templates, 20671, 1)
	var late: Array[Dictionary] = Contracts.select(templates, 20671, 5)
	for i: int in range(early.size()):
		var template: Dictionary = {}
		for raw: Variant in templates:
			if str((raw as Dictionary)["id"]) == str(early[i]["id"]):
				template = raw
		TestRunner.assert_eq(int(late[i]["target"]) - int(early[i]["target"]), int(template["stage_scale"]) * 4, "stage scaling follows template data")


func test_local_date_key_uses_utc_offset() -> void:
	var timestamp: float = 10.0 * DAY_SECONDS + 21.0 * 3600.0
	TestRunner.assert_eq(Contracts.date_key(timestamp, 0), 10, "UTC date key")
	TestRunner.assert_eq(Contracts.date_key(timestamp, 3 * 3600), 11, "local offset advances date key")


func test_event_progress_completes_a_contract_once() -> void:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	var date: int = Contracts.date_key(10.0 * DAY_SECONDS + 100.0, 0)
	var active: Array[Dictionary] = [
		{"id":"launch","date_key":date,"type":"launch","title":"Launch","target":1,"progress":0,"complete":false},
		{"id":"levels","date_key":date,"type":"levels","title":"Levels","target":5,"progress":0,"complete":false},
		{"id":"manager","date_key":date,"type":"manager","title":"Manager","target":1,"progress":0,"complete":false},
	]
	gs.set("daily_contracts", active)
	ContractsOps.on_launch_started(gs, 10.0 * DAY_SECONDS + 200.0, 0)
	var progress: Array[Dictionary] = gs.get("daily_contracts")
	TestRunner.assert_true(bool(progress[0]["complete"]), "launch event completes contract")
	ContractsOps.on_launch_started(gs, 10.0 * DAY_SECONDS + 300.0, 0)
	TestRunner.assert_eq(int(progress[0]["progress"]), 1, "completed contract does not gain progress again")
	gs.free()
