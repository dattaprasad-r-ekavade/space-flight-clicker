extends RefCounted


func test_translations() -> void:
	var english_rows: Array[PackedStringArray] = _read_csv("res://locale/strings.csv")
	for locale: String in ["es", "pt_BR", "fr", "de", "id", "tr", "ru"]:
		var translated_rows: Array[PackedStringArray] = _read_csv("res://locale/strings_%s.csv" % locale)
		TestRunner.assert_eq(translated_rows.size(), english_rows.size(), "%s row count matches English" % locale)
		if translated_rows.size() != english_rows.size():
			continue
		for index: int in range(1, english_rows.size()):
			var key: String = english_rows[index][0]
			var translated_key: String = translated_rows[index][0]
			var translation: String = translated_rows[index][1]
			TestRunner.assert_eq(translated_key, key, "%s key %d matches English" % [locale, index])
			TestRunner.assert_true(not translation.strip_edges().is_empty(), "%s translation %d is not empty" % [locale, index])
			TestRunner.assert_eq(translation.count("%"), key.count("%"), "%s percent count matches at row %d" % [locale, index])


func _read_csv(path: String) -> Array[PackedStringArray]:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		TestRunner.assert_true(false, "Could not open translation CSV: %s" % path)
		return []
	var rows: Array[PackedStringArray] = []
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() > 1:
			rows.append(row)
	file.close()
	return rows
