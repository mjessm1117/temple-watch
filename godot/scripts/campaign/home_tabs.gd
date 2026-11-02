extends RefCounted
const UI = preload("res://scripts/campaign/ui.gd")
const Icon = preload("res://scripts/campaign/home_tab_icon.gd")

static func decorate(button: Button, name: String) -> void:
	button.name = "Tab_" + name
	button.text = "     " + name
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 14)
	var glyph := Icon.new(); glyph.name = "Icon"; glyph.kind = name
	glyph.anchor_top = 0.5; glyph.anchor_bottom = 0.5
	glyph.offset_left = 10; glyph.offset_right = 28
	glyph.offset_top = -9; glyph.offset_bottom = 9
	button.add_child(glyph)
	var badge := Label.new(); badge.name = "Badge"; badge.visible = false
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color("091116"))
	var chip := StyleBoxFlat.new(); chip.bg_color = UI.GOLD; chip.set_corner_radius_all(8)
	badge.add_theme_stylebox_override("normal", chip)
	badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_left = -23; badge.offset_right = -5; badge.offset_top = 2; badge.offset_bottom = 18
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(badge)

static func update(buttons: Dictionary, badges: Dictionary, page: String, opened: bool) -> void:
	for name in buttons:
		var button: Button = buttons[name]
		var active: bool = opened and name == ("Command" if page in ["Council", "Settings"] else page)
		button.button_pressed = active
		for state in ["normal", "hover", "pressed", "focus"]:
			var fill := Color("263b40") if active else Color("101d22")
			var border := UI.GOLD if active else UI.BORDER
			if state == "hover": fill = fill.lightened(0.14)
			var style := UI.style(fill, border); style.set_content_margin_all(9)
			if active: style.border_width_bottom = 3
			button.add_theme_stylebox_override(state, style)
		var icon: Control = button.get_node("Icon")
		icon.ink = UI.GOLD if active else UI.MUTED; icon.queue_redraw()
		var badge: Label = button.get_node("Badge")
		badge.visible = badges.has(name)
		if badge.visible:
			badge.text = str(mini(9, int(badges[name].count))) + ("+" if int(badges[name].count) > 9 else "")
			button.tooltip_text = str(badges[name].why)
		else: button.tooltip_text = "Open " + str(name)
