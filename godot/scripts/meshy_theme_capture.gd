extends "res://scripts/map_preview.gd"
## Real missions, default cameras, HUD and Compatibility render counters; no saves.
var measurements: Array = []

func run() -> void:
	Settings.difficulty = "normal"
	root.borderless = true; root.unresizable = true
	root.min_size = Vector2i(1920,1080); root.size = Vector2i(1920,1080); root.position = Vector2i(0,0)
	root.content_scale_size = Vector2i(1920,1080)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var args := OS.get_cmdline_user_args()
	var ids: Array = Maps.manifest().missions.keys()
	for path in Maps.manifest().web_variants: ids.append(str(path).get_file().trim_suffix(".json"))
	ids.append("fixture")
	if "--one" in args: ids = [args[args.find("--one")+1]]
	var busiest: Dictionary = {}
	for id in ids:
		await show_battle(str(id)); lock_camera()
		await create_timer(0.5).timeout
		var sample := await measure(str(id),60)
		measurements.append(sample)
		var theme := str(sample.theme)
		if not busiest.has(theme) or sample.tris > busiest[theme].tris: busiest[theme] = sample
		game.queue_free(); await process_frame
	var output := FileAccess.open("/tmp/meshyint-survey-one.json" if "--one" in args else "/tmp/meshyint-survey.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(measurements,"  ")); output.close()
	for sample in busiest.values():
		await show_battle(str(sample.id)); lock_camera()
		await create_timer(2.0).timeout
		var measured := await measure(str(sample.id),600)
		print("MESHY BUDGET ",JSON.stringify(measured))
		await save_shot(str(sample.theme))
		var records: Array = game.terrain.get_child(0).batch.records
		var selected: Dictionary = {}
		# Prefer a full cover with half cover nearby, both in an actual mission.
		var best := INF
		for record in records:
			if record.role != "cover" or record.kind != "#" or not record.has("meshy_path"): continue
			for half in records:
				if half.role != "cover" or half.kind not in ["c","h"]: continue
				var distance: float = Vector2(record.tile).distance_to(Vector2(half.tile))
				if distance < best: best = distance; selected = record
		if selected.is_empty():
			for record in records:
				if record.role == "cover" and record.has("meshy_path"): selected = record; break
		if not selected.is_empty():
			await close_to(selected,7.0)
			await save_shot(str(sample.theme)+"-close")
		game.queue_free(); await process_frame
	if "--one" not in args:
		for pair in [["terminal","archive","hack_terminal"],["relay","relay","defend"],["charge","sabotage","sabotage"],["beacon","escort","evac"],["restraint","rescue","prisoner"]]:
			await show_battle(pair[1]); lock_camera(); await create_timer(1.0).timeout
			for record in game.terrain.get_child(0).batch.records:
				if record.role == "objective" and record.kind == pair[2] and (record.has("meshy_path") or pair[0] == "terminal"):
					await close_to(record,4.5 if pair[0] != "beacon" else 3.2)
					await save_shot("obj-"+pair[0]); break
			game.queue_free(); await process_frame
	game = null
	for i in 5: await process_frame
	quit(1 if failures else 0)

func measure(id: String, frames: int) -> Dictionary:
	var times: Array[float] = []; var tris := 0; var draws := 0; var total_draws := 0; var total_primitives := 0
	var previous := Time.get_ticks_usec()
	for i in frames:
		await process_frame
		var now := Time.get_ticks_usec(); times.append(float(now-previous)/1000.0); previous = now
		tris = maxi(tris,RenderingServer.viewport_get_render_info(root.get_viewport_rid(),RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME))
		draws = maxi(draws,RenderingServer.viewport_get_render_info(root.get_viewport_rid(),RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME))
		total_draws = maxi(total_draws,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		total_primitives = maxi(total_primitives,int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	var sum := 0.0
	for ms in times: sum += ms
	times.sort()

	var sample := {"id":id,"theme":str(game.mission.spec.get("theme","temple")),"tris":tris,"draws":draws,"total_draws":total_draws,"total_primitives":total_primitives,"fps":1000.0*frames/sum,"p95_ms":times[int(frames*0.95)],"zoom":game.zoom,"frames":frames,"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name()}
	if tris > 300000 or total_draws > 150:
		failures += 1; push_error("Phone budget exceeded: "+id)
	print("MESHY SAMPLE ",JSON.stringify(sample))
	return sample

func close_to(record: Dictionary, distance: float) -> void:
	var target := Vector3(record.tile.x,float(record.floor)+0.5,record.tile.y)
	game.cinematic = true
	if game.camera_tween: game.camera_tween.kill()
	if game.action_tween: game.action_tween.kill()
	game.camera.position = target+Vector3(0.3,0.8,1.0).normalized()*distance
	game.camera.look_at(target)
	await create_timer(0.5).timeout

func save_shot(label: String) -> void:
	game.scene_view.arrange_labels()
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	if picture.get_size() != Vector2i(1920,1080):
		failures += 1; push_error("Expected native 1920x1080 capture"); return
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/meshyint-%s.png" % label)
	if picture.save_png(path) != OK: failures += 1
	print("MESHY SHOT ",path)

func lock_camera() -> void:
	# Keep gameplay overlays on; the review scene suppresses only unattended camera input.
	game.cinematic = false
	Input.warp_mouse(Vector2(960,40))
	game.pivot = Vector3(float(game.mission.spec.width)*0.5,0,float(game.mission.spec.height)*0.5) if game.mission.modern else Vector3(9,0,17)
	game._update_camera(); game.camera.make_current()
	game.hovered = Vector2i(-1,-1); game.preview_tile = Vector2i(-1,-1); game._refresh()

func show_battle(id: String) -> void:
	var path := "res://data/rescue.json" if id == "fixture" else "res://data/maps/%s.json" % id if id.begins_with("web_") else Maps.resolve(id)
	game = load("res://scenes/rescue.tscn").instantiate()
	game.cam.free() # The original script constructs this unattached Node at instantiation.
	game.set_script(preload("res://scripts/meshy_theme_mission.gd"))
	game.review_source = Combat.adopt(Mission.new(17,path))
	root.add_child(game)
	game.set_process_unhandled_input(false); game.set_process_input(false)
	Input.warp_mouse(Vector2(960,40))
	await process_frame
	print("ART WINDOW: ",DisplayServer.window_get_size()," viewport ",root.get_visible_rect().size)
