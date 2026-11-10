extends RefCounted
## Tests for the shared UI theme.


func test_build_returns_theme() -> void:
	var theme: Theme = UiTheme.build()
	TestRunner.assert_true(theme != null, "build() returns a Theme")


func test_button_normal_stylebox_exists() -> void:
	var theme: Theme = UiTheme.build()
	TestRunner.assert_true(theme.has_stylebox("normal", "Button"), "Button has a normal stylebox")
	var box: StyleBox = theme.get_stylebox("normal", "Button")
	TestRunner.assert_true(box is StyleBoxFlat, "Button normal is a StyleBoxFlat")
