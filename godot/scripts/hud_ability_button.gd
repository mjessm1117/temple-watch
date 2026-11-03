extends Button
## Drawn action glyphs keep the battle bar independent of imported artwork.
var ability_id := ""
var display_name := ""
var hotkey := ""
var cost := ""
var cooldown := 0
var active := false

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
	draw_string(ThemeDB.fallback_font, Vector2(44, 30), display_name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 47, 11, Color("edf3f4") if not disabled else Color("87919b"))
	draw_string(ThemeDB.fallback_font, Vector2(44, 49), "%s AP" % cost, HORIZONTAL_ALIGNMENT_LEFT, size.x - 47, 12, gold)
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
