extends RefCounted
## Replace the repeated evacuation tile rings with one named destination on phones.
const Maps = preload("res://scripts/map_catalog.gd")
const Shot = preload("res://scripts/shot.gd")

static func apply(game: Node, label: Label3D) -> int:
	if not is_instance_valid(game) or not is_instance_valid(game.get("mission")) or game.get("hud_controls") == null or game.hud_controls.phone == null:
		label.visible = false
		return 0
	var spec: Variant = game.mission.get("spec")
	if not spec is Dictionary or spec.get("evac", []).is_empty():
		label.visible = false
		return 0
	var art: Node = game.terrain.get_child(0) if game.terrain.get_child_count() > 0 else null
	if art == null or art.get("marker_root") == null or art.get("palette") == null: return 0
	var palette: Dictionary = art.get("palette")
	var marker_root: Node3D = art.get("marker_root")
	var evac_material: Material = palette.get("evac")
	var hidden := 0
	for child in marker_root.get_children():
		if child is MultiMeshInstance3D and child.material_override == evac_material:
			child.visible = false
			hidden += 1
	var tile: Vector2i = Maps.point(spec.evac[0])
	label.position = Vector3(tile.x, Shot.elevation(game.mission, tile) * 0.7 + 1.0, tile.y)
	label.visible = true
	return hidden
