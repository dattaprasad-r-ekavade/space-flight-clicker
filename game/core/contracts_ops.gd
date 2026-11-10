class_name ContractsOps
extends RefCounted
## Daily contract state operations on the GameState node (`gs`).

const CONTRACTS_PATH: String = "res://data/contracts.json"
const CONTRACT_REWARD_SECONDS: float = 15.0 * 60.0


static func status(gs, now_unix: float, utc_offset: int) -> Array[Dictionary]:
	_ensure_today(gs, now_unix, utc_offset)
	var result: Array[Dictionary] = []
	for item: Dictionary in gs.daily_contracts:
		result.append(item.duplicate(true))
	return result


static func on_launch_started(gs, now_unix: float, utc_offset: int) -> void:
	_ensure_today(gs, now_unix, utc_offset)
	_advance(gs, "launch", 1)


static func on_division_changed(gs, id: String, now_unix: float, utc_offset: int) -> void:
	_ensure_today(gs, now_unix, utc_offset)
	if not gs.divisions.has(id):
		return
	var current: Dictionary = gs.divisions[id]
	var previous: Dictionary = gs.contract_division_snapshot.get(id, {
		"level": int(current["level"]), "has_manager": bool(current["has_manager"])
	})
	var level_delta: int = maxi(0, int(current["level"]) - int(previous["level"]))
	var hired: bool = not bool(previous["has_manager"]) and bool(current["has_manager"])
	gs.contract_division_snapshot[id] = {
		"level": int(current["level"]), "has_manager": bool(current["has_manager"])
	}
	if level_delta > 0:
		_advance(gs, "levels", level_delta)
	if hired:
		_advance(gs, "manager", 1)


static func on_boost_used(gs, now_unix: float, utc_offset: int) -> void:
	_ensure_today(gs, now_unix, utc_offset)
	_advance(gs, "boost", 1)


static func boost_granted(gs, seconds_left: float) -> float:
	gs._emit_bus("boost_changed", [])
	return seconds_left


static func time_warp_granted(gs, used: bool) -> bool:
	if used:
		gs._emit_bus("boost_changed", [])
	return used


static func _ensure_today(gs, now_unix: float, utc_offset: int) -> void:
	var key: int = Contracts.date_key(now_unix, utc_offset)
	if gs.daily_contracts.size() == Contracts.DAILY_COUNT and int(gs.daily_contracts[0].get("date_key", 0)) == key:
		return
	var templates: Array = DataLoader.load_json(CONTRACTS_PATH)
	var highest_stage: int = 1
	for index: int in range(gs.division_order.size()):
		if gs.is_unlocked(str(gs.division_order[index])):
			highest_stage = index + 1
	gs.daily_contracts = Contracts.select(templates, key, highest_stage)
	gs.contract_division_snapshot = _division_snapshot(gs)


static func _division_snapshot(gs) -> Dictionary:
	var snapshot: Dictionary = {}
	for id: String in gs.division_order:
		var current: Dictionary = gs.divisions[id]
		snapshot[id] = {"level": int(current["level"]), "has_manager": bool(current["has_manager"])}
	return snapshot


static func _advance(gs, contract_type: String, amount: int) -> void:
	for i: int in range(gs.daily_contracts.size()):
		var contract: Dictionary = gs.daily_contracts[i]
		if str(contract["type"]) != contract_type or bool(contract["complete"]):
			continue
		contract["progress"] = mini(int(contract["target"]), int(contract["progress"]) + amount)
		if int(contract["progress"]) >= int(contract["target"]):
			contract["complete"] = true
			gs.add_revenue(gs.income_per_second() * CONTRACT_REWARD_SECONDS)
		var contracts: Array[Dictionary] = gs.daily_contracts
		contracts[i] = contract
		gs.daily_contracts = contracts
	if gs.daily_contracts.size() == Contracts.DAILY_COUNT:
		var all_complete: bool = true
		for contract: Dictionary in gs.daily_contracts:
			all_complete = all_complete and bool(contract["complete"])
		var last: int = gs.daily_contracts.size() - 1
		var final_contract: Dictionary = gs.daily_contracts[last]
		if all_complete and not bool(final_contract.get("echo_paid", false)):
			gs.echoes += 1
			final_contract["echo_paid"] = true
			var contracts: Array[Dictionary] = gs.daily_contracts
			contracts[last] = final_contract
			gs.daily_contracts = contracts
			gs._emit_bus("state_loaded", [])
