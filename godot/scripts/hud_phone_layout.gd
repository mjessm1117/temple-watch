extends RefCounted
## Phone battle geometry. Controls stay over the full-size map viewport.

static func place(control: Control, box: Rect2) -> void:
	control.anchor_left = 0.0; control.anchor_right = 0.0
	control.anchor_top = 0.0; control.anchor_bottom = 0.0
	control.offset_left = box.position.x; control.offset_top = box.position.y
	control.offset_right = box.end.x; control.offset_bottom = box.end.y

static func boxes(size: Vector2) -> Dictionary:
	var width := size.x
	var plate_width := 250.0
	var tray_left := plate_width + 12.0
	var tray_right := minf(width - 8.0, tray_left + 348.0)
	return {
		"header": Rect2(0, 0, width, 44),
		"plate": Rect2(6, size.y - 92, plate_width, 88),
		"tray": Rect2(tray_left, size.y - 92, tray_right - tray_left, 88),
		"camera": Rect2(width - 48, 104, 44, 132),
		"map": Rect2(0, 44, width, size.y - 44),
	}
