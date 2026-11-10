extends RefCounted
## Sanity checks for the test runner itself.


func test_sanity_true() -> void:
	TestRunner.assert_true(true, "true is true")


func test_sanity_eq() -> void:
	TestRunner.assert_eq(2 + 2, 4, "2 + 2 == 4")


func test_sanity_near() -> void:
	TestRunner.assert_near(1.0001, 1.0, 0.001, "within 0.1 percent")
