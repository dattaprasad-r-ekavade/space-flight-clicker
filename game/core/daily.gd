class_name Daily
extends RefCounted
## Pure daily reward calendar calculations.

const SECONDS_PER_DAY: float = 86400.0
const CYCLE_LENGTH: int = 7


## Return today's claim availability and the reward for the next valid streak day.
## `utc_offset` is the local offset in seconds east of UTC.
static func status(last_claim_unix: float, streak: int, now_unix: float, utc_offset: int) -> Dictionary:
	var current_streak: int = clampi(streak, 0, CYCLE_LENGTH)
	var claim_streak: int = 1
	var can_claim: bool = true
	var days_since_claim: int = 0
	if last_claim_unix > 0.0:
		var last_local_day: int = floori((last_claim_unix + float(utc_offset)) / SECONDS_PER_DAY)
		var today_local_day: int = floori((now_unix + float(utc_offset)) / SECONDS_PER_DAY)
		days_since_claim = today_local_day - last_local_day
		if days_since_claim <= 0:
			can_claim = false
			claim_streak = maxi(1, current_streak)
		elif days_since_claim == 1 and current_streak > 0:
			claim_streak = current_streak % CYCLE_LENGTH + 1
	var minutes: int = _reward_minutes(claim_streak)
	return {
		"can_claim": can_claim,
		"streak": claim_streak,
		"reward_minutes": minutes,
		"echoes": 3 if claim_streak == CYCLE_LENGTH else 0,
		"days_since_claim": days_since_claim,
	}


static func _reward_minutes(day: int) -> int:
	match day:
		1:
			return 10
		2:
			return 15
		3:
			return 20
		4:
			return 30
		5:
			return 45
		6:
			return 60
		7:
			return 120
	return 10
