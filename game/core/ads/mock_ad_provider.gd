class_name MockAdProvider
extends AdProvider
## Test and dev provider. Grants or closes after delay_s. Set no_fill to fail every request.

var no_fill: bool = false
var delay_s: float = 1.0


func is_rewarded_ready() -> bool:
	return not no_fill


func show_rewarded(on_result: Callable) -> void:
	if no_fill:
		on_result.call(false)
		return
	_after_delay(func() -> void: on_result.call(true))


func is_interstitial_ready() -> bool:
	return not no_fill


func show_interstitial(on_closed: Callable) -> void:
	if no_fill:
		return
	_after_delay(func() -> void: on_closed.call())


func _after_delay(action: Callable) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if delay_s <= 0.0 or tree == null:
		action.call()
		return
	tree.create_timer(delay_s).timeout.connect(action)
