extends RefCounted
## Phone battle geometry. Controls stay over the full-size map viewport.
const ACTION_MIN_SIZE := Vector2(44, 44)

static func place(control: Control, box: Rect2) -> void:
	control.anchor_left = 0.0; control.anchor_right = 0.0
	control.anchor_top = 0.0; control.anchor_bottom = 0.0
	control.offset_left = box.position.x; control.offset_top = box.position.y
	control.offset_right = box.end.x; control.offset_bottom = box.end.y

static func boxes(size: Vector2) -> Dictionary:
	var width := size.x
	var physical := preload("res://scripts/phone_layout.gd").window_size()
	var scale := width / float(physical.x) if physical.x > 0 else 1.0
	var short := width / scale < 750.0
	var portrait := size.y > size.x
	if portrait:
		return {
			"header": Rect2(0, 0, width, 44),
			"plate": Rect2(8, 74, minf(width - 72, 224), 70),
			"tray": Rect2(8, size.y - 88, width - 16, 84),
			"camera": Rect2(width - 56, 290, 48, 144),
			"map": Rect2(0, 44, width, size.y - 44),
		}
	var plate_width := maxf(190.0 if short else 216.0, (230.0 if short else 260.0) * scale)
	var height := (70.0 if short else 76.0) * scale
	var tray_left := maxf(plate_width + maxf(14.0, 11.0 * scale) + 3.0 * scale, width - 505.0 * scale)
	var tray_right := width - 4.0 * scale
	return {
		"header": Rect2(0, 0, width, 44),
		"plate": Rect2(15 * scale, size.y - height - scale, plate_width, height),
		"tray": Rect2(tray_left, size.y - height - scale, tray_right - tray_left, height),
		"camera": Rect2(width - 56, 60, 48, 144),
		"portrait": Rect2(8 * scale, 52, 60, 60),
		"map": Rect2(0, 44, width, size.y - 44),
	}
