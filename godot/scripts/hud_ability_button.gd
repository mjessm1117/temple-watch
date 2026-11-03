extends Button
## Drawn action glyphs keep the battle bar independent of imported artwork.
var ability_id := ""
var display_name := ""
var hotkey := ""
var cost := ""
var cooldown := 0
var active := false

static func name_layout(value: String, button_width: float) -> Dictionary:
	var font := ThemeDB.fallback_font
	var available := button_width - 49.0
	for font_size in [11, 10, 9]:
		if font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= available:
			return {"lines": [value], "size": font_size}
	var words := value.split(" ")
	var best: Array[String] = [value]
	var best_width := INF
	for split_at in range(1, words.size()):
		var first := " ".join(words.slice(0, split_at))
		var second := " ".join(words.slice(split_at))
		var widest := maxf(font.get_string_size(first, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x, font.get_string_size(second, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x)
		if widest < best_width: best_width = widest; best = [first, second]
	return {"lines": best, "size": 9}

func configure(id: String, name: String, key: String, ap_cost: String, turns: int, reason: String, is_active: bool = false) -> void:
	ability_id = id
	display_name = name
	hotkey = key
	cost = ap_cost
	cooldown = turns
	active = is_active
	disabled = reason != ""
	tooltip_text = "%s · %s AP%s" % [name, cost, " · cooldown %d" % turns if turns > 0 else ""]
	if reason != "": tooltip_text += " · " + reason
	text = ""
	queue_redraw()

func _draw() -> void:
	var gold := Color("f5d68b") if active else Color("b69b65") if not disabled else Color("67737d")
	var blue := Color("7ecde7") if not disabled else Color("67737d")
	draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), Color("111d29"), true)
	draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), gold, false, 2.0 if active else 1.0)
	draw_rect(Rect2(6, 5, 19, 17), Color("30404b"), true)
	draw_string(ThemeDB.fallback_font, Vector2(9, 18), hotkey, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	var c := Vector2(29, size.y * 0.55)
	var layout := name_layout(display_name, size.x)
	var lines: Array = layout.lines
	for i in range(lines.size()):
		draw_string(ThemeDB.fallback_font, Vector2(44, 30 if lines.size() == 1 else 23 + i * 12), str(lines[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(layout.size), Color("edf3f4") if not disabled else Color("87919b"))
	draw_string(ThemeDB.fallback_font, Vector2(44, 51), "%s AP" % cost, HORIZONTAL_ALIGNMENT_LEFT, size.x - 47, 12, gold)
	match ability_id:
		"move":
			draw_line(c + Vector2(-9, 7), c + Vector2(7, -7), blue, 3)
			draw_polyline(PackedVector2Array([c + Vector2(-1,-7),c + Vector2(7,-7),c + Vector2(7,1)]), blue, 3)
		"shoot", "overwatch":
			draw_arc(c, 10, 0, TAU, 20, blue, 2)
			draw_line(c + Vector2(-13,0), c + Vector2(13,0), blue, 2)
			draw_line(c + Vector2(0,-13), c + Vector2(0,13), blue, 2)
		"hunker":
			draw_colored_polygon(PackedVector2Array([c+Vector2(-10,-9),c+Vector2(10,-9),c+Vector2(8,6),c+Vector2(0,12),c+Vector2(-8,6)]), blue)
		"strike", "push":
			draw_line(c + Vector2(-9,9), c + Vector2(9,-9), blue, 3)
			draw_line(c + Vector2(-7,-7), c + Vector2(7,7), blue, 2)
		_:
			draw_arc(c, 10, 0, TAU, 4, blue, 2)
			draw_circle(c, 3, gold)
	if cooldown > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02,0.04,0.07,0.68), true)
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 30, 20), str(cooldown), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("f0d287"))
