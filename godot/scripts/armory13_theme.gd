extends RefCounted
## Shared presentation tokens for armory, title, settings, research and forge.
const DARK := Color("0b1820e8")
const RAISED := Color("132a34f2")
const EDGE := Color("38616b")
const CYAN := Color("79d3e2")
const GOLD := Color("e0bd78")

static func panel_style(padding := 10, accent: Color = CYAN) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = DARK; box.border_color = EDGE
	box.set_border_width_all(1); box.border_width_left = 2
	box.border_color = accent.darkened(0.25)
	box.set_corner_radius_all(2); box.set_content_margin_all(padding)
	return box

static func button_style(state: String, padding := 8) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = RAISED if state in ["hover", "pressed", "focus"] else DARK
	box.border_color = GOLD if state == "pressed" else CYAN if state in ["hover", "focus"] else EDGE
	box.set_border_width_all(1); box.border_width_bottom = 2 if state == "pressed" else 1
	box.set_corner_radius_all(2); box.set_content_margin_all(padding)
	return box

static func style_button(button: Button, size := 14) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, button_style(state))
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", Color("dbe7e4"))
	button.add_theme_color_override("font_hover_color", CYAN)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_disabled_color", Color("668087"))

static func apply_tree(node: Node) -> void:
	if node is Button: style_button(node, int(node.get_theme_font_size("font_size")))
	elif node is PanelContainer: node.add_theme_stylebox_override("panel", panel_style())
	for child in node.get_children(): apply_tree(child)
