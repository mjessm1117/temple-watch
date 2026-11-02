extends "res://scripts/map_preview.gd"
## Standalone battle benchmark shared verbatim with the pre-tier worktree.

func show_battle(id: String) -> void:
	var source = Mission.new(17, Maps.resolve(id))
	game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	# Let imported textures and the initial scene finish setup before replacing the fixture.
	for i in 4: await process_frame
	game.mission = Combat.adopt(source)
	for view in game.figures.get_children():
		if view.name != "Prisoner": game.figures.remove_child(view); view.queue_free()
	game.views.clear(); game.selected_id = int(game.mission.living("player")[0].id)
	game.hud.queue_free(); game.portrait_viewport.queue_free(); game.portrait_kind = ""; game.action_buttons.clear(); game._build_ui()
	game._build_terrain(); game.terrain_seen_board = game.mission.board.duplicate(); game.terrain_seen_revision = game.mission.terrain_revision
	game.pivot = Vector3(float(game.mission.spec.width)*0.5, 0, float(game.mission.spec.height)*0.5)
	game.zoom = maxf(float(game.mission.spec.width), float(game.mission.spec.height))*1.3
	game.pitch = 0.8; game.yaw = 0.3; game.action_camera = true
	game._update_camera(); game._refresh(); game.scene_view.arrange_labels()
	Input.warp_mouse(Vector2(960,60))
	await process_frame

func run() -> void:
	Settings.difficulty = "normal"
	root.borderless = true; root.unresizable = true
	root.size = Vector2i(1366, 768); root.position = Vector2i(0, 50)
	root.content_scale_size = Vector2i(1366, 768)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await show_battle("cache")
	await create_timer(3.0).timeout
	var times: Array[float] = []
	var draws := 0; var primitives := 0
	var previous := Time.get_ticks_usec()
	for i in 600:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append(float(now - previous) / 1000.0)
		previous = now
		draws = maxi(draws, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		primitives = maxi(primitives, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	var total := 0.0
	for ms in times: total += ms
	times.sort()
	print("GRAPHICS PERF: " + JSON.stringify({"fps_avg":1000.0 / (total / times.size()), "frame_ms_p95":times[int(times.size() * 0.95)], "draw_calls_max":draws, "primitives_max":primitives, "samples":times.size(), "renderer":RenderingServer.get_current_rendering_method(), "adapter":RenderingServer.get_video_adapter_name()}))
	game.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit(1 if failures else 0)
