class_name StatsOps
extends RefCounted
## Play statistics operations on the GameState node (`gs`).


static func tick(gs, delta: float) -> void:
	BoostOps.tick(gs, delta)
	gs.play_time_seconds += delta
	gs.run_time_seconds += delta
	gs.best_run_time_seconds = maxf(float(gs.best_run_time_seconds), float(gs.run_time_seconds))


static func launch_started(gs) -> void:
	gs.total_launches += 1


## Preserve historical stats while resetting the current run for prestige.
static func prestige(gs, bonus_mult: float) -> void:
	var total_launches: int = int(gs.total_launches)
	var play_time: float = float(gs.play_time_seconds)
	var best_run_time: float = maxf(float(gs.best_run_time_seconds), float(gs.run_time_seconds))
	DailyOps.prestige(gs, bonus_mult)
	gs.total_launches = total_launches
	gs.play_time_seconds = play_time
	gs.run_time_seconds = 0.0
	gs.best_run_time_seconds = best_run_time
