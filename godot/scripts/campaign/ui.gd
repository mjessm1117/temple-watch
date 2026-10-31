extends RefCounted
const BG = Color("101826")
const PANEL = Color("172537")
const PANEL_ALT = Color("1d3045")
const BORDER = Color("35536a")
const TEXT = Color("e8f0ef")
const MUTED = Color("9bb2bc")
const ACCENT = Color("70d7ce")
const GOLD = Color("f1cd83")
const DANGER = Color("e28b85")

static func panel(color: Color = PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	p.add_theme_stylebox_override("panel", style)
	return p

static func label(message: String, size: int = 17, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = message
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func button(message: String, action: Callable, enabled: bool = true) -> Button:
	var b := Button.new()
	b.text = message
	b.disabled = not enabled
	b.custom_minimum_size.y = 40
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(action)
	return b

static func column(gap: int = 10) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", gap)
	return c

static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
