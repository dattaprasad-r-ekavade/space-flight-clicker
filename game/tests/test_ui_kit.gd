extends RefCounted
## Checks the UI kit controls before they enter the tree.


func test_big_button_stores_values() -> void:
	var b: BigButton = BigButton.new()
	b.set_title("Launch")
	b.set_subtitle("Cost 10")
	b.set_affordable(false)
	TestRunner.assert_eq(b.get_title(), "Launch", "title stored")
	TestRunner.assert_eq(b.get_subtitle(), "Cost 10", "subtitle stored")
	TestRunner.assert_true(not b.is_affordable(), "not affordable")
	TestRunner.assert_true(b.disabled, "unaffordable button is disabled")
	TestRunner.assert_true(b.custom_minimum_size.x >= UiTheme.TOUCH, "touch width")
	TestRunner.assert_true(b.custom_minimum_size.y >= UiTheme.TOUCH, "touch height")
	b._ready()
	b.set_title("Buy")
	TestRunner.assert_eq(b.get_title(), "Buy", "title stored after ready")
	b.free()


func test_panel_card_content_is_stable() -> void:
	var p: PanelCard = PanelCard.new()
	var first: VBoxContainer = p.content()
	TestRunner.assert_true(first != null, "content box exists before ready")
	p._ready()
	TestRunner.assert_true(p.content() == first, "content box is the same after ready")
	p.free()


func test_fill_bar_progress_is_clamped() -> void:
	var f: FillBar = FillBar.new()
	f.set_progress(0.5)
	TestRunner.assert_near(f.get_progress(), 0.5, 0.001, "progress stored")
	f.set_progress(2.0)
	TestRunner.assert_near(f.get_progress(), 1.0, 0.001, "progress clamped high")
	f.set_progress(-1.0)
	TestRunner.assert_near(f.get_progress(), 0.0, 0.001, "progress clamped low")
	f.set_fill_color(UiTheme.ACCENT)
	f.set_label("Stage 1")
	f._ready()
	f.set_progress(0.25)
	TestRunner.assert_near(f.get_progress(), 0.25, 0.001, "progress after ready")
	TestRunner.assert_eq(f.get_label(), "Stage 1", "label stored")
	f.free()


func test_tab_strip_tabs_and_selection() -> void:
	var t: TabStrip = TabStrip.new()
	var names: Array[String] = ["A", "B", "C"]
	t.set_tabs(names)
	TestRunner.assert_eq(t.get_tab_count(), 3, "tab count stored")
	TestRunner.assert_eq(t.get_selected(), 0, "first tab selected by default")
	t.select(2)
	TestRunner.assert_eq(t.get_selected(), 2, "select stores index")
	t.select(9)
	TestRunner.assert_eq(t.get_selected(), 2, "out of range select ignored")
	t._ready()
	TestRunner.assert_eq(t.get_tab_count(), 3, "tab count after ready")
	t.select(1)
	TestRunner.assert_eq(t.get_selected(), 1, "select after ready")
	t.free()
