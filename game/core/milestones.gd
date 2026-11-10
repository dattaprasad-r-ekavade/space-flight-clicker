class_name Milestones
extends RefCounted
## Lifetime Height milestones and their permanent revenue multiplier.

const DATA_PATH: String = "res://data/milestones.json"


static func items() -> Array[Dictionary]:
	var raw_items: Variant = DataLoader.load_json(DATA_PATH)
	var result: Array[Dictionary] = []
	if typeof(raw_items) != TYPE_ARRAY:
		return result
	for raw_item: Variant in raw_items:
		if typeof(raw_item) == TYPE_DICTIONARY:
			result.append(raw_item as Dictionary)
	return result


static func mult(lifetime_height: float) -> float:
	var result: float = 1.0
	for milestone: Dictionary in items():
		if lifetime_height >= float(milestone.get("threshold", INF)):
			result *= float(milestone.get("mult", 1.0))
	return result


static func is_reached(milestone: Dictionary, lifetime_height: float) -> bool:
	return lifetime_height >= float(milestone.get("threshold", INF))
