class_name OfflineOps
extends RefCounted
## Offline-earnings operations on the GameState node (`gs`).
## GameState keeps one-line methods that call these. Pure maths lives in Offline.


## Work out what the player earned while the game was closed. Sets gs.pending_offline.
static func compute_pending(gs, now_unix: float) -> void:
	var last_seen: float = float(gs.last_seen_unix)
	var away: float = now_unix - last_seen
	if last_seen <= 0.0 or away < Offline.MIN_SECONDS:
		gs.pending_offline = {}
		return
	gs.pending_offline = Offline.compute(gs.income_per_second(), away, gs.offline_cap_seconds())


## Pay the pending offline revenue times `multiplier`. Clears the pending earnings. Returns the amount paid.
static func claim(gs, multiplier: float) -> float:
	var paid: float = float(gs.pending_offline.get("revenue", 0.0)) * multiplier
	gs.pending_offline = {}
	if paid > 0.0:
		gs.add_revenue(paid)
	return paid
