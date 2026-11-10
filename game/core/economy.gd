class_name Economy
extends RefCounted
## Pure economy formulas from game_doc.md section 4 (Formulas).
## Pure logic: no nodes, no autoloads, no clock. `div` is one division Dictionary
## as returned by DataLoader.divisions().

const LEVEL_UNLOCK: int = 25
const FREE_DIVISION_ID: String = "bottles"
const MANAGER_COST_FACTOR: float = 200.0
const LEVEL_MULT_STEP: float = 2.0
const LEVEL_MULT_THRESHOLDS: Array[int] = [10, 25, 50, 100, 150, 200, 300, 400]
const FLIGHT_STEP_MULT: float = 0.5
const FLIGHT_THRESHOLDS: Array[int] = [25, 100, 200, 400]
const GROWTH_EPSILON: float = 1e-12


## Apogee in metres at `level`. Level 1 gives h_start, level 25 and above gives h_ceiling.
static func apogee(div: Dictionary, level: int) -> float:
	var h_start: float = _f(div, "h_start")
	var h_ceiling: float = _f(div, "h_ceiling")
	if h_start <= 0.0:
		return h_start
	var capped: int = mini(maxi(level, 1), LEVEL_UNLOCK)
	var t: float = float(capped - 1) / float(LEVEL_UNLOCK - 1)
	return h_start * pow(h_ceiling / h_start, t)


## Cost to go from `level` to `level + 1`. Division "bottles" at level 0 is free.
static func level_cost(div: Dictionary, level: int) -> float:
	if level == 0 and _is_free_start(div):
		return 0.0
	return _f(div, "base_cost") * pow(_f(div, "growth"), float(level))


## Total cost to buy `count` levels starting at `level`. Equals the sum of level_cost calls.
static func bulk_cost(div: Dictionary, level: int, count: int) -> float:
	if count <= 0:
		return 0.0
	var first: int = _first_paid_level(div, level)
	var paid_count: int = level + count - first
	if paid_count <= 0:
		return 0.0
	return _paid_cost(div, first, paid_count)


## Largest number of levels, starting at `level`, whose bulk_cost is at most `revenue`.
static func max_affordable(div: Dictionary, level: int, revenue: float) -> int:
	var offset: int = _first_paid_level(div, level) - level
	var first: int = level + offset
	var unit: float = _f(div, "base_cost") * pow(_f(div, "growth"), float(first))
	var n_max: int = 0
	if unit > 0.0 and revenue > 0.0:
		n_max = _max_paid_terms(div, first, unit, revenue)
	return offset + n_max


## Revenue multiplier from level thresholds. Doubles at each threshold reached.
static func level_mult(level: int) -> float:
	return pow(LEVEL_MULT_STEP, float(_count_reached(LEVEL_MULT_THRESHOLDS, level)))


## Flight duration in seconds. Halves at each flight threshold reached.
static func flight_time(div: Dictionary, level: int, flight_mult: float) -> float:
	var steps: int = _count_reached(FLIGHT_THRESHOLDS, level)
	return _f(div, "base_flight_s") * pow(FLIGHT_STEP_MULT, float(steps)) * flight_mult


## Revenue for one launch at `level`.
static func launch_revenue(div: Dictionary, level: int, research_mult: float, global_mult: float) -> float:
	return _f(div, "base_rev") * float(level) * level_mult(level) * research_mult * global_mult


## Cost of the manager upgrade for this division.
static func manager_cost(div: Dictionary) -> float:
	return _f(div, "base_cost") * MANAGER_COST_FACTOR


static func _f(div: Dictionary, key: String) -> float:
	return float(div.get(key, 0.0))


static func _is_free_start(div: Dictionary) -> bool:
	return str(div.get("id", "")) == FREE_DIVISION_ID


## The first level that has a price. For the free division this is 1, otherwise `level`.
static func _first_paid_level(div: Dictionary, level: int) -> int:
	if level == 0 and _is_free_start(div):
		return 1
	return level


## Sum of prices for `n` paid levels starting at `first`.
static func _paid_cost(div: Dictionary, first: int, n: int) -> float:
	var start_cost: float = _f(div, "base_cost") * pow(_f(div, "growth"), float(first))
	return start_cost * _geom_sum(_f(div, "growth"), n)


## Number of whole paid levels that fit in `budget`. Uses a logarithm, then fixes by one step.
static func _max_paid_terms(div: Dictionary, first: int, unit: float, budget: float) -> int:
	var g: float = _f(div, "growth")
	var n: int = 0
	if absf(g - 1.0) < GROWTH_EPSILON:
		n = floori(budget / unit)
	else:
		var ratio: float = 1.0 + budget * (g - 1.0) / unit
		n = floori(log(ratio) / log(g))
	n = maxi(n, 0)
	if _paid_cost(div, first, n + 1) <= budget:
		n += 1
	elif n > 0 and _paid_cost(div, first, n) > budget:
		n -= 1
	return n


## 1 + g + g^2 + ... + g^(n-1).
static func _geom_sum(g: float, n: int) -> float:
	if n <= 0:
		return 0.0
	if absf(g - 1.0) < GROWTH_EPSILON:
		return float(n)
	return (pow(g, float(n)) - 1.0) / (g - 1.0)


static func _count_reached(thresholds: Array[int], level: int) -> int:
	var count: int = 0
	for t: int in thresholds:
		if level >= t:
			count += 1
	return count
