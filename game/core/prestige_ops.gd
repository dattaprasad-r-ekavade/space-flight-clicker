class_name PrestigeOps
extends RefCounted
## Prestige state changes on the GameState node (`gs`).


static func can_prestige(gs) -> bool:
	if gs.division_order.is_empty():
		return false
	var final_id: String = gs.division_order.back()
	if not gs.divisions.has(final_id):
		return false
	return int(gs.divisions[final_id]["level"]) >= 25


static func prestige(gs, bonus_mult: float) -> void:
	if not can_prestige(gs):
		return
	gs.echoes += Prestige.echoes_for(float(gs.run_revenue), bonus_mult)
	gs.revenue = 0.0
	gs.run_revenue = 0.0
	gs.record_height = 0.0
	gs.selected_division = gs.FIRST_DIVISION_ID
	gs.divisions = {}
	for id: String in gs.division_order:
		gs.divisions[id] = gs._new_division_state()
	gs.owned_research = {}
	gs.pending_offline = {}
	gs.life += 1
	gs._emit_bus("revenue_changed", [gs.revenue])
	gs._emit_bus("record_height_changed", [gs.record_height])
	for id: String in gs.division_order:
		gs._emit_bus("division_changed", [id])
