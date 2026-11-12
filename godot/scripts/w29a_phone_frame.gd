extends RefCounted
## Keep the selected soldier's visible body inside the unobstructed phone map.
static func unit_bounds(g: Node) -> Rect2:
	var unit: Dictionary = g.mission.unit_by_id(g.selected_id)
	if unit.is_empty() or g.camera.is_position_behind(Vector3(unit.x, 1.0, unit.y)): return Rect2()
	var rules: Script = load("res://scripts/shot.gd")
	var floor_y: float = float(rules.call("elevation", g.mission, Vector2i(int(unit.x), int(unit.y)))) * 0.7 if rules != null and rules.has_method("elevation") else 0.0
	var feet: Vector2 = g.camera.unproject_position(Vector3(unit.x, floor_y, unit.y))
	var head: Vector2 = g.camera.unproject_position(Vector3(unit.x, floor_y + 1.9, unit.y))
	return Rect2(Vector2(minf(feet.x, head.x) - 18.0, minf(feet.y, head.y) - 8.0), Vector2(absf(feet.x - head.x) + 36.0, absf(feet.y - head.y) + 16.0))

static func frame(g: Node, safe: Rect2) -> void:
	if not safe.has_area() or g.cinematic or g.mission == null: return
	var unit: Dictionary = g.mission.unit_by_id(g.selected_id)
	if unit.is_empty(): return
	if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
	var target := safe.grow(-12.0)
	for step in 3:
		var bounds := unit_bounds(g)
		if bounds.has_area() and target.encloses(bounds): return
		var desired := target.get_center()
		var from: Vector3 = g.cam._ground_at28(bounds.get_center()) if bounds.has_area() else Vector3(unit.x, 0, unit.y)
		var to: Vector3 = g.cam._ground_at28(desired)
		g.pivot += from - to
		g._update_camera()
