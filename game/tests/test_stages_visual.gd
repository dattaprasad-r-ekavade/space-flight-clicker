extends RefCounted
## Checks that stages_visual.json has all nine stages and the five keys per stage.

const PATH: String = "res://data/stages_visual.json"
const STAGE_IDS: Array[String] = [
	"bottles", "model_rockets", "sounding", "orbital", "station",
	"moon", "solar", "galaxy", "black_hole",
]
const KEYS: Array[String] = ["sky_top", "sky_bottom", "star_amount", "trail", "trail_color"]


func test_stages_visual_has_all_ids() -> void:
	var data: Variant = DataLoader.load_json(PATH)
	TestRunner.assert_true(data is Dictionary, "stages_visual.json is an object")
	if not (data is Dictionary):
		return
	for id: String in STAGE_IDS:
		TestRunner.assert_true(data.has(id), "stages_visual has %s" % id)


func test_stages_visual_entries_have_keys() -> void:
	var data: Variant = DataLoader.load_json(PATH)
	if not (data is Dictionary):
		TestRunner.assert_true(false, "stages_visual.json is an object")
		return
	for id: String in STAGE_IDS:
		var entry: Variant = data.get(id, {})
		TestRunner.assert_true(entry is Dictionary, "%s is an object" % id)
		if not (entry is Dictionary):
			continue
		for key: String in KEYS:
			TestRunner.assert_true(entry.has(key), "%s has %s" % [id, key])
