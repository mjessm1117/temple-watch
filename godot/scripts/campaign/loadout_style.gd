extends RefCounted
const Theme13 = preload("res://scripts/armory13_theme.gd")
const BG = Color("0a1113")
const PANEL = Color("0f191cf5")
const EDGE = Color("304b53")
const TEXT = Color("dbe7e4")
const MUTED = Color("8aa2a5")
const CYAN = Color("79d3e2")
const GOLD = Color("e0bd78")
const GREEN = Color("7fd99a")
const RED = Color("ef8e80")

static func box(color: Color = PANEL, edge: Color = EDGE, padding: int = 12) -> StyleBoxFlat:
	var s := Theme13.panel_style(padding)
	s.bg_color = color; s.border_color = edge
	return s

static func panel() -> PanelContainer:
	var p := PanelContainer.new(); p.add_theme_stylebox_override("panel", box()); return p

static func label(text: String, size: int = 16, color: Color = TEXT) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", color)
	return l

static func column(gap: int = 6) -> VBoxContainer:
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", gap); return v

static func button(text: String, action: Callable, enabled: bool = true) -> Button:
	var b := Button.new(); b.text = text; b.disabled = not enabled
	b.custom_minimum_size.y = 44 if preload("res://scripts/phone_layout.gd").narrow(preload("res://scripts/phone_layout.gd").window_size()) else 36
	b.add_theme_font_size_override("font_size", 14)
	Theme13.style_button(b)
	b.pressed.connect(action); return b

static func icon(key: String) -> Texture2D:
	var path := "res://assets/loadout/icons/%s.svg" % key
	return load(path if ResourceLoader.exists(path) else "res://assets/loadout/icons/guard.svg")

static func clear(node: Node) -> void:
	for child in node.get_children(): node.remove_child(child); child.queue_free()
