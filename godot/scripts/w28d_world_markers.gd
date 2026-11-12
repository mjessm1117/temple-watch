extends RefCounted
## Shrink world markers to small head pips and keep crowded pips off the top strip.
static func update(game, hud) -> void:
	if not game.has_meta("w28d_hold_shrunk"):
		for node in game.find_children("*", "Label3D", true, false):
			if node.text == "HOLD ZONE":
				node.pixel_size = 0.0009
				node.font_size = 12
		game.set_meta("w28d_hold_shrunk", true)
	var occupied: Array[Rect2] = []
	var ids: Array = game.views.keys()
	ids.sort_custom(func(a, b): return a == game.selected_id or (b != game.selected_id and int(a) < int(b)))
	var map: Rect2 = hud.hud_safe_rect28()
	for id in ids:
		var view = game.views[id]
		if view.status_label != null: view.status_label.hide()
		if view.side_badge26 == null: continue
		var pip: Sprite3D = view.side_badge26
		pip.pixel_size = 0.0035
		pip.position = Vector3(-0.06, 2.18, 0)
		var point: Vector2 = game.camera.unproject_position(view.global_position + Vector3.UP * 2.18)
		var box := Rect2(point - Vector2(12, 7), Vector2(24, 14))
		var free := map.has_point(point)
		for used in occupied:
			if used.intersects(box): free = false; break
		pip.visible = free
		if free: occupied.append(box)
