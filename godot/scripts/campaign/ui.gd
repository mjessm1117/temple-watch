extends RefCounted
## Web tokens: public/css/style.css + ui.css. Public factory API is stable.
const BG = Color("0a1113")
const PANEL = Color("0f191c")
const PANEL_ALT = Color("15232a")
const BORDER = Color("22363c")
const TEXT = Color("dbe7e4")
const MUTED = Color("8aa2a5")
const ACCENT = Color("79d3e2")
const GOLD = Color("e0bd78")
const DANGER = Color("ef6a5d")
const Motion = preload("res://scripts/ui_motion.gd")
const Icons = preload("res://scripts/ui_icon.gd")
static var fonts: Dictionary = {}

static func font(kind: String = "body") -> Font:
	if not fonts.has(kind):
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Chakra Petch", "DejaVu Sans"] if kind == "display" else ["IBM Plex Mono", "DejaVu Sans Mono"] if kind == "mono" else ["IBM Plex Sans", "DejaVu Sans"])
		f.font_weight = 600 if kind == "display" else 400
		fonts[kind] = f
	return fonts[kind]

static func style(fill: Color = PANEL, border: Color = BORDER) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.set_content_margin_all(14)
	return s

static func panel(color: Color = PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(color))
	p.add_child(Motion.new())
	return p

static func label(message: String, size: int = 17, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = message
	l.add_theme_font_override("font", font("display" if size >= 24 else "body"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func button(message: String, action: Callable, enabled: bool = true) -> Button:
	var b := Button.new()
	b.text = message
	b.disabled = not enabled
	b.custom_minimum_size.y = 40
	style_button(b)
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

static func style_button(b: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var s := style(PANEL_ALT if state in ["hover", "pressed"] else PANEL, ACCENT if state in ["hover", "pressed", "focus"] else BORDER)
		s.set_content_margin_all(10)
		if state == "hover":
			s.shadow_color = Color(0.47, 0.83, 0.89, 0.14)
			s.shadow_size = 7
		b.add_theme_stylebox_override(state, s)
	b.add_theme_font_override("font", font("display"))
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", ACCENT)
	b.add_theme_color_override("font_pressed_color", ACCENT)
	b.add_theme_color_override("font_disabled_color", Color("52676a"))
	if not b.has_node("UIFeedback"):
		var motion := Motion.new()
		motion.name = "UIFeedback"
		b.add_child(motion)

static func icon(kind: String, side: float = 28.0, color: Color = ACCENT) -> Control:
	var node := Icons.new()
	node.kind = kind
	node.ink = color
	node.custom_minimum_size = Vector2.ONE * side
	return node

static func slide(control: Control) -> void:
	control.modulate.a = 0.0
	control.position.x += 18
	var tween := control.create_tween().set_parallel(true)
	tween.tween_property(control, "modulate:a", 1.0, 0.3)
	tween.tween_property(control, "position:x", control.position.x - 18, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
