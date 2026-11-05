extends SceneTree
## Deterministic Low-tier battle captures and render counts.
const InputControls = preload("res://scripts/input_controls.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var phone := "--phone" in args
	var tactical := "--tactical" in args
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
	if not tactical:
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
	await RenderingServer.frame_post_draw
	var name := "wave14-battle-%s-%s-%s.png" % [phase, "tactical" if tactical else "aim", "phone" if phone else "desktop"]
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/" + name)
	var result := root.get_texture().get_image().save_png(path)
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var triangles := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("BATTLE14 CAPTURE %s: %s draws=%d triangles=%d" % [name, error_string(result), draws, triangles])
	if not tactical:
		var sight: Control = game.hud_controls.aim_ui.sight
		print("BATTLE14 SIGHT visible=%s size=%s source=%s target=%s" % [sight.visible, sight.size, sight.source_point, sight.target_point])
		if phone: print("BATTLE14 HUD aim_y=%s tray_y=%s header_y=%s" % [game.hud_controls.aim_ui.panel.get_global_rect().position.y, game.hud_controls.phone.ability_tray.get_global_rect().position.y, game.hud_controls.phone.overlay.get_child(0).get_global_rect().end.y])
	quit(0 if result == OK else 1)
