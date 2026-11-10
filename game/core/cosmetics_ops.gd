class_name CosmeticsOps
extends RefCounted
## Bottle skin and trail colour selection on the GameState node (`gs`).


static func unlocked_trail_ids(gs) -> Array[String]:
	var ids: Array[String] = ["default"]
	if int(gs.life) >= 2:
		ids.append("blue")
	if int(gs.life) >= 5:
		ids.append("orange")
	if int(gs.life) >= 10:
		ids.append("cyan")
	if int(gs.life) >= 25:
		ids.append("purple")
	return ids


static func choose_bottle_skin(gs, id: String) -> bool:
	if not id.is_empty() and not gs.unlocked_skin_ids().has(id):
		return false
	gs.selected_bottle_skin = id
	gs._emit_bus("state_loaded", [])
	return true


static func choose_trail_color(gs, id: String) -> bool:
	if not unlocked_trail_ids(gs).has(id):
		return false
	gs.selected_trail_color = id
	gs._emit_bus("state_loaded", [])
	return true


## Cosmetics are permanent and survive prestige alongside historical statistics.
static func prestige(gs, bonus_mult: float) -> void:
	var bottle_skin: String = str(gs.selected_bottle_skin)
	var trail_color: String = str(gs.selected_trail_color)
	StatsOps.prestige(gs, bonus_mult)
	gs.selected_bottle_skin = bottle_skin
	gs.selected_trail_color = trail_color
	gs._emit_bus("state_loaded", [])
