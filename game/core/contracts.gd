class_name Contracts
extends RefCounted
## Pure daily contract selection and target scaling.

const SECONDS_PER_DAY: float = 86400.0
const DAILY_COUNT: int = 3


static func date_key(now_unix: float, utc_offset: int) -> int:
	return floori((now_unix + float(utc_offset)) / SECONDS_PER_DAY)


## Choose three distinct templates reproducibly from the local date key.
static func select(templates: Array, date_seed: int, highest_stage: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for item: Variant in templates:
		if typeof(item) == TYPE_DICTIONARY:
			pool.append((item as Dictionary).duplicate(true))
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = date_seed
	for i: int in range(pool.size() - 1, 0, -1):
		var swap_index: int = random.randi_range(0, i)
		var temporary: Dictionary = pool[i]
		pool[i] = pool[swap_index]
		pool[swap_index] = temporary
	var selected: Array[Dictionary] = []
	for i: int in range(mini(DAILY_COUNT, pool.size())):
		var template: Dictionary = pool[i]
		var target: int = target_for_stage(int(template.get("base_target", 1)), int(template.get("stage_scale", 0)), highest_stage)
		selected.append({
			"id": str(template.get("id", "")),
			"date_key": date_seed,
			"type": str(template.get("type", "")),
			"title": str(template.get("title", "")),
			"target": target,
			"progress": 0,
			"complete": false,
		})
	return selected


static func target_for_stage(base_target: int, stage_scale: int, highest_stage: int) -> int:
	return maxi(1, base_target + maxi(0, highest_stage - 1) * stage_scale)
