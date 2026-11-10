class_name NumFormat
extends RefCounted
## Pure formatting for money, height and duration. No node access.

const SCALE_LIMIT: float = 1e6
const KM_LIMIT_M: float = 1e10
const AU_LIMIT_M: float = 9.46e14
const AU_M: float = 1.496e11
const LIGHT_YEAR_M: float = 9.461e15


## Money: "1,234" below 1e6, then "1.23M", "B", "T", "aa", "ab" ...
static func money(v: float) -> String:
	if is_nan(v):
		return "NaN"
	if is_inf(v):
		return "∞" if v > 0.0 else "-∞"
	var r: float = round(absf(v))
	var body: String = _money_abs(r)
	if v < 0.0 and r > 0.0:
		return "-" + body
	return body


## Height in metres: "999 m", "384,400 km", "0.07 AU", "26,000 ly".
static func height(metres: float) -> String:
	if is_nan(metres):
		return "NaN"
	if is_inf(metres):
		return "∞" if metres > 0.0 else "-∞"
	var body: String = _height_abs(absf(metres))
	if metres < 0.0 and body != "0 m":
		return "-" + body
	return body


## Duration: "45s", "1m 30s", "2h 05m".
static func duration(seconds: float) -> String:
	if is_nan(seconds):
		return "NaN"
	if is_inf(seconds):
		return "∞" if seconds > 0.0 else "-∞"
	var total: float = round(absf(seconds))
	var body: String
	if total < 60.0:
		body = "%ds" % int(total)
	elif total < 3600.0:
		body = "%dm %02ds" % [int(total / 60.0), int(fmod(total, 60.0))]
	else:
		body = "%.0fh %02dm" % [floor(total / 3600.0), int(fmod(total, 3600.0) / 60.0)]
	if seconds < 0.0 and total > 0.0:
		return "-" + body
	return body


static func _money_abs(r: float) -> String:
	if r < SCALE_LIMIT:
		return _group(int(r))
	return _scaled(r)


static func _height_abs(a: float) -> String:
	if round(a) < 1000.0:
		return "%d m" % int(round(a))
	if a < KM_LIMIT_M:
		return _money_abs(round(a / 1000.0)) + " km"
	if a < AU_LIMIT_M:
		return "%.2f AU" % (a / AU_M)
	var ly: float = a / LIGHT_YEAR_M
	if ly < 999.5:
		return "%.2f ly" % ly
	return money(ly) + " ly"


## Integer with thousands separators. Expects n >= 0.
static func _group(n: int) -> String:
	var digits: String = str(n)
	var out: String = ""
	var count: int = 0
	for i in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = digits.substr(i, 1) + out
		count += 1
	return out


## Three significant digits with suffix. Expects a >= 1e6 and finite.
static func _scaled(a: float) -> String:
	var g: int = int(floor(log(a) / log(10.0) / 3.0))
	g = maxi(g, 2)
	var mant: float = a / pow(10.0, 3.0 * g)
	while mant >= 1000.0:
		g += 1
		mant = a / pow(10.0, 3.0 * g)
	while mant < 1.0 and g > 2:
		g -= 1
		mant = a / pow(10.0, 3.0 * g)
	var text: String = _mantissa(mant)
	if text.to_float() >= 1000.0:
		g += 1
		mant = a / pow(10.0, 3.0 * g)
		text = _mantissa(mant)
	return text + _suffix(g)


static func _mantissa(m: float) -> String:
	if m < 9.995:
		return "%.2f" % m
	if m < 99.95:
		return "%.1f" % m
	return "%.0f" % m


## g = 2 gives "M" (1e6), 3 gives "B", 4 gives "T", 5 gives "aa", 6 gives "ab" ...
static func _suffix(g: int) -> String:
	if g == 2:
		return "M"
	if g == 3:
		return "B"
	if g == 4:
		return "T"
	var k: int = g - 5
	var first: int = int(float(k) / 26.0)
	var second: int = k - first * 26
	return String.chr(97 + first) + String.chr(97 + second)
