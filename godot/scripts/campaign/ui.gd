extends RefCounted
## Web tokens: public/css/style.css + ui.css. Public factory API is stable.
const BG = Color("0a1113")
const PANEL = Color("0f191c")
const PANEL_ALT = Color("15232a")
const BORDER = Color("22363c")
const TEXT = Color("dbe7e4")
const MUTED = Color("8aa2a5")
const SECONDARY = Color("9bb2b5")
const HINT = Color("9bb2b5")
const ACCENT = Color("79d3e2")
const GOLD = Color("e0bd78")
const DANGER = Color("ef6a5d")
const SURFACE = Color("101b26ee")
const SURFACE_RAISED = Color("152b35f5")
const LINE = GOLD
const TYPE_CAPTION = 14
const TYPE_ACTION = 16
const ICON_SMALL = 24
const ICON_LARGE = 32
const Motion = preload("res://scripts/ui_motion.gd")
const Icons = preload("res://scripts/ui_icon.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Feedback = preload("res://scripts/campaign/style21_feedback.gd")
const StylePrefs = preload("res://scripts/campaign/style21_preferences.gd")
const TYPE = {"small": 14, "body": 16, "title": 20, "hero": 32}
const DISABLED_TEXT = Color("9bb2b5")
static var fonts: Dictionary = {}

static func font(kind: String = "body") -> Font:
	if not fonts.has(kind):
		var f := load("res://assets/fonts/NotoSansMono-Regular.ttf" if kind == "mono" else "res://assets/fonts/NotoSans-Bold.ttf" if kind == "display" else "res://assets/fonts/NotoSans-Regular.ttf") as Font
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
	var tree := Engine.get_main_loop() as SceneTree
	var phone := Phone.narrow(Vector2i(tree.root.size)) if tree != null else Phone.narrow(Phone.window_size())
	l.add_theme_font_size_override("font_size", maxi(14, roundi(size * float(StylePrefs.get_value("text_scale")))) if phone else roundi(size * float(StylePrefs.get_value("text_scale"))))
	l.add_theme_color_override("font_color", readable(color))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func readable(color: Color) -> Color:
	var result := color
	while _contrast(result, PANEL_ALT) < 4.5:
		result = result.lerp(Color.WHITE, 0.08)
	return result

static func _contrast(foreground: Color, background: Color) -> float:
	var a := _luminance(foreground)
	var b := _luminance(background)
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)

static func _luminance(color: Color) -> float:
	var channels := [color.r, color.g, color.b]
	for i in 3: channels[i] = channels[i] / 12.92 if channels[i] <= 0.04045 else pow((channels[i] + 0.055) / 1.055, 2.4)
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]

static func button(message: String, action: Callable, enabled: bool = true) -> Button:
	var b := Button.new()
	b.text = message
	b.disabled = not enabled
	b.custom_minimum_size.y = 44 if Phone.narrow(Phone.window_size()) else 40
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
	var phone := Phone.narrow(Phone.window_size())
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var s := style(Color("315c68") if phone and state == "pressed" else PANEL_ALT if state in ["hover", "pressed"] else PANEL, GOLD if phone and state == "pressed" else ACCENT if state in ["hover", "pressed", "focus"] else BORDER)
		s.set_content_margin_all(10)
		if state == "hover":
			s.shadow_color = Color(0.47, 0.83, 0.89, 0.14)
			s.shadow_size = 7
		b.add_theme_stylebox_override(state, s)
	b.add_theme_font_override("font", font("display"))
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", ACCENT)
	b.add_theme_color_override("font_pressed_color", GOLD if phone else ACCENT)
	b.add_theme_color_override("font_disabled_color", DISABLED_TEXT)
	b.add_theme_color_override("font_focus_color", TEXT)
	if not b.has_node("UIFeedback"):
		var motion := Motion.new()
		motion.name = "UIFeedback"
		b.add_child(motion)
	if not b.has_node("Style21Feedback"):
		var feedback := Feedback.new()
		feedback.name = "Style21Feedback"
		b.add_child(feedback)

static func header(message: String) -> PanelContainer:
	var p := panel(PANEL_ALT)
	p.add_child(label(message, TYPE.title, GOLD))
	return p

static func ensure_phone_type(node: Node) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or not Phone.narrow(Vector2i(tree.root.size)) and not Phone.mobile_device(): return
	if node is Label:
		var item := node as Label
		item.add_theme_font_override("font", font("body"))
		item.add_theme_font_size_override("font_size", maxi(14, item.get_theme_font_size("font_size")))
	for child in node.get_children(): ensure_phone_type(child)

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
