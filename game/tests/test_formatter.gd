extends RefCounted
## Boundary tests for NumFormat (game/core/formatter.gd).


func test_money_small() -> void:
	TestRunner.assert_eq(NumFormat.money(0.0), "0", "zero")
	TestRunner.assert_eq(NumFormat.money(1234.0), "1,234", "thousands separator")
	TestRunner.assert_eq(NumFormat.money(-1234.0), "-1,234", "negative")
	TestRunner.assert_eq(NumFormat.money(-0.4), "0", "no negative zero")


func test_money_boundaries() -> void:
	TestRunner.assert_eq(NumFormat.money(999999.0), "999,999", "just below 1e6")
	TestRunner.assert_eq(NumFormat.money(999999.6), "1.00M", "rounds up to 1e6")
	TestRunner.assert_eq(NumFormat.money(1e6), "1.00M", "1e6")
	TestRunner.assert_eq(NumFormat.money(12345678.0), "12.3M", "three significant digits")
	TestRunner.assert_eq(NumFormat.money(999999999.0), "1.00B", "rounds up to 1e9")
	TestRunner.assert_eq(NumFormat.money(1e9), "1.00B", "1e9")
	TestRunner.assert_eq(NumFormat.money(1e12), "1.00T", "1e12")
	TestRunner.assert_eq(NumFormat.money(1e15), "1.00aa", "1e15")
	TestRunner.assert_eq(NumFormat.money(1e18), "1.00ab", "1e18")
	TestRunner.assert_eq(NumFormat.money(1e300), "1.00dr", "1e300")


func test_money_special() -> void:
	TestRunner.assert_eq(NumFormat.money(NAN), "NaN", "NaN")
	TestRunner.assert_eq(NumFormat.money(INF), "∞", "infinity")
	TestRunner.assert_eq(NumFormat.money(-INF), "-∞", "negative infinity")


func test_height_small() -> void:
	TestRunner.assert_eq(NumFormat.height(0.0), "0 m", "zero")
	TestRunner.assert_eq(NumFormat.height(999.0), "999 m", "999 m")
	TestRunner.assert_eq(NumFormat.height(-999.0), "-999 m", "negative metres")


func test_height_km() -> void:
	TestRunner.assert_eq(NumFormat.height(1000.0), "1 km", "1000 m is km")
	TestRunner.assert_eq(NumFormat.height(384400000.0), "384,400 km", "Moon distance")
	TestRunner.assert_eq(NumFormat.height(9.9e9), "9.90M km", "just below 1e10 m")


func test_height_au() -> void:
	TestRunner.assert_eq(NumFormat.height(1e10), "0.07 AU", "1e10 m is AU")
	TestRunner.assert_eq(NumFormat.height(9.4e14), "%.2f AU" % (9.4e14 / 1.496e11), "just below AU limit")


func test_height_ly() -> void:
	TestRunner.assert_eq(NumFormat.height(9.46e14), "0.10 ly", "AU limit goes to ly")
	TestRunner.assert_eq(NumFormat.height(26000.0 * 9.461e15), "26,000 ly", "26,000 ly")
	TestRunner.assert_true(NumFormat.height(1e300).ends_with("dl ly"), "1e300 m uses suffix")


func test_height_special() -> void:
	TestRunner.assert_eq(NumFormat.height(NAN), "NaN", "NaN")
	TestRunner.assert_eq(NumFormat.height(INF), "∞", "infinity")
	TestRunner.assert_eq(NumFormat.height(-INF), "-∞", "negative infinity")


func test_duration() -> void:
	TestRunner.assert_eq(NumFormat.duration(0.0), "0s", "zero")
	TestRunner.assert_eq(NumFormat.duration(45.0), "45s", "seconds")
	TestRunner.assert_eq(NumFormat.duration(90.0), "1m 30s", "minutes")
	TestRunner.assert_eq(NumFormat.duration(7500.0), "2h 05m", "hours")
	TestRunner.assert_eq(NumFormat.duration(-45.0), "-45s", "negative")
	TestRunner.assert_eq(NumFormat.duration(NAN), "NaN", "NaN")
	TestRunner.assert_eq(NumFormat.duration(INF), "∞", "infinity")
