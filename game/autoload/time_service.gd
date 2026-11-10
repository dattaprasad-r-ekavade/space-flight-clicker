extends Node

var _has_override: bool = false
var _override_value: float = 0.0


func now_unix() -> float:
	if _has_override:
		return _override_value
	return Time.get_unix_time_from_system()


func set_override(value: float) -> void:
	_has_override = true
	_override_value = value
