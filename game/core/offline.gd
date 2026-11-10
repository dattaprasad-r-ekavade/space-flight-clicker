class_name Offline
extends RefCounted
## Offline earnings maths. Pure: no nodes, no clock. Design section 7.

## Shortest absence that pays anything. Shorter absences show no popup.
const MIN_SECONDS: float = 60.0


## Earnings for an absence. Returns {seconds_counted: float, revenue: float}.
## Negative time away and time below MIN_SECONDS give zero. Time is capped at cap_seconds.
static func compute(income_per_second: float, seconds_away: float, cap_seconds: float) -> Dictionary:
	if seconds_away < MIN_SECONDS:
		return {"seconds_counted": 0.0, "revenue": 0.0}
	var counted: float = minf(seconds_away, maxf(cap_seconds, 0.0))
	return {"seconds_counted": counted, "revenue": income_per_second * counted}
