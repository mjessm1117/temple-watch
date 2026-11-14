extends RefCounted
## Replace the repeated evacuation tile rings with one named destination on phones.
const Maps = preload("res://scripts/map_catalog.gd")
const Shot = preload("res://scripts/shot.gd")

static func apply(game: Node, label: Label3D) -> int:
	if not is_instance_valid(game) or not is_instance_valid(game.get("mission")) or game.get("hud_controls") == null or game.hud_controls.phone == null:
		label.visible = false
		return 0
	var spec: Variant = game.mission.get("spec")
	if not spec is Dictionary or spec.get("evac", []).is_empty() or str(game.mission.objective_state.get("phase", "primary")) != "evac":
		label.visible = false
		return 0
	if label.visible and Time.get_ticks_msec() - int(label.get_meta("w33d_refresh", 0)) < 180:
		return int(label.get_meta("w33d_hidden", 0))
	var art: Node = game.terrain.get_child(0) if game.terrain.get_child_count() > 0 else null
	if art == null or art.get("marker_root") == null or art.get("palette") == null:
		label.visible = false
		return 0
	var palette: Dictionary = art.get("palette")
	var marker_root: Node3D = art.get("marker_root")
	var evac_material: Material = palette.get("evac")
	var hidden := 0
	for child in marker_root.get_children():
		if child is MultiMeshInstance3D and child.material_override == evac_material:
			child.visible = false
			hidden += 1
	var tile: Vector2i = Maps.point(spec.evac[0])
	var allies: Array = game.mission.living("player")
	var best := -INF
	var chosen := Vector3(tile.x, Shot.elevation(game.mission,tile)*0.7+2.6, tile.y)
	var viewport_size: Vector2 = game.get_viewport().get_visible_rect().size
	for point in spec.evac:
		tile = Maps.point(point)
		for radius in [0.0, 0.9, 1.8, 2.4]:
			for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-0.7,-0.7), Vector2(0.7,-0.7), Vector2(-0.7,0.7), Vector2(0.7,0.7)]:
				var at := Vector3(tile.x + direction.x*radius, Shot.elevation(game.mission,tile)*0.7+2.6, tile.y + direction.y*radius)
				if not game.mission.in_bounds(Vector2i(roundi(at.x),roundi(at.z))) or game.camera.is_position_behind(at): continue
				var screen: Vector2 = game.camera.unproject_position(at)
				if screen.x < 60 or screen.x > viewport_size.x-60 or screen.y < 64 or screen.y > viewport_size.y-105: continue
				var clearance := INF
				for ally in allies:
					var ally_tile := Vector2i(int(ally.x),int(ally.y))
					var body := Vector3(ally.x,Shot.elevation(game.mission,ally_tile)*0.7+1.2,ally.y)
					clearance = minf(clearance,screen.distance_to(game.camera.unproject_position(body)))
				if clearance > best: best = clearance; chosen = at
	label.position = chosen
	label.visible = true
	label.set_meta("w33d_refresh", Time.get_ticks_msec())
	label.set_meta("w33d_hidden", hidden)
	return hidden
