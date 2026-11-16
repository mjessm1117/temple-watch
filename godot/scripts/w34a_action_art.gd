extends "res://scripts/hud_phone_action_art.gd"
## Side-by-side icon and full caption for the fixed left action column.

func _draw() -> void:
	var font := preload("res://scripts/campaign/ui.gd").font("body")
	for button in buttons:
		if not button.visible or not button.is_visible_in_tree(): continue
		var at: Vector2 = button.get_global_rect().position - get_global_rect().position
		var gold := Color("f5d68b") if button.active else Color("b69b65") if not button.disabled else Color("67737d")
		var blue := Color("7ecde7") if not button.disabled else Color("67737d")
		var center := at + Vector2(21, 22)
		draw_arc(center, 15, 0, TAU, 28, Color("9ef6b3") if button.combo_ready else gold, 2)
		match button.ability_id:
			"move":
				draw_line(center + Vector2(-9, 6), center + Vector2(8, -5), blue, 2.5)
				draw_polyline(PackedVector2Array([center + Vector2(1, -9), center + Vector2(9, -6), center + Vector2(6, 2)]), blue, 2.5)
			"shoot", "overwatch":
				draw_arc(center, 8, 0, TAU, 20, blue, 2.5)
				draw_line(center + Vector2(-12, 0), center + Vector2(12, 0), blue, 2)
				draw_line(center + Vector2(0, -12), center + Vector2(0, 12), blue, 2)
			"strike", "push": draw_line(center + Vector2(-9, 9), center + Vector2(9, -9), blue, 3)
			_: draw_string(font, center + Vector2(-6, 7), button.display_name.substr(0, 1).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, blue)
		var caption: String = caption_for(button.display_name)
		var font_size := 11
		while font_size > 9 and font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > button.size.x - 44:
			font_size -= 1
		draw_string(font, at + Vector2(43, 29), caption, HORIZONTAL_ALIGNMENT_LEFT, button.size.x - 44, font_size, Color("edf3f4") if not button.disabled else Color("9bb2b5"))
		var pill := StyleBoxFlat.new()
		pill.bg_color = Color("10212d"); pill.border_color = gold
		pill.set_border_width_all(1); pill.set_corner_radius_all(6)
		draw_style_box(pill, Rect2(at + Vector2(button.size.x - 24, 0), Vector2(24, 14)))
		var badge := str(button.cost)
		if button.cooldown > 0: badge = "%d CD" % button.cooldown
		draw_string(font, at + Vector2(button.size.x - 24, 12), badge, HORIZONTAL_ALIGNMENT_CENTER, 24, 11, Color("f9e5b8"))
		for mark in button.chain_marks.slice(0, 1):
			var tag := str(mark.get("tag", ""))
			var tag_color := Color(preload("res://scripts/hud18_icon.gd").COLORS.get(tag, "dcebf0"))
			draw_circle(at + Vector2(7, 8), 7, Color("10212d"))
			draw_arc(at + Vector2(7, 8), 7, 0, TAU, 12, tag_color, 1.5)
			draw_string(font, at + Vector2(3, 12), tag.substr(0, 1).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, tag_color)
		var charges: int = int(button.get_meta("w34a_charges", -1))
		if charges >= 0: draw_string(font, at + Vector2(button.size.x - 24, 41), "×%d" % charges, HORIZONTAL_ALIGNMENT_CENTER, 24, 10, Color("f9e5b8"))
