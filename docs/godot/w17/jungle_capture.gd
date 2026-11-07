extends SceneTree
## Same-tile old/new jungle battle camera comparison.
const Mission = preload("res://scripts/mission.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Combat = preload("res://scripts/combat_mission.gd")
const Batch = preload("res://scripts/map_art_batch.gd")
const SOURCE := {
	"temple":"res://assets/maps/meshy1/cover_half_temple_v3.glb",
	"dock":"res://assets/maps/meshy3/cover_half_dock_v1.glb",
	"plains":"res://assets/maps/meshy3/cover_half_plains_v1.glb",
	"city":"res://assets/maps/meshy2/cover_half_city_v1.glb",
	"ruins":"res://assets/maps/meshy3/cover_half_ruins_v1.glb",
	"caves":"res://assets/maps/meshy3/cover_half_caves_v1.glb"
}
const MISSION := {"temple":"fixture","dock":"rescue","plains":"relay","city":"envoy","ruins":"archive","caves":"r_caves","jungle":"h_grove"}

func _initialize() -> void:
	capture.call_deferred()

func capture() -> void:
	var theme := ""
	var output := ""
	var variant := ""
	var close := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--theme="): theme = arg.trim_prefix("--theme=")
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--variant="): variant = arg.trim_prefix("--variant=")
		if arg == "--close": close = true
	if theme != "jungle" or output.is_empty() or variant not in ["old", "new"]:
		push_error("Need --theme=temple|dock|plains|city|ruins|caves|jungle and --output=path")
		quit(1); return
	var id: String = MISSION[theme]
	var mission_path := "res://data/rescue.json" if id == "fixture" else Maps.resolve(id)
	var game = load("res://scenes/rescue.tscn").instantiate()
	game.cam.free()
	game.set_script(preload("res://scripts/meshy_theme_mission.gd"))
	game.review_source = Combat.adopt(Mission.new(17, mission_path))
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_process_unhandled_input(false)
	game.set_process_input(false)
	game.hud.visible = false
	for view in game.views.values(): view.visible = false
	var art = game.terrain.get_child(0)
	var group := Node3D.new()
	game.add_child(group)
	var pair := clear_triple(game.mission)
	var tile: Vector2i = pair[1]
	var position := Vector3(tile.x, 0, tile.y)
	position.y = preload("res://scripts/shot.gd").elevation(game.mission, tile) * 0.7
	if variant == "old":
		add_old_bags(group, position, art.palette.bags)
	else:
		add_fitted_model(group, "res://assets/maps/meshy7/cover_half_jungle_v7.glb", position)
	game.pivot = position
	game.zoom = 5.0 if close else 12.0
	game.pitch = 0.95
	game.yaw = 0.2
	game._update_camera()
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(output)
	print("W16 JUNGLE CAPTURE %s %s %s" % [theme, image.get_size(), error])
	quit(0 if error == OK else 1)

func clear_triple(mission: RefCounted) -> Array[Vector2i]:
	var best := INF
	var result: Array[Vector2i] = []
	var center := Vector2(float(mission.spec.width) * 0.5, float(mission.spec.height) * 0.5)
	for y in range(3, int(mission.spec.height) - 3):
		for x in range(3, int(mission.spec.width) - 9):
			var left := Vector2i(x, y)
			var mid := Vector2i(x + 3, y)
			var right := Vector2i(x + 6, y)
			if not clear_neighborhood(mission, left) or not clear_neighborhood(mission, mid) or not clear_neighborhood(mission, right): continue
			if preload("res://scripts/shot.gd").elevation(mission, left) != preload("res://scripts/shot.gd").elevation(mission, mid) or preload("res://scripts/shot.gd").elevation(mission, left) != preload("res://scripts/shot.gd").elevation(mission, right): continue
			var distance := Vector2(x + 3.0, y).distance_squared_to(center)
			if distance < best:
				best = distance
				result = [left, mid, right]
	if result.is_empty():
		push_error("No clear tile triple for capture")
		return [Vector2i(5, 5), Vector2i(8, 5), Vector2i(11, 5)]
	return result

func clear_neighborhood(mission: RefCounted, tile: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var neighbor := tile + Vector2i(dx, dy)
			if not mission.passable(neighbor) or mission.tile(neighbor) != ".": return false
	return true

func add_fitted_model(parent: Node3D, path: String, at: Vector3) -> void:
	var instance: Node3D = load(path).instantiate()
	parent.add_child(instance)
	var parts: Array = []
	Batch.new().collect(instance, Transform3D.IDENTITY, parts)
	var bounds := AABB()
	var first := true
	for part in parts:
		var box: AABB = part.transform * part.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var factor := 0.96 / maxf(bounds.size.x, bounds.size.z)
	instance.scale = Vector3(factor, 0.8 / bounds.size.y, factor)
	instance.position = at - Vector3(bounds.get_center().x * factor, bounds.position.y * instance.scale.y, bounds.get_center().z * factor)

func add_old_bags(parent: Node3D, at: Vector3, material: Material) -> void:
	var shape: Mesh = Batch.new().shapes.rock
	for row in 3:
		for col in 3:
			var bag := MeshInstance3D.new()
			bag.mesh = shape
			bag.material_override = material
			bag.scale = Vector3(0.34, 0.26, 0.61)
			bag.position = at + Vector3((col - 1) * 0.29, 0.13 + row * 0.23, 0)
			parent.add_child(bag)
