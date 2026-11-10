class_name EchoShop
extends RefCounted
## Echo Shop data and pure formulas.

const DATA_PATH: String = "res://data/echo_shop.json"
const BASE_ECHO_POWER_PER_ECHO: float = 0.02


static func items() -> Array[Dictionary]:
	var raw_items: Variant = DataLoader.load_json(DATA_PATH)
	var result: Array[Dictionary] = []
	if typeof(raw_items) != TYPE_ARRAY:
		return result
	for raw_item: Variant in raw_items:
		if typeof(raw_item) == TYPE_DICTIONARY:
			result.append(raw_item as Dictionary)
	return result


static func item(item_id: String) -> Dictionary:
	for entry: Dictionary in items():
		if str(entry.get("id", "")) == item_id:
			return entry
	return {}


static func cost(item_data: Dictionary, level: int) -> float:
	var base_cost: float = float(item_data.get("base_cost", 0.0))
	return base_cost * pow(3.0, float(maxi(level, 0)))


static func head_start(item_data: Dictionary, level: int) -> float:
	if level <= 0:
		return 0.0
	var value: Dictionary = item_data.get("value", {}) as Dictionary
	var start: float = float(value.get("start", 0.0))
	var growth: float = float(value.get("growth", 1.0))
	return start * pow(growth, float(level))


static func old_friends(item_data: Dictionary, level: int) -> bool:
	return level > 0 and float(item_data.get("value", 0.0)) > 0.0


static func muscle_memory(item_data: Dictionary, level: int, base_taps: int) -> int:
	if level <= 0:
		return base_taps
	var reduction: float = clampf(float(item_data.get("value", 0.0)), 0.0, 1.0)
	return maxi(2, roundi(float(base_taps) * pow(1.0 - reduction, float(level))))


static func long_nap(item_data: Dictionary, level: int, base_cap_seconds: float) -> float:
	var seconds_per_level: float = float(item_data.get("value", 0.0))
	return base_cap_seconds + float(maxi(level, 0)) * seconds_per_level


static func deep_echo(item_data: Dictionary, level: int) -> float:
	return float(maxi(level, 0)) * float(item_data.get("value", 0.0))


static func fast_hands(item_data: Dictionary, level: int) -> float:
	var reduction: float = clampf(float(item_data.get("value", 0.0)), 0.0, 1.0)
	return pow(1.0 - reduction, float(maxi(level, 0)))


static func lucky_bottle(item_data: Dictionary, level: int, random_value: float) -> bool:
	var chance: float = clampf(float(maxi(level, 0)) * float(item_data.get("value", 0.0)), 0.0, 1.0)
	return random_value >= 0.0 and random_value < chance


static func memory_bottles(item_data: Dictionary, level: int) -> Array[String]:
	var unlocked: Array[String] = []
	var skin_count: int = mini(maxi(level, 0), int(item_data.get("max_level", 0)))
	for skin_number: int in range(skin_count):
		unlocked.append("memory_bottle_%d" % (skin_number + 1))
	return unlocked
