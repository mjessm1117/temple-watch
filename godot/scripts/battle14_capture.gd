extends SceneTree
## Deterministic Low-tier battle captures and render counts.
const InputControls = preload("res://scripts/input_controls.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var phone := "--phone" in args
	var tactical := "--tactical" in args
	var start := "--start" in args
	var second := "--second" in args
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
	if second:
		var squad: Array[Dictionary] = game.mission.living("player")
		if squad.size() > 1:
			game._select(int(squad[1].id))
			game.pivot = Vector3(squad[1].x, 0, squad[1].y)
			game.zoom = preload("res://scripts/battle11_camera.gd").selected_zoom(game.mission)
	elif not start: game._select(int(actor.id))
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
	if game.camera_tween != null and game.camera_tween.is_running(): game.camera_tween.kill()
	game._update_camera()
	for i in range(8): await process_frame
	game.phase_banner.hide()
	game.hud_controls.night.phase_plate.hide()
	game.hud_controls.night.phase_plate.modulate.a = 0.0
	for i in range(12): await process_frame
	if tactical and second:
		var selected_unit: Dictionary = game.mission.unit_by_id(game.selected_id)
		game.pivot = Vector3(selected_unit.x, 0, selected_unit.y)
		game.zoom = preload("res://scripts/battle11_camera.gd").selected_zoom(game.mission)
		game._update_camera()
		await process_frame
	await RenderingServer.frame_post_draw
	var name := "%s-tactical-%s.png" % ["phone" if phone else "desktop", "second" if second else "start" if start else "selected"] if tactical else "wave14-battle-%s-aim-%s.png" % [phase, "phone" if phone else "desktop"]
	var path := ProjectSettings.globalize_path("res://../docs/godot/w14/intfix/" + name)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result := root.get_texture().get_image().save_png(path)
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var triangles := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("BATTLE14 CAPTURE %s: %s draws=%d triangles=%d" % [name, error_string(result), draws, triangles])
	if tactical:
		var selected: Dictionary = game.mission.unit_by_id(game.selected_id)
		var at: Vector3 = game.views[int(selected.id)].global_position
		var feet: Vector2 = game.camera.unproject_position(at + Vector3(0, 0.2, 0))
		var head: Vector2 = game.camera.unproject_position(at + Vector3(0, 1.85, 0))
		print("TACTICAL UNIT id=%d center=%s height=%.1f at=%s pivot=%s camera=%s" % [int(selected.id), (feet + head) * 0.5, feet.distance_to(head), at, game.pivot, game.camera.position])
	if not tactical:
		var sight: Control = game.hud_controls.aim_ui.sight
		print("BATTLE14 SIGHT visible=%s size=%s source=%s target=%s" % [sight.visible, sight.size, sight.source_point, sight.target_point])
		if phone: print("BATTLE14 HUD aim_y=%s tray_y=%s header_y=%s" % [game.hud_controls.aim_ui.panel.get_global_rect().position.y, game.hud_controls.phone.ability_tray.get_global_rect().position.y, game.hud_controls.phone.overlay.get_child(0).get_global_rect().end.y])
	quit(0 if result == OK else 1)
