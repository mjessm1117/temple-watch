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
	var phase := args[0] if args.size() else "before"
	for id in ["fixture", "ilum", "relay"]:
		await show_battle(id); lock_camera()
		await create_timer(1.0).timeout
		measurements.append(await measure(id,60))
		await save_shot(id+"-"+phase)
		var records: Array = game.terrain.get_child(0).batch.records
		for record in records:
			if (id == "relay" and record.role == "objective" and record.kind == "defend") or (id != "relay" and record.role == "cover" and record.kind == "#" and record.has("meshy_path")):
				await close_to(record,5.0)
				await save_shot(id+"-"+phase+"-close")
				break
		game.queue_free(); await process_frame
	var output := FileAccess.open("res://../art/meshy4/budgets-"+phase+".json", FileAccess.WRITE)
	output.store_string(JSON.stringify(measurements,"  ")); output.close()
	game = null
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
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/meshy4-%s.png" % label)
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
