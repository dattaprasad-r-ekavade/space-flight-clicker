extends RefCounted
## Tests for the log analytics provider.


func test_log_provider_keeps_last_50() -> void:
	var p = load("res://core/analytics/log_provider.gd").new()
	for i in range(60):
		p.log_event("e", {"i": i})
	TestRunner.assert_eq(p.history.size(), 50, "history keeps 50 events")
	TestRunner.assert_eq(p.history[0]["params"]["i"], 10, "oldest kept is event 10")
	TestRunner.assert_eq(p.history[49]["params"]["i"], 59, "newest is event 59")


func test_base_provider_does_nothing() -> void:
	var p = load("res://core/analytics/analytics_provider.gd").new()
	p.log_event("e", {})
	TestRunner.assert_true(true, "base provider accepts events")
