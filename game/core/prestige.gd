class_name Prestige
extends RefCounted
## Pure prestige formulas.


static func echoes_for(run_revenue: float, bonus_mult: float) -> int:
	var eligible_revenue: float = maxf(run_revenue, 0.0)
	var multiplier: float = maxf(bonus_mult, 0.0)
	return int(floor(10.0 * sqrt(eligible_revenue / 1.0e12) * multiplier))
