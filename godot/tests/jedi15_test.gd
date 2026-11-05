extends SceneTree
## Named Jedi library contract and optional native battle captures.

const Lookup = preload("res://scripts/characters/jedi_models.gd")
const IDS := ["kira", "tor", "satele", "ressa", "kell", "sava", "tem"]
const MAX_TRIS := 5910
const MAX_BYTES := 3983745
const ROOT := "res://assets/characters/jedi/"
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(value: bool, reason: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(reason)

func find_type(node: Node, kind: String) -> Node:
	if node.is_class(kind): return node
	for child in node.get_children():
		var found := find_type(child, kind)
		if found != null: return found
	return null

func count_tris(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D and node.mesh != null:
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			count += (indices.size() if indices.size() > 0 else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	for child in node.get_children(): count += count_tris(child)
	return count

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if "--capture-before" in args or "--capture-after" in args:
		await capture("before" if "--capture-before" in args else "after")
		quit(1 if failures else 0)
		return
	var manifest_path := ROOT + "manifest.json"
	check(FileAccess.file_exists(manifest_path), "manifest exists")
	if not FileAccess.file_exists(manifest_path): quit(1); return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	var entries: Array = manifest.get("jedi", [])
	check(entries.size() == 7, "seven manifest entries")
	if "--pck" in args:
		for id in IDS:
			var packed_path: String = ROOT + str(id) + "/" + str(id) + ".glb"
			check(ResourceLoader.exists(packed_path), str(id) + " exported scene")
			if ResourceLoader.exists(packed_path): check(load(packed_path) is PackedScene, str(id) + " exported load")
		print("jedi15 pck: %d checks, %d failures" % [checks, failures])
		quit(1 if failures else 0)
		return
	var hashes: Dictionary = {}
	var fallback := load("res://assets/models/units/jedi.glb") as PackedScene
	check(fallback != null, "generic fallback loads")
	for id in IDS:
		var match: Array = entries.filter(func(e): return e.get("id", "") == id)
		check(match.size() == 1, id + " manifest identity")
		if match.size() != 1: continue
		var entry: Dictionary = match[0]
		var path: String = ROOT + str(id) + "/" + str(id) + ".glb"
		var lod: String = ROOT + str(id) + "/" + str(id) + "_lod.glb"
		var preview: String = ROOT + str(id) + "/preview.png"
		check(FileAccess.file_exists(path) and FileAccess.file_exists(lod) and FileAccess.file_exists(preview), id + " files")
		if not FileAccess.file_exists(path): continue
		var bytes := FileAccess.get_file_as_bytes(path).size()
		var hash := FileAccess.get_md5(path)
		check(not hashes.has(hash), id + " unique GLB")
		hashes[hash] = true
		check(bytes <= MAX_BYTES, id + " GLB budget")
		var scene := load(path) as PackedScene
		check(scene != null, id + " scene loads")
		if scene == null: continue
		var model := scene.instantiate()
		root.add_child(model)
		var tris := count_tris(model)
		check(tris <= MAX_TRIS, id + " triangle budget")
		check(int(entry.get("tris", -1)) == tris and int(entry.get("glb_bytes", -1)) == bytes, id + " manifest measurements")
		check(float(entry.get("height_m", 0.0)) > 1.3 and float(entry.get("height_m", 0.0)) < 2.3, id + " height")
		check(str(entry.get("rig", "")) == "UE shared battle clips", id + " rig declaration")
		var skeleton := find_type(model, "Skeleton3D") as Skeleton3D
		check(skeleton != null, id + " skeleton")
		if skeleton:
			for bone in ["pelvis", "spine_01", "hand_r", "thigh_l", "thigh_r"]:
				check(skeleton.find_bone(bone) >= 0, id + " bone " + bone)
		var player := find_type(model, "AnimationPlayer") as AnimationPlayer
		check(player != null, id + " animation player")
		if player:
			for clip in ["idle", "run", "swing"]:
				check(player.has_animation(clip), id + " clip " + clip)
				if player.has_animation(clip): player.play(clip); player.advance(0.08)
		check(entry.has("mesh_task_ids") and entry.has("prompts") and entry.has("credits_spent") and entry.has("saber_color"), id + " provenance")
		model.queue_free()
	check(hashes.size() == 7, "seven distinct GLBs")
	if fallback:
		check(Lookup.scene_for({"name":"Unknown Jedi", "model":"jedi"}, fallback) == fallback, "unknown Jedi fallback")
		check(Lookup.scene_for({"name":"Kira Venn", "model":"trooper"}, fallback) == fallback, "non-Jedi fallback")
		check(Lookup.scene_for_id("missing", fallback) == fallback, "missing file fallback")
	print("jedi15: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func capture(phase: String) -> void:
	var size := root.size
	root.content_scale_size = size
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 18: await process_frame
	var names := ["Kira Venn", "Tor Saalen", "Satele Shan"]
	var players: Array = game.mission.living("player")
	check(players.size() >= 3, "three players available")
	for i in 3:
		players[i].name = names[i]
		players[i].model = "jedi"
		players[i].class_name = "Guardian"
	for view in game.views.values(): view.queue_free()
	game.views.clear()
	await process_frame
	game._refresh()
	game.pivot = Vector3(5.0, 0.0, 22.0)
	game.zoom = 12.0
	game.pitch = 0.7
	game.yaw = 0.3
	game._update_camera()
	for i in 32: await process_frame
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var tris := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	print("JEDI15 PERF %s %s draws=%d triangles=%d" % [phase, size, draws, tris])
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(image.get_size() == size, "native capture size")
		var label := "phone" if size.x == 844 else "desktop"
		var path := "res://../docs/godot/shots/wave15-jedi-%s-%s.png" % [phase, label]
		check(image.save_png(path) == OK, "capture saved")
	game.sound.player.stop(); game.sound.player.stream = null
	game.queue_free()
	print("jedi15 capture: %d checks, %d failures" % [checks, failures])
