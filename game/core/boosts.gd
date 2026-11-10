class_name BoostOps
extends RefCounted
## Rewarded boost state operations on the GameState node (`gs`).

const BOOST_2X_SECONDS: float = 30.0 * 60.0
const BOOST_2X_CAP_SECONDS: float = 4.0 * 60.0 * 60.0
const TIME_WARP_SECONDS: float = 20.0 * 60.0
const TIME_WARP_COOLDOWN_SECONDS: float = 15.0 * 60.0


## Advance the regular game tick and drain active-play boost time.
static func tick(gs, delta: float) -> void:
	MilestonesOps.tick(gs, delta)
	gs.boost_2x_remaining = maxf(0.0, float(gs.boost_2x_remaining) - delta)


## Add a 30-minute boost, capped at four hours, and return its new remaining time.
static func grant_boost_2x(gs) -> float:
	gs.boost_2x_remaining = minf(
		BOOST_2X_CAP_SECONDS, float(gs.boost_2x_remaining) + BOOST_2X_SECONDS
	)
	return float(gs.boost_2x_remaining)


## Apply the boost to the existing global revenue multiplier.
static func global_mult(gs, base_mult: float) -> float:
	if float(gs.boost_2x_remaining) > 0.0:
		return base_mult * 2.0
	return base_mult


## Check the saved wall-clock cooldown using a caller-supplied time.
static func can_time_warp(gs, now_unix: float) -> bool:
	return now_unix >= float(gs.time_warp_cooldown_until)


## Pay 20 minutes of current income and begin the 15-minute cooldown.
static func use_time_warp(gs, now_unix: float) -> bool:
	if not can_time_warp(gs, now_unix):
		return false
	var payout: float = gs.income_per_second() * TIME_WARP_SECONDS
	gs.time_warp_cooldown_until = now_unix + TIME_WARP_COOLDOWN_SECONDS
	gs.add_revenue(payout)
	return true
