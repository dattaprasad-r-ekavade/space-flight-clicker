class_name AdProvider
extends RefCounted
## Base class for ad networks. The default answer is "not ready".
## A real network (later task) overrides these methods.


func initialize() -> void:
	pass


func is_rewarded_ready() -> bool:
	return false


func show_rewarded(on_result: Callable) -> void:
	on_result.call(false)


func is_interstitial_ready() -> bool:
	return false


func show_interstitial(on_closed: Callable) -> void:
	on_closed.call()


func show_privacy_options() -> void:
	pass
