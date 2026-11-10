extends Control
## Draw all phone action icons in one canvas item so their shapes and text batch.
const Marks = preload("res://scripts/hud18_icon.gd")
var buttons: Array[Button] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func _draw() -> void:
	var visible_buttons: Array[Button] = []
	var offsets: Array[Vector2] = []
	for button in buttons:
		if not button.visible or not button.is_visible_in_tree(): continue
		visible_buttons.append(button)
		offsets.append(button.get_global_rect().position - get_global_rect().position)
	var font := preload("res://scripts/campaign/ui.gd").font("body")
	# Draw each primitive and font size together across the whole row.
	for index in visible_buttons.size():
		var button = visible_buttons[index]
		var at := offsets[index]
		var gold := Color("f5d68b") if button.active else Color("b69b65") if not button.disabled else Color("67737d")
		draw_arc(at + Vector2(button.size.x * 0.5, 18), 15, 0, TAU, 32, Color("9ef6b3") if button.combo_ready else gold, 2.5)
	for index in visible_buttons.size():
		var button = visible_buttons[index]
		var at := offsets[index]
		var gold := Color("f5d68b") if button.active else Color("b69b65") if not button.disabled else Color("67737d")
		var pill := StyleBoxFlat.new()
		pill.bg_color = Color("10212d"); pill.border_color = gold
		pill.set_border_width_all(1); pill.set_corner_radius_all(7)
		draw_style_box(pill, Rect2(at + Vector2(button.size.x - 30, 0), Vector2(30, 14)))
	for index in visible_buttons.size():
		var button = visible_buttons[index]
		var at := offsets[index]
		for i in range(mini(button.chain_marks.size(), 3)):
			var mark: Dictionary = button.chain_marks[i]
			var center := at + Vector2(button.size.x - 10.0 - i * 15.0, 11.0)
			var color := Color(Marks.COLORS.get(str(mark.tag), "dcebf0"))
			draw_circle(center, 7.0, Color("10212d"))
			draw_arc(center, 7.0, 0, TAU, 12, color, 1.5)
	for index in visible_buttons.size():
		var button = visible_buttons[index]
		var at := offsets[index]
		var badge := "%s AP" % button.cost
		if button.cooldown > 0: badge = "%d CD" % button.cooldown
		draw_string(font, at + Vector2(button.size.x - 30, 14), badge, HORIZONTAL_ALIGNMENT_CENTER, 30, 14, Color("f9e5b8"))
	for index in visible_buttons.size():
		var button = visible_buttons[index]
		var at := offsets[index]
		var blue := Color("7ecde7") if not button.disabled else Color("67737d")
		var glyphs := {"move":"➜", "shoot":"◎", "overwatch":"⌖", "hunker":"⬟", "strike":"⚔", "push":"⇥", "reload":"↻"}
		if not preload("res://scripts/phone_layout.gd").touch_device():
			draw_string(font, at + Vector2(2, 28), str(glyphs.get(button.ability_id, "✦")), HORIZONTAL_ALIGNMENT_CENTER, button.size.x - 4, 18, blue)
	for index in visible_buttons.size():
		var button = visible_buttons[index]
		var at := offsets[index]
		var caption: String = caption_for(button.display_name)
		while caption.length() > 1 and font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x > button.size.x - 4:
			caption = caption.substr(0, caption.length() - 1)
		draw_string(font, at + Vector2(1, 32 if preload("res://scripts/phone_layout.gd").touch_device() else 39), caption, HORIZONTAL_ALIGNMENT_CENTER, button.size.x - 2, 14, Color("edf3f4") if not button.disabled else Color("9bb2b5"))
	for index in visible_buttons.size():
		var button = visible_buttons[index]
		var at := offsets[index]
		for i in range(mini(button.chain_marks.size(), 3)):
			var mark: Dictionary = button.chain_marks[i]
			var center := at + Vector2(button.size.x - 10.0 - i * 15.0, 11.0)
			var color := Color(Marks.COLORS.get(str(mark.tag), "dcebf0"))
			var glyph: String = str(mark.tag).substr(0, 1) if preload("res://scripts/phone_layout.gd").touch_device() else Marks.GLYPHS.get(str(mark.tag), "•")
			draw_string(font, center + Vector2(-4, 4), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)

static func caption_for(display_name: String) -> String:
	var caption := display_name.to_upper()
	if caption.begins_with("SABER "): return "SABER"
	if caption == "FORCE LEAP": return "LEAP"
	return caption
