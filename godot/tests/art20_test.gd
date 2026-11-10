extends SceneTree
## W20 art budgets and reproducible normal-distance evidence.
const JEDI := ["kira", "tor", "satele", "ressa", "kell", "sava", "tem"]
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func arg(key: String, fallback := "") -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with(key + "="): return value.get_slice("=",1)
	return fallback

func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error("ART20 FAIL " + message)
	else: print("ART20 PASS " + message)

func glb_triangles(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	file.seek(12); var json_size := file.get_32(); file.seek(20)
	var doc: Dictionary = JSON.parse_string(file.get_buffer(json_size).get_string_from_utf8())
	var count := 0
	for mesh in doc.meshes:
		for surface in mesh.primitives:
			if surface.has("indices"): count += int(doc.accessors[int(surface.indices)].count) / 3
	return count

func triangles(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D and node.mesh:
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			count += (arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX].size() else arrays[Mesh.ARRAY_VERTEX].size()) / 3
	for child in node.get_children(): count += triangles(child)
	return count

func run() -> void:
	var mode := arg("--mode", "test")
	var dimensions := arg("--size","844x390").split("x")
	root.size = Vector2i(int(dimensions[0]),int(dimensions[1])); root.content_scale_size = root.size
	preload("res://scripts/phone_layout.gd").test_scale = float(arg("--dpr","1"))
	if mode == "hero":
		await hero(); return
	if mode == "map":
		await map_capture(); return
	for id in JEDI:
		var path := "res://assets/characters/jedi/%s/%s.glb" % [id,id]
		var scene := load(path) as PackedScene
		check(scene != null, id + " loads")
		if scene == null: continue
		var actor := scene.instantiate(); root.add_child(actor)
		var count := triangles(actor)
		print("ART20 TRI unit ",id," ",count)
		check(count <= 15000,id + " <= 15K tris")
		actor.queue_free(); await process_frame
		var import_text := FileAccess.get_file_as_string(path + ".import")
		check("meshes/generate_lods=false" in import_text,id + " close LOD disabled")
		check("meshes/force_disable_compression=true" in import_text,id + " mesh lossless")
		var file := FileAccess.open(path, FileAccess.READ)
		file.seek(12); var json_size := file.get_32(); file.seek(20)
		var gltf: Dictionary = JSON.parse_string(file.get_buffer(json_size).get_string_from_utf8())
		check(gltf.images[0].mimeType == "image/png",id + " atlas lossless PNG")
		var texture_import := FileAccess.get_file_as_string("res://assets/characters/jedi/%s/%s_Image_0.webp.import" % [id,id])
		check("compress/mode=0" in texture_import,id + " external texture lossless")
	for group in ["w17", "w19"]:
		for filename in DirAccess.get_files_at("res://assets/units/" + group):
			if not filename.ends_with(".glb") or filename.ends_with("_lod1.glb"): continue
			var scene := load("res://assets/units/%s/%s" % [group, filename]) as PackedScene
			if scene == null: continue
			var unit := scene.instantiate(); root.add_child(unit)
			var count := triangles(unit)
			check(count <= 15000,group + "/" + filename + " <= 15K tris")
			unit.queue_free(); await process_frame
	for name in ["crate","terminal"]:
		var scene := load("res://assets/models/props/%s.glb" % name) as PackedScene
		if scene == null: continue
		var prop := scene.instantiate(); root.add_child(prop)
		var count := triangles(prop)
		print("ART20 TRI prop ",name," ",count)
		check(count <= 3000,name + " <= 3K tris")
		prop.queue_free(); await process_frame
	var folders := ["res://assets/maps"]
	while not folders.is_empty():
		var folder: String = folders.pop_back()
		for subfolder in DirAccess.get_directories_at(folder): folders.append(folder + "/" + subfolder)
		for filename in DirAccess.get_files_at(folder):
			if filename.ends_with(".glb"):
				check(glb_triangles(folder + "/" + filename) <= 3000,folder + "/" + filename + " <= 3K tris")
	var graphics := root.get_node("Graphics")
	graphics.requested = "low"; graphics.effective = "low"
	var game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(game)
	await process_frame
	check(game.terrain.get_child_count() > 0,"Low battle loads")
	for i in 6: await process_frame
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	print("ART20 DRAWS low ",draws)
	check(draws <= 48,"Low draw calls <= fbc2447 baseline")
	game.queue_free(); await process_frame
	print("ART20 RESULT failures=",failures)
	quit(0 if failures == 0 else 1)

func map_capture() -> void:
	var theme := arg("--theme","temple")
	var game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(game)
	await process_frame
	game.demo_mode = true; game.set_process(false)
	game.mission.spec["theme"] = theme
	game.terrain_seen_revision = -1
	game.pivot = Vector3(12.5,0,11.0); game.zoom = 17.0
	game.pitch = 0.95; game.yaw = 0.2
	game._refresh(); game._update_camera(); game.hud.visible = false
	for i in 6: await process_frame
	var error := root.get_texture().get_image().save_png(arg("--output"))
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	print("ART20 MAP ",theme," draws=",draws," save=",error)
	if DisplayServer.get_name() != "headless":
		check(draws <= int({"temple":23,"dock":26,"jungle":29}.get(theme,9999)),theme + " draw calls <= fbc2447 baseline")
	quit(0 if error == OK and failures == 0 else 1)

func hero() -> void:
	var model = load("res://assets/characters/jedi/kira/kira.glb").instantiate()
	root.add_child(model)
	var camera := Camera3D.new(); root.add_child(camera)
	camera.position = Vector3(0,1.45,1.25); camera.look_at(Vector3(0,1.35,0)); camera.current = true
	var world := WorldEnvironment.new(); root.add_child(world)
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color("293e4c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color("a9c6d0"); env.ambient_light_energy = 0.9
	world.environment = env
	var key := DirectionalLight3D.new(); key.rotation_degrees = Vector3(-45,-35,0); key.light_energy = 1.3; key.light_color = Color("ffe4b6"); root.add_child(key)
	for i in 8: await process_frame
	var error := root.get_texture().get_image().save_png(arg("--output"))
	print("ART20 HERO tris=",triangles(model)," draws=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)," save=",error)
	quit(0 if error == OK else 1)
