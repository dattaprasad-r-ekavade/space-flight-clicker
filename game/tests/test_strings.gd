extends RefCounted
## Checks that the string table built by tools/extract_strings.py is present.


func _read_csv() -> String:
	var f: FileAccess = FileAccess.open("res://locale/strings.csv", FileAccess.READ)
	if f == null:
		return ""
	var text: String = f.get_as_text()
	f.close()
	return text


func test_strings_csv_has_rows() -> void:
	var text: String = _read_csv()
	TestRunner.assert_true(text != "", "strings.csv can be read")
	var lines: PackedStringArray = text.split("\n", false)
	TestRunner.assert_true(lines.size() > 100, "strings.csv has more than 100 lines")
	TestRunner.assert_eq(lines[0].strip_edges(), "keys,en", "strings.csv header")


func test_strings_csv_known_texts() -> void:
	var text: String = _read_csv()
	TestRunner.assert_true(text.contains("\nLaunch,Launch\n"), "strings.csv has Launch")
	TestRunner.assert_true(text.contains("\nDivisions,Divisions\n"), "strings.csv has Divisions")
	TestRunner.assert_true(text.contains("\nKid on the Hill,Kid on the Hill\n"), "strings.csv has Kid on the Hill")
