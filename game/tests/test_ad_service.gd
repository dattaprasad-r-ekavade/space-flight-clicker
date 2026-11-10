extends RefCounted
## Tests for the ad interface, the mock provider, and the interstitial rules.


func _make_service(clock_holder: Array) -> Node:
	var svc = load("res://autoload/ad_service.gd").new()
	svc.persist = false
	svc.clock = func() -> float: return clock_holder[0]
	svc.install_unix = 1000.0
	svc.set_provider(_make_mock(false))
	return svc


func _make_mock(no_fill: bool) -> MockAdProvider:
	var mock: MockAdProvider = MockAdProvider.new()
	mock.delay_s = 0.0
	mock.no_fill = no_fill
	return mock


func test_unknown_placement_returns_false() -> void:
	var svc = _make_service([5000.0])
	var got: Array = []
	svc.show_rewarded("not_a_placement", func(granted: bool) -> void: got.append(granted))
	TestRunner.assert_eq(got.size(), 1, "callback called once")
	TestRunner.assert_eq(got[0], false, "unknown placement grants nothing")
	svc.free()


func test_mock_grant_returns_true() -> void:
	var svc = _make_service([5000.0])
	var got: Array = []
	svc.show_rewarded("offline_double", func(granted: bool) -> void: got.append(granted))
	TestRunner.assert_eq(got.size(), 1, "callback called once")
	TestRunner.assert_eq(got[0], true, "mock grants a valid placement")
	svc.free()


func test_no_fill_returns_false() -> void:
	var clock: Array = [5000.0]
	var svc = _make_service(clock)
	svc.set_provider(_make_mock(true))
	TestRunner.assert_eq(svc.is_rewarded_ready(), false, "no fill is not ready")
	var got: Array = []
	svc.show_rewarded("boost_2x", func(granted: bool) -> void: got.append(granted))
	TestRunner.assert_eq(got[0], false, "no fill grants nothing")
	TestRunner.assert_eq(svc.maybe_show_interstitial("test"), false, "no fill blocks interstitial")
	svc.free()


func test_rules_install_grace() -> void:
	TestRunner.assert_eq(AdRules.can_show_interstitial(1599.0, 1000.0, 0.0, false), false, "599 s after install is blocked")
	TestRunner.assert_eq(AdRules.can_show_interstitial(1600.0, 1000.0, 0.0, false), true, "600 s after install is allowed")


func test_rules_min_gap() -> void:
	TestRunner.assert_eq(AdRules.can_show_interstitial(5899.0, 1000.0, 5000.0, false), false, "899 s after last is blocked")
	TestRunner.assert_eq(AdRules.can_show_interstitial(5900.0, 1000.0, 5000.0, false), true, "900 s after last is allowed")


func test_rules_remove_ads() -> void:
	TestRunner.assert_eq(AdRules.can_show_interstitial(9000.0, 1000.0, 0.0, true), false, "remove_ads blocks always")


func test_interstitial_with_fake_clock() -> void:
	var clock: Array = [1000.0 + 500.0]
	var svc = _make_service(clock)
	# Too early after install: blocked.
	TestRunner.assert_eq(svc.maybe_show_interstitial("stage_unlock"), false, "500 s after install is blocked")
	clock[0] = 1000.0 + 600.0 + 1.0
	TestRunner.assert_eq(svc.maybe_show_interstitial("stage_unlock"), true, "601 s after install is shown")
	clock[0] = 1000.0 + 601.0 + 800.0
	TestRunner.assert_eq(svc.maybe_show_interstitial("stage_unlock"), false, "800 s after last is blocked")
	clock[0] = 1000.0 + 601.0 + 900.0
	TestRunner.assert_eq(svc.maybe_show_interstitial("stage_unlock"), true, "900 s after last is shown")
	svc.remove_ads = true
	clock[0] = 1000.0 + 601.0 + 900.0 + 5000.0
	TestRunner.assert_eq(svc.maybe_show_interstitial("stage_unlock"), false, "remove_ads blocks interstitial")
	svc.free()
