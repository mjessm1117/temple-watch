extends SceneTree
## Battle-map visual contract and repeatable Low renderer measurements.
const STONE = preload("res://assets/env/stone.gdshader")
const TERRAIN = preload("res://assets/env/terrain.gdshader")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var baseline := "--baseline" in args
	var capture := "--capture" in args
	var graphics: Node = root.get_node("Graphics")
	var low := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	var phase := "before" if baseline else "after"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for size in [Vector2i(844,390), Vector2i(1366,768)]:
		root.size = size
		root.content_scale_size = size
		var game = load("res://scenes/rescue.tscn").instantiate()
		root.add_child(game)
		for i in 12: await process_frame
		graphics.apply_all()
		for i in 8: await process_frame
		var env: Environment = game.scene_view.world.environment
		var art = game.terrain.get_child(0)
		if not baseline:
			check(root.size == size, "viewport fits %s" % size)
			check(game.camera != null and art != null, "battle map exists")
			check(env.fog_enabled, "cheap fog remains enabled")
			check(env.glow_enabled == not low, "Low glow remains disabled")
			check(env.ssao_enabled == (graphics.effective == "high"), "tier SSAO contract unchanged")
			check(env.adjustment_enabled, "theme color grading remains enabled")
			check(game.scene_view.sun.shadow_enabled == not low, "Low shadows remain disabled")
			check(art.palette.floor.shader == TERRAIN and art.palette.wall.shader == STONE, "terrain shaders exist")
			var selected = game.views.get(game.selected_id)
			check(selected != null and selected.get_node_or_null("GfxSelectionRing") != null, "selection marker exists")
			var marker: MeshInstance3D = selected.get_node_or_null("GfxSelectionRing")
			check(marker.visible and marker.mesh is TorusMesh, "selected unit has sharp ring")
			check(marker.mesh.get_aabb().size.x < 1.5 and marker.mesh.get_aabb().size.z < 1.5, "selection marker fits one tile at %s" % size)
			check(art.palette.floor.get_shader_parameter("detail_quality") == (0.0 if low else 1.0), "material detail follows tier")
			check(art.palette.wall.get_shader_parameter("detail_quality") == (0.0 if low else 1.0), "stone detail follows tier")
			check(game.range_highlights.get_child_count() > 0, "move-range grid has source geometry")
			check(game.highlights.get_child_count() > 1 and game.highlights.get_child(1).get_child_count() > 0, "batched range grid exists")
		if capture and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			check(image.get_size() == size, "capture size %s" % size)
			var path := "res://../docs/godot/shots/wave13-gfx-%s-%s-%s.png" % [phase,"low" if low else "high", "phone" if size.x == 844 else "desktop"]
			check(image.save_png(path) == OK, "capture %s" % path)
		if low:
			var start := Time.get_ticks_usec()
			var max_draws := 0
			var max_primitives := 0
			for i in 120:
				await process_frame
				max_draws = maxi(max_draws,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
				max_primitives = maxi(max_primitives,int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
			var fps := 120000000.0 / float(Time.get_ticks_usec() - start)
			print("GFX13 PERF %s %s: %s" % [phase,size,JSON.stringify({"draw_calls_max":max_draws,"triangles_max":max_primitives,"fps_estimate":snappedf(fps,0.1),"adapter":RenderingServer.get_video_adapter_name()})])
			if not baseline and DisplayServer.get_name() != "headless":
				check(max_draws > 0 and max_draws <= (100 if size.x == 844 else 275), "Low draw budget")
				check(max_primitives > 0 and max_primitives <= 300000, "Low triangle budget")
		game.sound.player.stop()
		game.sound.player.stream = null
		game.queue_free()
		await create_timer(0.2).timeout
		for i in 3: await process_frame
	print("gfx13 %s: %d checks, %d failures" % [phase,checks,failures])
	quit(1 if failures else 0)
