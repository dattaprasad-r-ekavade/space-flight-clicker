class_name GameStateOps
extends RefCounted
## Fresh-install state initialization for GameState.


static func new_game(gs, company_name: String) -> void:
	if gs.division_order.is_empty():
		gs._load_division_data()
	gs.revenue = 0.0
	gs.run_revenue = 0.0
	gs.record_height = 0.0
	gs.lifetime_height = 0.0
	gs.echoes = 0
	gs.echo_levels = {}
	gs.life = 1
	gs.company_name = company_name
	gs.selected_division = gs.FIRST_DIVISION_ID
	gs.divisions = {}
	gs.owned_research = {}
	gs.last_seen_unix = 0.0
	gs.pending_offline = {}
	gs.boost_2x_remaining = 0.0
	gs.time_warp_cooldown_until = 0.0
	gs.daily_last_claim_unix = 0.0
	gs.daily_streak = 0
	var empty_contracts: Array[Dictionary] = []
	gs.daily_contracts = empty_contracts
	gs.contract_division_snapshot = {}
	gs.total_launches = 0
	gs.play_time_seconds = 0.0
	gs.run_time_seconds = 0.0
	gs.best_run_time_seconds = 0.0
	gs.selected_bottle_skin = ""
	gs.selected_trail_color = "default"
	for id: String in gs.division_order:
		gs.divisions[id] = gs._new_division_state()
