extends SceneTree
## Reproducible before/after aim captures at the two supported sizes.
const InputControls = preload("res://scripts/input_controls.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var phone := "--phone" in args
	var phase := "before" if "--before" in args else "after"
	var size := Vector2i(844, 390) if phone else Vector2i(1366, 768)
	root.borderless = true
	root.unresizable = true
	root.size = size
	root.content_scale_size = size
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.set_process(false)
	var actor: Dictionary = {}
	for unit in game.mission.living("player"):
		if "shoot" in unit.get("kit", []): actor = unit; break
	if actor.is_empty(): quit(2); return
	game._select(int(actor.id))
	var nearby: Dictionary = game.mission.paths(actor, 3)
	for tile in nearby.costs:
		if int(nearby.costs[tile]) == 1:
			var enemy: Dictionary = game.mission.living("enemy")[0]
			enemy.x = tile.x; enemy.y = tile.y; enemy.awake = true; enemy.spotted = true
			break
	game._refresh_figures()
	game.action = "shoot"
	var options: Array[Dictionary] = InputControls.valid_targets(game.mission, actor, "shoot")
	if options.is_empty(): quit(3); return
	game.target_id = int(options[0].id)
	game._frame_target()
	game._refresh()
	for i in range(35): await process_frame
	game.phase_banner.hide()
	game.hud_controls.night.phase_plate.hide()
	game.hud_controls.night.phase_plate.modulate.a = 0.0
	for i in range(12): await process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
	var name := "wave13-battle-%s-%s.png" % [phase, "phone" if phone else "desktop"]
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/" + name)
	var result := root.get_texture().get_image().save_png(path)
	print("BATTLE13 CAPTURE %s: %s" % [name, error_string(result)])
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var triangles := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var started := Time.get_ticks_usec()
	for i in range(40): await process_frame
	var frame_ms := float(Time.get_ticks_usec() - started) / 40000.0
	print("BATTLE13 PERF %s: draws=%d triangles=%d frame_ms=%.2f fps_estimate=%.1f" % [name, draws, triangles, frame_ms, 1000.0 / frame_ms])
	quit(0 if result == OK else 1)
