extends RefCounted
## Tests for the daily reward calendar.

const DAY_SECONDS: float = 86400.0


func test_same_local_day_cannot_claim_twice() -> void:
	var result: Dictionary = Daily.status(10.0 * DAY_SECONDS + 100.0, 3, 10.0 * DAY_SECONDS + 500.0, 0)
	TestRunner.assert_true(not bool(result["can_claim"]), "same day is not claimable twice")
	TestRunner.assert_eq(int(result["streak"]), 3, "same day keeps the current streak")
	TestRunner.assert_eq(int(result["reward_minutes"]), 20, "same day shows the current reward")


func test_next_day_advances_streak() -> void:
	var result: Dictionary = Daily.status(10.0 * DAY_SECONDS + 100.0, 3, 11.0 * DAY_SECONDS + 100.0, 0)
	TestRunner.assert_true(bool(result["can_claim"]), "next day is claimable")
	TestRunner.assert_eq(int(result["streak"]), 4, "next day advances the streak")
	TestRunner.assert_eq(int(result["reward_minutes"]), 30, "day four pays 30 minutes")


func test_missed_day_restarts_streak() -> void:
	var result: Dictionary = Daily.status(10.0 * DAY_SECONDS + 100.0, 5, 12.0 * DAY_SECONDS + 100.0, 0)
	TestRunner.assert_true(bool(result["can_claim"]), "claim is available after a missed day")
	TestRunner.assert_eq(int(result["streak"]), 1, "missed day restarts at day one")
	TestRunner.assert_eq(int(result["reward_minutes"]), 10, "restart pays day one")


func test_day_seven_reward_and_cycle_wrap() -> void:
	var day_seven: Dictionary = Daily.status(10.0 * DAY_SECONDS + 100.0, 6, 11.0 * DAY_SECONDS + 100.0, 0)
	TestRunner.assert_eq(int(day_seven["streak"]), 7, "streak reaches day seven")
	TestRunner.assert_eq(int(day_seven["reward_minutes"]), 120, "day seven pays 120 minutes")
	TestRunner.assert_eq(int(day_seven["echoes"]), 3, "day seven grants three Echoes")
	var wrapped: Dictionary = Daily.status(11.0 * DAY_SECONDS + 100.0, 7, 12.0 * DAY_SECONDS + 100.0, 0)
	TestRunner.assert_eq(int(wrapped["streak"]), 1, "cycle wraps back to day one")


func test_clock_set_backwards_cannot_claim() -> void:
	var result: Dictionary = Daily.status(10.0 * DAY_SECONDS + 100.0, 4, 9.0 * DAY_SECONDS + 100.0, 0)
	TestRunner.assert_true(not bool(result["can_claim"]), "backwards clock cannot restore claim")
	TestRunner.assert_eq(int(result["streak"]), 4, "backwards clock preserves streak")


func test_utc_offset_changes_local_day_boundary() -> void:
	var last_claim: float = 10.0 * DAY_SECONDS + 21.0 * 3600.0
	var now_unix: float = last_claim + 2.0 * 3600.0
	var result: Dictionary = Daily.status(last_claim, 1, now_unix, 2 * 3600)
	TestRunner.assert_true(bool(result["can_claim"]), "offset crosses the local midnight boundary")
