class_name MilestonesOps
extends RefCounted
## Milestone state integration on the GameState node (`gs`).


static func tick(gs, delta: float) -> void:
	var previous_height: float = float(gs.lifetime_height)
	LaunchOps.tick(gs, delta)
	for milestone: Dictionary in Milestones.items():
		var threshold: float = float(milestone.get("threshold", INF))
		if previous_height < threshold and float(gs.lifetime_height) >= threshold:
			gs._toast_milestone(str(milestone.get("name_key", "")))


static func global_mult(gs) -> float:
	return EchoShopOps.global_mult(gs) * Milestones.mult(float(gs.lifetime_height))
