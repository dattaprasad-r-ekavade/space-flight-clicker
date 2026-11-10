extends Node
## Owns ad placements, interstitial rules, and ad analytics. UI calls this, never a provider.

signal ad_availability_changed(rewarded_ready: bool)

const PLACEMENTS: Array[String] = ["offline_double", "boost_2x", "time_warp", "echo_bonus"]
const ADS_PATH: String = "user://ads.json"

var remove_ads: bool = false
var install_unix: float = 0.0
var last_interstitial_unix: float = 0.0
## Test hooks. A test sets clock to a Callable returning float, and persist to false.
var clock: Callable = Callable()
var persist: bool = true

var _provider: AdProvider = null


func _ready() -> void:
	_load_state()
	if install_unix <= 0.0:
		install_unix = _now()
		_save()
	set_provider(MockAdProvider.new())


func set_provider(provider: AdProvider) -> void:
	_provider = provider
	if _provider != null:
		_provider.initialize()
	ad_availability_changed.emit(is_rewarded_ready())


func is_rewarded_ready() -> bool:
	return _provider != null and _provider.is_rewarded_ready()


func show_rewarded(placement: String, callback: Callable) -> void:
	if not PLACEMENTS.has(placement) or not is_rewarded_ready():
		_report("ad_rewarded_result", {"placement": placement, "granted": false})
		callback.call(false)
		return
	_provider.show_rewarded(func(granted: bool) -> void:
		_report("ad_rewarded_result", {"placement": placement, "granted": granted})
		callback.call(granted))


func maybe_show_interstitial(reason: String) -> bool:
	if _provider == null or not _provider.is_interstitial_ready():
		return false
	var now: float = _now()
	if not AdRules.can_show_interstitial(now, install_unix, last_interstitial_unix, remove_ads):
		return false
	last_interstitial_unix = now
	_save()
	_report("ad_interstitial_shown", {"reason": reason})
	_provider.show_interstitial(func() -> void:
		_report("ad_interstitial_closed", {"reason": reason}))
	return true


func show_privacy_options() -> void:
	if _provider != null:
		_provider.show_privacy_options()


func _now() -> float:
	if clock.is_valid():
		return clock.call()
	var time_service: Node = _autoload("TimeService")
	if time_service != null and time_service.has_method("now_unix"):
		return time_service.now_unix()
	return Time.get_unix_time_from_system()


func _report(event_name: String, params: Dictionary) -> void:
	var analytics: Node = _autoload("Analytics")
	if analytics != null and analytics.has_method("event"):
		analytics.event(event_name, params)


func _autoload(autoload_name: String) -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/" + autoload_name)


func _load_state() -> void:
	if not FileAccess.file_exists(ADS_PATH):
		return
	var text: String = FileAccess.get_file_as_string(ADS_PATH)
	var data: Variant = JSON.parse_string(text)
	if data is Dictionary:
		var d: Dictionary = data
		install_unix = float(d.get("install_unix", 0.0))
		last_interstitial_unix = float(d.get("last_interstitial_unix", 0.0))


func _save() -> void:
	if not persist:
		return
	var file: FileAccess = FileAccess.open(ADS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"install_unix": install_unix,
		"last_interstitial_unix": last_interstitial_unix,
	}))
	file.close()
