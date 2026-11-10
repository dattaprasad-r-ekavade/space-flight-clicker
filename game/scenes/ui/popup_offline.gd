class_name PopupOffline
extends PanelContainer
## Shows the time away and the earnings. Offers Claim and a rewarded x2 option.

const AD_PLACEMENT: String = "offline_double"
const CLAIM_MULTIPLIER: float = 1.0
const AD_MULTIPLIER: float = 2.0

var _seconds: float = 0.0
var _revenue: float = 0.0


## Set the values before the popup is added to the tree.
func setup(seconds: float, revenue: float) -> void:
	_seconds = seconds
	_revenue = revenue


func _ready() -> void:
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTheme.PAD)
	add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTheme.PAD)
	margin.add_child(box)

	box.add_child(_make_label(tr("Welcome back!"), UiTheme.FONT_TITLE, UiTheme.TEXT))
	box.add_child(_make_label(tr("You were away for %s") % NumFormat.duration(_seconds), UiTheme.FONT_BODY, UiTheme.TEXT_DIM))
	box.add_child(_make_label(tr("Earned"), UiTheme.FONT_BODY, UiTheme.TEXT_DIM))
	box.add_child(_make_label(NumFormat.money(_revenue), UiTheme.FONT_NUMBER, UiTheme.ACCENT))
	_add_button(box, tr("Claim"), _on_claim_pressed)
	_add_button(box, tr("Watch ad: x2"), _on_ad_pressed)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _add_button(box: VBoxContainer, title: String, handler: Callable) -> void:
	var button: BigButton = BigButton.new()
	button.custom_minimum_size = Vector2(0.0, UiTheme.TOUCH)
	box.add_child(button)
	button.set_title(title)
	button.pressed.connect(handler)


func _on_claim_pressed() -> void:
	GameState.claim_offline(CLAIM_MULTIPLIER)
	PopupHost.instance.close_current()


func _on_ad_pressed() -> void:
	var callback: Callable = _on_ad_result
	if AdService.has_method("show_rewarded"):
		AdService.show_rewarded(AD_PLACEMENT, callback)
	else:
		callback.call(true)


func _on_ad_result(granted: bool) -> void:
	if not granted:
		return
	GameState.claim_offline(AD_MULTIPLIER)
	PopupHost.instance.close_current()
