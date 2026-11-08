extends RefCounted
## Phone battle geometry. Controls stay over the full-size map viewport.

static func place(control: Control, box: Rect2) -> void:
	control.anchor_left = 0.0; control.anchor_right = 0.0
	control.anchor_top = 0.0; control.anchor_bottom = 0.0
	control.offset_left = box.position.x; control.offset_top = box.position.y
	control.offset_right = box.end.x; control.offset_bottom = box.end.y

static func boxes(size: Vector2) -> Dictionary:
	var width := size.x
	var tree := Engine.get_main_loop() as SceneTree
	var physical := tree.root.content_scale_size if tree != null else DisplayServer.window_get_size()
	var scale := width / float(physical.x) if physical.x > 0 else 1.0
	var short := width / scale < 750.0
	var plate_width := (230.0 if short else 260.0) * scale
	var height := (70.0 if short else 76.0) * scale
	var tray_left := plate_width + 11.0 * scale
	var tray_right := width - 4.0 * scale
	return {
		"header": Rect2(0, 0, width, 44),
		"plate": Rect2(3 * scale, size.y - height - scale, plate_width, height),
		"tray": Rect2(tray_left, size.y - height - scale, tray_right - tray_left, height),
		"camera": Rect2(width - 48, 104, 44, 132),
		"map": Rect2(0, 44, width, size.y - 44),
	}
