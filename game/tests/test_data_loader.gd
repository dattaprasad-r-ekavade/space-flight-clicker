extends RefCounted
## Tests for DataLoader and game/data/divisions.json.


func test_divisions_count() -> void:
	TestRunner.assert_eq(DataLoader.divisions().size(), 9, "nine divisions")


func test_division_ids_unique() -> void:
	var seen: Dictionary = {}
	var unique: bool = true
	for division: Dictionary in DataLoader.divisions():
		if seen.has(division["id"]):
			unique = false
		seen[division["id"]] = true
	TestRunner.assert_true(unique, "division ids are unique")


func test_ceiling_equals_next_start() -> void:
	var divs: Array[Dictionary] = DataLoader.divisions()
	for i: int in range(divs.size() - 1):
		TestRunner.assert_eq(divs[i]["h_ceiling"], divs[i + 1]["h_start"], "ceiling of %s" % divs[i]["id"])


func test_first_division_values() -> void:
	var first: Dictionary = DataLoader.divisions()[0]
	TestRunner.assert_eq(first["id"], "bottles", "first id")
	TestRunner.assert_eq(first["h_start"], 1.0, "first h_start")
	TestRunner.assert_eq(first["base_cost"], 5.0, "first base_cost")


func test_pump_taps_is_int() -> void:
	for division: Dictionary in DataLoader.divisions():
		TestRunner.assert_eq(typeof(division["pump_taps"]), TYPE_INT, "pump_taps int for %s" % division["id"])


func test_load_json_reads_divisions_file() -> void:
	var raw: Variant = DataLoader.load_json(DataLoader.DIVISIONS_PATH)
	TestRunner.assert_true(raw is Array, "divisions.json parses to an Array")
	TestRunner.assert_eq((raw as Array).size(), 9, "divisions.json has nine entries")
