class_name DailyOps
extends RefCounted
## Daily reward state operations on the GameState node (`gs`).


static func status(gs, now_unix: float, utc_offset: int) -> Dictionary:
	return Daily.status(float(gs.daily_last_claim_unix), int(gs.daily_streak), now_unix, utc_offset)


## Claim today's income reward and preserve streak progress across prestige.
static func claim(gs, now_unix: float, utc_offset: int) -> bool:
	var result: Dictionary = status(gs, now_unix, utc_offset)
	if not bool(result["can_claim"]):
		return false
	var streak: int = int(result["streak"])
	var payout: float = gs.income_per_second() * float(int(result["reward_minutes"]) * 60)
	gs.daily_last_claim_unix = now_unix
	gs.daily_streak = streak
	gs.add_revenue(payout)
	gs.echoes += int(result["echoes"])
	gs._emit_bus("state_loaded", [])
	return true


static func prestige(gs, bonus_mult: float) -> void:
	var last_claim: float = float(gs.daily_last_claim_unix)
	var streak: int = int(gs.daily_streak)
	EchoShopOps.prestige(gs, bonus_mult)
	gs.daily_last_claim_unix = last_claim
	gs.daily_streak = streak
