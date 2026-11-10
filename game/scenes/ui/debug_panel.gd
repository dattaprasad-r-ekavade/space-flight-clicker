extends Control
## Debug overlay. Only runs in debug builds. Adds a DBG button on the left edge
## that opens a list of cheat and test buttons. UI only: all changes go through GameState.

var _panel: PanelContainer = null


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_toggle()
	_build_panel()


## The DBG button at the middle of the left edge.
func _build_toggle() -> void:
	var toggle: Button = Button.new()
	toggle.text = "DBG"
	toggle.custom_minimum_size = Vector2(UiTheme.TOUCH, UiTheme.TOUCH)
	toggle.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	toggle.anchor_top = 0.22
	toggle.anchor_bottom = 0.22
	toggle.modulate.a = 0.6
	toggle.grow_horizontal = Control.GROW_DIRECTION_END
	toggle.grow_vertical = Control.GROW_DIRECTION_BOTH
	toggle.pressed.connect(_on_toggle_pressed)
	add_child(toggle)


## The hidden panel with the vertical list of buttons.
func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_panel.offset_left = float(UiTheme.TOUCH + UiTheme.PAD)
	_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	_panel.add_child(list)
	_add_button(list, "+1 hour income", Callable(self, "_on_hour_income"))
	_add_button(list, "Revenue x1000", Callable(self, "_on_revenue_x1000"))
	_add_button(list, "Unlock next stage", Callable(self, "_on_unlock_next"))
	_add_button(list, "Speed x1", Callable(self, "_on_speed").bind(1.0))
	_add_button(list, "Speed x10", Callable(self, "_on_speed").bind(10.0))
	_add_button(list, "Speed x100", Callable(self, "_on_speed").bind(100.0))
	_add_button(list, "Simulate 4 h offline", Callable(self, "_on_simulate_offline"))
	_add_button(list, "Grant 100 Echoes", Callable(self, "_on_grant_echoes"))
	_add_button(list, "Wipe save", Callable(self, "_on_wipe_save"))


func _add_button(list: VBoxContainer, text: String, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(UiTheme.TOUCH * 4, UiTheme.TOUCH)
	button.pressed.connect(action)
	list.add_child(button)


func _on_toggle_pressed() -> void:
	_panel.visible = not _panel.visible


func _on_hour_income() -> void:
	GameState.add_revenue(GameState.income_per_second() * 3600.0)


func _on_revenue_x1000() -> void:
	GameState.add_revenue(maxf(GameState.revenue, 1.0) * 999.0)


## Give enough revenue to bring the newest unlocked division to the unlock level.
func _on_unlock_next() -> void:
	var target: String = ""
	for id: String in GameState.division_order:
		if GameState.is_unlocked(id):
			target = id
	if target == "":
		return
	var level: int = int(GameState.divisions[target]["level"])
	var need: int = Economy.LEVEL_UNLOCK - level
	if need <= 0:
		return
	var cost: float = Economy.bulk_cost(GameState.division_data[target], level, need)
	GameState.add_revenue(maxf(cost - GameState.revenue, 0.0))
	GameState.buy_levels(target, need)


func _on_speed(factor: float) -> void:
	Engine.time_scale = factor


func _on_simulate_offline() -> void:
	GameState.last_seen_unix = TimeService.now_unix() - 4.0 * 3600.0
	GameState.compute_pending_offline(TimeService.now_unix())
	EventBus.state_loaded.emit()


func _on_grant_echoes() -> void:
	GameState.echoes += 100
	EventBus.state_loaded.emit()


func _on_wipe_save() -> void:
	GameState.new_game()
	SaveService.save()
	EventBus.state_loaded.emit()
