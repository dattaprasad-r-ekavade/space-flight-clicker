extends Control
## Shows one of each UI kit control. Run kit_demo.tscn to check the look.


func _ready() -> void:
	theme = UiTheme.build()
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", UiTheme.PAD)
	add_child(box)

	var buy: BigButton = BigButton.new()
	buy.set_title(tr("Buy stage"))
	buy.set_subtitle(NumFormat.money(1234.0))
	box.add_child(buy)

	var locked: BigButton = BigButton.new()
	locked.set_title(tr("Locked"))
	locked.set_subtitle(NumFormat.money(99999.0))
	locked.set_affordable(false)
	box.add_child(locked)

	var card: PanelCard = PanelCard.new()
	box.add_child(card)
	var note: Label = Label.new()
	note.text = tr("Panel text")
	card.content().add_child(note)

	var bar: FillBar = FillBar.new()
	bar.set_fill_color(UiTheme.GOOD)
	bar.set_label(tr("Progress"))
	bar.set_progress(0.6)
	box.add_child(bar)

	var tabs: TabStrip = TabStrip.new()
	var names: Array[String] = [tr("Launch"), tr("Upgrade"), tr("Research")]
	tabs.set_tabs(names)
	box.add_child(tabs)
