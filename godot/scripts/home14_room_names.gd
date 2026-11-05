extends Control
## One CanvasItem batches the phone cutaway names above the room hit targets.
var buttons: Dictionary

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	if buttons == null: return
	var font := ThemeDB.fallback_font
	var rows := []
	for id in buttons:
		var button: Button = buttons[id]
		if not button.visible: continue
		var words := str(button.get_node("RoomName").text).split(" ")
		var lines := [" ".join(words.slice(0, 1)), " ".join(words.slice(1))] if words.size() > 1 else [words[0]]
		var area := Rect2(button.position + Vector2(1, 1), Vector2(button.size.x - 2, 20 if lines.size() > 1 else 11))
		rows.append({"area": area, "lines": lines, "color": button.get_node("RoomName").get_theme_color("font_color")})
	for row in rows:
		draw_rect(row.area, Color(0.018, 0.045, 0.057, 0.88))
	for row in rows:
		var area: Rect2 = row.area
		var lines: Array = row.lines
		for i in lines.size():
			var line: String = lines[i]
			if line.is_empty(): continue
			var size := 7
			while size > 5 and font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > area.size.x - 2:
				size -= 1
			var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			draw_string(font, Vector2(area.position.x + (area.size.x - width) * 0.5, area.position.y + 7 + i * 9), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, row.color)
