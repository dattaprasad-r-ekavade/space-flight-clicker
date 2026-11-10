class_name UiTheme
extends RefCounted
## Builds the one UI theme used by every Control in the game.
## Colours and sizes are public so other UI files can use them.

const BG: Color = Color("#141A2E")
const PANEL: Color = Color("#1F2847")
const PANEL_LIGHT: Color = Color("#2B3763")
const ACCENT: Color = Color("#F28C28")
const ACCENT_2: Color = Color("#5CF2FF")
const GOOD: Color = Color("#6BBF59")
const TEXT: Color = Color("#F4F4F0")
const TEXT_DIM: Color = Color("#A8B0C8")
const DISABLED: Color = Color("#4A525E")

const FONT_BODY: int = 40
const FONT_SMALL: int = 30
const FONT_TITLE: int = 56
const FONT_NUMBER: int = 64

const RADIUS: int = 24
const PAD: int = 24
const TOUCH: int = 96

const FONT_REGULAR_PATH: String = "res://assets/fonts/NotoSans-Regular.ttf"
const FONT_BOLD_PATH: String = "res://assets/fonts/NotoSans-Bold.ttf"
const SCROLL_WIDTH: int = 6


## Returns the full theme. Uses Noto Sans when the font files exist,
## otherwise the engine default font.
static func build() -> Theme:
	var theme: Theme = Theme.new()
	var regular: Font = _load_font(FONT_REGULAR_PATH)
	var bold: Font = _load_font(FONT_BOLD_PATH)
	if regular != null:
		theme.default_font = regular
	if bold == null:
		bold = regular
	theme.default_font_size = FONT_BODY

	_set_label(theme)
	_set_button(theme, bold)
	_set_panel(theme)
	_set_progress(theme)
	_set_line_edit(theme, regular)
	_set_scroll(theme)
	return theme


## True when both Noto Sans font files exist in the project.
static func has_custom_fonts() -> bool:
	return FileAccess.file_exists(FONT_REGULAR_PATH) and FileAccess.file_exists(FONT_BOLD_PATH)


static func _load_font(path: String) -> Font:
	if not FileAccess.file_exists(path):
		return null
	return load(path) as Font


static func _flat(bg: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(RADIUS)
	box.content_margin_left = PAD
	box.content_margin_right = PAD
	box.content_margin_top = PAD / 2
	box.content_margin_bottom = PAD / 2
	return box


static func _set_label(theme: Theme) -> void:
	theme.set_color("font_color", "Label", TEXT)
	theme.set_font_size("font_size", "Label", FONT_BODY)


static func _set_button(theme: Theme, bold: Font) -> void:
	theme.set_stylebox("normal", "Button", _flat(PANEL_LIGHT))
	theme.set_stylebox("hover", "Button", _flat(PANEL_LIGHT.lightened(0.12)))
	theme.set_stylebox("pressed", "Button", _flat(ACCENT))
	theme.set_stylebox("disabled", "Button", _flat(DISABLED))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", TEXT)
	theme.set_color("font_pressed_color", "Button", BG)
	theme.set_color("font_disabled_color", "Button", TEXT_DIM)
	theme.set_font_size("font_size", "Button", FONT_BODY)
	if bold != null:
		theme.set_font("font", "Button", bold)


static func _set_panel(theme: Theme) -> void:
	theme.set_stylebox("panel", "PanelContainer", _flat(PANEL))


static func _set_progress(theme: Theme) -> void:
	var back: StyleBoxFlat = _flat(PANEL_LIGHT)
	back.content_margin_left = 0
	back.content_margin_right = 0
	back.content_margin_top = 0
	back.content_margin_bottom = 0
	var fill: StyleBoxFlat = _flat(GOOD)
	fill.content_margin_left = 0
	fill.content_margin_right = 0
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	theme.set_stylebox("background", "ProgressBar", back)
	theme.set_stylebox("fill", "ProgressBar", fill)
	theme.set_color("font_color", "ProgressBar", TEXT)
	theme.set_font_size("font_size", "ProgressBar", FONT_SMALL)


static func _set_line_edit(theme: Theme, regular: Font) -> void:
	var normal: StyleBoxFlat = _flat(PANEL_LIGHT)
	var focus: StyleBoxFlat = _flat(PANEL_LIGHT)
	focus.border_width_bottom = 4
	focus.border_color = ACCENT_2
	theme.set_stylebox("normal", "LineEdit", normal)
	theme.set_stylebox("focus", "LineEdit", focus)
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", TEXT_DIM)
	theme.set_color("caret_color", "LineEdit", ACCENT_2)
	theme.set_color("selection_color", "LineEdit", ACCENT_2.darkened(0.4))
	theme.set_font_size("font_size", "LineEdit", FONT_BODY)
	if regular != null:
		theme.set_font("font", "LineEdit", regular)


static func _set_scroll(theme: Theme) -> void:
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = PANEL
	track.set_corner_radius_all(SCROLL_WIDTH)
	track.content_margin_left = SCROLL_WIDTH
	track.content_margin_right = SCROLL_WIDTH
	var grab: StyleBoxFlat = StyleBoxFlat.new()
	grab.bg_color = TEXT_DIM
	grab.set_corner_radius_all(SCROLL_WIDTH)
	grab.content_margin_left = SCROLL_WIDTH
	grab.content_margin_right = SCROLL_WIDTH
	var grab_hi: StyleBoxFlat = grab.duplicate() as StyleBoxFlat
	grab_hi.bg_color = ACCENT_2
	theme.set_stylebox("scroll", "VScrollBar", track)
	theme.set_stylebox("grabber", "VScrollBar", grab)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grab_hi)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grab_hi)
