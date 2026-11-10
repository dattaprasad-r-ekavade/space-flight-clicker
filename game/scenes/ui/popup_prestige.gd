class_name PopupPrestige
extends PanelContainer
## Black hole popup: Echoes to gain, what resets and what stays, an optional ad bonus, and Enter.

const AD_PLACEMENT: String = "echo_bonus"
const AD_BONUS_MULT: float = 1.25
const CINEMATIC_NODE: String = "CinematicPrestige"

var _bonus_mult: float = 1.0
var _ad_pending: bool = false
var _entered: bool = false
var _gain_label: Label = null
var _ad_button: BigButton = null
var _enter_button: BigButton = null


func _ready() -> void:
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTheme.PAD)
	add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTheme.PAD)
	margin.add_child(box)

	box.add_child(_make_label(tr("Enter the Black Hole?"), UiTheme.FONT_TITLE, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	_gain_label = _make_label("", UiTheme.FONT_NUMBER, UiTheme.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_gain_label)

	box.add_child(_make_label(tr("You lose:"), UiTheme.FONT_SMALL, UiTheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT))
	var lose_lines: Array[String] = [
		tr("Revenue"), tr("Division levels"), tr("Managers"),
		tr("Research"), tr("Record height"), tr("Active boosts"),
	]
	box.add_child(_make_label(_join(lose_lines), UiTheme.FONT_BODY, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT))

	box.add_child(_make_label(tr("You keep:"), UiTheme.FONT_SMALL, UiTheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT))
	var keep_lines: Array[String] = [
		tr("Echoes"), tr("Echo Shop upgrades"), tr("Lifetime height and milestones"),
		tr("Cosmetics"), tr("Settings"),
	]
	box.add_child(_make_label(_join(keep_lines), UiTheme.FONT_BODY, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT))

	_ad_button = _add_button(box, tr("Watch ad: +25% Echoes"), _on_ad_pressed)
	_enter_button = _add_button(box, tr("Enter"), _on_enter_pressed)
	_add_button(box, tr("Not yet"), _on_not_yet_pressed)
	_refresh_gain()


func _make_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _add_button(box: VBoxContainer, title: String, handler: Callable) -> BigButton:
	var button: BigButton = BigButton.new()
	button.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
	box.add_child(button)
	button.set_title(title)
	button.pressed.connect(handler)
	return button


func _join(lines: Array[String]) -> String:
	return "\n".join(PackedStringArray(lines))


## The Echoes to gain use the run revenue and the current bonus multiplier.
func _refresh_gain() -> void:
	var gain: int = Prestige.echoes_for(GameState.run_revenue, _bonus_mult)
	_gain_label.text = tr("Echoes to gain: %d") % gain


func _on_ad_pressed() -> void:
	if _ad_pending or _entered:
		return
	_ad_pending = true
	AdService.show_rewarded(AD_PLACEMENT, _on_ad_result)


func _on_ad_result(granted: bool) -> void:
	_ad_pending = false
	if not granted:
		return
	_bonus_mult = AD_BONUS_MULT
	_ad_button.disabled = true
	_refresh_gain()


## Play the cinematic first when it exists. Prestige after its finished signal.
func _on_enter_pressed() -> void:
	if _entered:
		return
	_entered = true
	_enter_button.disabled = true
	_ad_button.disabled = true
	var cinematic: Node = get_tree().root.find_child(CINEMATIC_NODE, true, false)
	if cinematic != null and cinematic.has_method("play") and cinematic.has_signal("finished"):
		cinematic.connect("finished", _do_prestige, CONNECT_ONE_SHOT)
		cinematic.call("play")
		return
	_do_prestige()


func _do_prestige() -> void:
	GameState.prestige(_bonus_mult)
	AdService.maybe_show_interstitial("prestige")
	EventBus.state_loaded.emit()
	if PopupHost.instance != null:
		PopupHost.instance.close_current()


func _on_not_yet_pressed() -> void:
	if PopupHost.instance != null:
		PopupHost.instance.close_current()
