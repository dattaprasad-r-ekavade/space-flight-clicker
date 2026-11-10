extends RefCounted
## Tests Echo Shop prices and permanent purchases.


func _new_state() -> Node:
	var script: GDScript = load("res://autoload/game_state.gd") as GDScript
	var gs: Node = script.new() as Node
	gs.new_game()
	return gs


func test_cost_scales_by_three() -> void:
	var shop_script: GDScript = load("res://core/echo_shop.gd") as GDScript
	var item: Dictionary = {"base_cost": 10.0}
	TestRunner.assert_eq(shop_script.cost(item, 0), 10.0, "level zero costs base cost")
	TestRunner.assert_eq(shop_script.cost(item, 1), 30.0, "level one costs three times base cost")
	TestRunner.assert_eq(shop_script.cost(item, 2), 90.0, "level two costs nine times base cost")


func test_cannot_buy_past_max_level() -> void:
	var gs: Node = _new_state()
	gs.set("echoes", 1000)
	TestRunner.assert_true(gs.call("buy_echo_item", "old_friends"), "first level purchases")
	TestRunner.assert_true(not gs.call("buy_echo_item", "old_friends"), "max-level item cannot be purchased again")
	var levels: Dictionary = gs.get("echo_levels")
	TestRunner.assert_eq(int(levels["old_friends"]), 1, "level remains at maximum")
	gs.free()


func test_cannot_buy_without_enough_echoes() -> void:
	var gs: Node = _new_state()
	gs.set("echoes", 9)
	TestRunner.assert_true(not gs.call("buy_echo_item", "head_start"), "purchase fails below the price")
	var levels: Dictionary = gs.get("echo_levels")
	TestRunner.assert_true(not levels.has("head_start"), "failed purchase leaves level unchanged")
	TestRunner.assert_eq(int(gs.get("echoes")), 9, "failed purchase leaves Echoes unchanged")
	gs.free()


func test_echo_levels_survive_prestige_and_save() -> void:
	var gs: Node = _new_state()
	gs.set("echoes", 10)
	TestRunner.assert_true(gs.call("buy_echo_item", "head_start"), "purchase succeeds")
	var encoded: Dictionary = gs.call("to_dict")
	var loaded_state: Node = _new_state()
	loaded_state.call("from_dict", encoded)
	var loaded_levels: Dictionary = loaded_state.get("echo_levels")
	TestRunner.assert_eq(int(loaded_levels["head_start"]), 1, "purchase level is saved")
	gs.free()

	var divisions: Dictionary = loaded_state.get("divisions")
	var order: Array = loaded_state.get("division_order")
	var final_id: String = str(order.back())
	divisions[final_id]["level"] = 25
	loaded_state.call("prestige", 1.0)
	var levels_after_prestige: Dictionary = loaded_state.get("echo_levels")
	TestRunner.assert_eq(int(levels_after_prestige["head_start"]), 1, "purchase level survives prestige")
	loaded_state.free()
