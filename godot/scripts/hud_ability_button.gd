extends Button
## Drawn action glyphs keep the battle bar independent of imported artwork.
var ability_id := ""
var display_name := ""
var hotkey := ""
var cost := ""
var cooldown := 0
var active := false
var compact := false
var phone_icon := false
var chain_marks: Array[Dictionary] = []
var combo_ready := false

static func phone_badge_rect(button_size: Vector2) -> Rect2:
	return Rect2(button_size.x - 30, 0, 30, 14)

static func phone_label_rect(button_size: Vector2) -> Rect2:
	return Rect2(1, button_size.y - 12, button_size.x - 2, 12)

func _ready() -> void:
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

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

func set_chain(def: Dictionary, target: Dictionary) -> void:
	chain_marks.clear(); combo_ready = false
	var chain: Dictionary = def.get("chain", {})
	for kind in ["consume", "apply"]:
		for entry in chain.get(kind, []):
			var tag := str(entry.get("tag", "")) if entry is Dictionary else str(entry)
			if tag == "": continue
			chain_marks.append({"tag": tag, "consume": kind == "consume"})
			if kind == "consume" and target.get("combo_tags", {}).has(tag): combo_ready = true
	queue_redraw()

func _draw() -> void:
	if phone_icon and bool(get_meta("shared_phone_art", false)): return
	var gold := Color("f5d68b") if active else Color("b69b65") if not disabled else Color("67737d")
	var blue := Color("7ecde7") if not disabled else Color("67737d")
	var touch_down := compact and button_pressed
	if phone_icon:
		draw_arc(Vector2(size.x * 0.5, 18), 15, 0, TAU, 32, Color("9ef6b3") if combo_ready else gold, 2.5)
		var caption := display_name.to_upper()
		if caption.length() > 7: caption = caption.substr(0, 6) + "…"
		draw_string(ThemeDB.fallback_font, Vector2(1, 39), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x - 2, 10, Color("edf3f4") if not disabled else Color("87919b"))
		var badge := "%s AP" % cost
		if cooldown > 0: badge = "%d CD" % cooldown
		var badge_rect := phone_badge_rect(size)
		draw_rect(badge_rect, Color("10212d"), true)
		draw_rect(badge_rect, gold, false, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 30, 11), badge, HORIZONTAL_ALIGNMENT_CENTER, 30, 11, Color("f9e5b8"))
	else:
		draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), Color("32566b") if touch_down else Color("111d29"), true)
		draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), Color("9ef6b3") if combo_ready else Color("f5d68b") if touch_down else gold, false, 3.0 if combo_ready or touch_down else 2.0 if active else 1.0)
	var c := Vector2(size.x * 0.5, minf(25.0, size.y * 0.35)) if compact else Vector2(29, size.y * 0.55)
	if compact and not phone_icon:
		var font := ThemeDB.fallback_font
		var lines: Array[String] = [display_name]
		var font_size := 14
		if font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > size.x - 6:
			var words := display_name.split(" ")
			var best_width := INF
			for split_at in range(1, words.size()):
				var first := " ".join(words.slice(0, split_at))
				var second := " ".join(words.slice(split_at))
				var widest := maxf(font.get_string_size(first, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, font.get_string_size(second, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
				if widest < best_width: best_width = widest; lines = [first, second]
			while font_size > 12 and best_width > size.x - 6:
				font_size -= 1
				best_width = 0.0
				for line in lines: best_width = maxf(best_width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		for i in range(lines.size()):
			draw_string(font, Vector2(3, 47.0 if lines.size() == 1 else 38.0 + i * 14.0), lines[i], HORIZONTAL_ALIGNMENT_CENTER, size.x - 6, font_size, Color("edf3f4") if not disabled else Color("87919b"))
	elif not phone_icon:
		draw_rect(Rect2(6, 5, 19, 17), Color("30404b"), true)
		draw_string(ThemeDB.fallback_font, Vector2(9, 18), hotkey, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		var layout := name_layout(display_name, size.x)
		var lines: Array = layout.lines
		for i in range(lines.size()):
			draw_string(ThemeDB.fallback_font, Vector2(44, 30 if lines.size() == 1 else 23 + i * 12), str(lines[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(layout.size), Color("edf3f4") if not disabled else Color("87919b"))
		draw_string(ThemeDB.fallback_font, Vector2(44, 51), "%s AP" % cost, HORIZONTAL_ALIGNMENT_LEFT, size.x - 47, 12, gold)
	if phone_icon:
		var glyphs := {"move":"➜", "shoot":"◎", "overwatch":"⌖", "hunker":"⬟", "strike":"⚔", "push":"⇥", "reload":"↻"}
		draw_string(ThemeDB.fallback_font, Vector2(2, 28), str(glyphs.get(ability_id, "✦")), HORIZONTAL_ALIGNMENT_CENTER, size.x - 4, 18, blue)
	else:
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
	if cooldown > 0 and not phone_icon:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02,0.04,0.07,0.68), true)
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 30, 20), str(cooldown), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("f0d287"))
	for i in range(mini(chain_marks.size(), 3)):
		var mark: Dictionary = chain_marks[i]
		var at := Vector2(size.x - 10.0 - i * 15.0, 11.0)
		var color := Color(preload("res://scripts/hud18_icon.gd").COLORS.get(str(mark.tag), "dcebf0"))
		draw_circle(at, 7.0, Color("10212d"))
		draw_arc(at, 7.0, 0, TAU, 12, color, 1.5)
		var glyph: String = preload("res://scripts/hud18_icon.gd").GLYPHS.get(str(mark.tag), "•")
		draw_string(ThemeDB.fallback_font, at + Vector2(-4, 4), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
