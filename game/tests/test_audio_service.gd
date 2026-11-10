extends RefCounted
## Tests the pure rate-limit helper of AudioService.

const AudioSvc = preload("res://autoload/audio_service.gd")


func test_can_play_never_played() -> void:
	TestRunner.assert_true(AudioSvc.can_play(-1, 0), "first play is allowed at time 0")


func test_can_play_blocked_inside_window() -> void:
	TestRunner.assert_true(not AudioSvc.can_play(1000, 1030), "30 ms later is blocked")


func test_can_play_allowed_after_window() -> void:
	TestRunner.assert_true(AudioSvc.can_play(1000, 1060), "60 ms later is allowed")
