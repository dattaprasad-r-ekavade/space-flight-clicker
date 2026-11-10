class_name LogAnalyticsProvider
extends AnalyticsProvider
## Writes events to the console in debug builds. Keeps the last 50 events for tests.

const MAX_HISTORY: int = 50

var history: Array = []


func log_event(name: String, params: Dictionary) -> void:
	history.append({"name": name, "params": params.duplicate()})
	while history.size() > MAX_HISTORY:
		history.pop_front()
	if OS.is_debug_build():
		print("ANALYTICS %s %s" % [name, str(params)])
