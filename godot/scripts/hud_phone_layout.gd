extends RefCounted
## Battle HUD coordinates are phone CSS points after Window.content_scale_factor.
const ACTION_MIN_SIZE := Vector2(56, 56)

static func place(control: Control, box: Rect2) -> void:
	control.anchor_left = 0.0; control.anchor_right = 0.0
	control.anchor_top = 0.0; control.anchor_bottom = 0.0
	control.offset_left = box.position.x; control.offset_top = box.position.y
	control.offset_right = box.end.x; control.offset_bottom = box.end.y

static func boxes(size: Vector2) -> Dictionary:
	var w := size.x
	var h := size.y
	var portrait := h > w
	if portrait:
		var plate_y := h - 226.0
		return {
			"header": Rect2(0, 0, w, 76),
			"plate": Rect2(8, plate_y, w - 16, 68),
			"tray": Rect2(8, h - 150, w - 16, 68),
			"end": Rect2(w - 136, h - 74, 128, 66),
			"camera": Rect2(w - 52, 100, 44, 156),
			"map": Rect2(8, 100, w - 68, maxf(0, plate_y - 108)),
		}
	var card_width := 180.0 if w < 620.0 else clampf(w * 0.24, 220, 246)
	var end_width := 108.0 if w < 620.0 else 124.0
	var tray_left := card_width + 24.0
	var end_x := w - end_width - 8.0
	return {
		"header": Rect2(0, 0, w, 52),
		"plate": Rect2(8, h - 68, card_width, 68),
		"tray": Rect2(tray_left, h - 64, maxf(120, end_x - tray_left - 8), 64),
		"end": Rect2(end_x, h - 68, end_width, 68),
		"camera": Rect2(w - 52, 62, 44, 156),
		"map": Rect2(8, 76, w - 68, maxf(0, h - 160)),
	}
