class_name EchoShopOps
extends RefCounted
## Echo Shop state changes on the GameState node (`gs`).


static func buy_echo_item(gs, item_id: String) -> bool:
	var item_data: Dictionary = EchoShop.item(item_id)
	if item_data.is_empty():
		return false
	var levels: Dictionary = gs.echo_levels
	var level: int = int(levels.get(item_id, 0))
	if level >= int(item_data.get("max_level", 0)):
		return false
	var price: float = EchoShop.cost(item_data, level)
	if float(gs.echoes) < price:
		return false
	gs.echoes -= int(price)
	levels[item_id] = level + 1
	return true


static func head_start_revenue(gs) -> float:
	var item_data: Dictionary = EchoShop.item("head_start")
	return EchoShop.head_start(item_data, int(gs.echo_levels.get("head_start", 0)))


static func manager_cost(gs, division_id: String) -> float:
	var item_data: Dictionary = EchoShop.item("old_friends")
	var level: int = int(gs.echo_levels.get("old_friends", 0))
	var index: int = gs.division_order.find(division_id)
	if index >= 0 and index < 3 and EchoShop.old_friends(item_data, level):
		return 0.0
	return Economy.manager_cost(gs.division_data[division_id])


static func pump_taps(gs, division_id: String) -> int:
	var base_taps: int = Research.pump_taps(
		int(gs.division_data[division_id]["pump_taps"]), gs.owned_research
	)
	var item_data: Dictionary = EchoShop.item("muscle_memory")
	var level: int = int(gs.echo_levels.get("muscle_memory", 0))
	return EchoShop.muscle_memory(item_data, level, base_taps)


static func offline_cap_seconds(gs) -> float:
	var item_data: Dictionary = EchoShop.item("long_nap")
	var level: int = int(gs.echo_levels.get("long_nap", 0))
	return EchoShop.long_nap(item_data, level, 4.0 * 3600.0)


static func prestige(gs, bonus_mult: float) -> void:
	if not PrestigeOps.can_prestige(gs):
		return
	PrestigeOps.prestige(gs, bonus_mult)
	gs.revenue = head_start_revenue(gs)
	gs._emit_bus("revenue_changed", [gs.revenue])


static func echo_power(gs) -> float:
	var item_data: Dictionary = EchoShop.item("deep_echo")
	var level: int = int(gs.echo_levels.get("deep_echo", 0))
	return EchoShop.BASE_ECHO_POWER_PER_ECHO + EchoShop.deep_echo(item_data, level)


static func global_mult(gs) -> float:
	var echo_mult: float = 1.0 + float(gs.echoes) * echo_power(gs)
	return Research.global_mult(gs.owned_research) * echo_mult


static func flight_multiplier(gs) -> float:
	var item_data: Dictionary = EchoShop.item("fast_hands")
	var level: int = int(gs.echo_levels.get("fast_hands", 0))
	return Research.flight_mult(gs.owned_research) * EchoShop.fast_hands(item_data, level)


static func lucky_launch_pays_ten(gs, random_value: float) -> bool:
	var item_data: Dictionary = EchoShop.item("lucky_bottle")
	var level: int = int(gs.echo_levels.get("lucky_bottle", 0))
	return EchoShop.lucky_bottle(item_data, level, random_value)


static func unlocked_skin_ids(gs) -> Array[String]:
	var item_data: Dictionary = EchoShop.item("memory_bottles")
	var level: int = int(gs.echo_levels.get("memory_bottles", 0))
	return EchoShop.memory_bottles(item_data, level)
