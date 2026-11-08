extends SceneTree
## Deterministic battle captures and renderer counts.
const InputControls = preload("res://scripts/input_controls.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var phone := "--phone" in args
	var phase := "before" if "--before" in args else "after"
	var view := "impact" if "--impact" in args else "aim" if "--aim" in args else "overhead" if "--overhead" in args else "tactical"
	var theme := "temple"
	for arg in args:
		if arg.begins_with("--theme="): theme = arg.trim_prefix("--theme=")
	var size := Vector2i(844, 390) if phone else Vector2i(1366, 768)
	root.borderless = true; root.unresizable = true
	root.size = size; root.content_scale_size = size
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.set_process(false)
	if theme != str(game.mission.spec.get("theme", "temple")):
		game.mission.spec.theme = theme
		game._build_terrain()
	var actor: Dictionary = {}
	for unit in game.mission.living("player"):
		if "shoot" in unit.get("kit", []): actor = unit; break
	if actor.is_empty(): quit(2); return
	game._select(int(actor.id))
	if view in ["aim", "impact"]:
		var nearby: Dictionary = game.mission.paths(actor, 3)
		for tile in nearby.costs:
			if int(nearby.costs[tile]) == 3:
				var enemy: Dictionary = game.mission.living("enemy")[0]
				enemy.x = tile.x; enemy.y = tile.y; enemy.awake = true; enemy.spotted = true
				break
		game._refresh_figures()
		game.action = "shoot"
		var options: Array[Dictionary] = InputControls.valid_targets(game.mission, actor, "shoot")
		if options.is_empty(): quit(3); return
		game.target_id = int(options[0].id)
		game._frame_target(); game._refresh()
	if game.camera_tween != null and game.camera_tween.is_running(): game.camera_tween.kill()
	if view == "overhead": game.zoom = 44.0
	game._update_camera()
	for i in range(24): await process_frame
	if view == "tactical":
		var squad: Array = game.mission.living("player")
		var center := Vector3.ZERO
		for unit in squad: center += Vector3(float(unit.x), 0.0, float(unit.y))
		game.pivot = center / float(squad.size())
		game._update_camera()
	game.phase_banner.hide()
	game.hud_controls.night.phase_plate.hide()
	if view == "impact":
		game.animate_headless = true
		print("CINE15 PRE FIRE action_camera=%s target=%d" % [game.action_camera, game.target_id])
		game._attack(game.target_id, "shoot")
		await create_timer(0.91).timeout
		print("CINE15 MID FIRE pending=%s cinematic=%s trace=%s" % [game.player_attack_pending, game.cinematic, game.cam.trace])
	await RenderingServer.frame_post_draw
	var label := "%s-%s-%s-%s" % [phase, "phone-low" if phone else "desktop-medium" if "--medium" in args else "desktop-high", theme, view]
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave16-cam-" + label + ".png")
	if "--intfix" in args: path = ProjectSettings.globalize_path("res://../docs/godot/shots/w16-intfix-" + ("phone-low" if phone else "desktop-high") + "-" + view + ".png")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result := root.get_texture().get_image().save_png(path)
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var triangles := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("CINE15 CAPTURE %s result=%s draws=%d triangles=%d" % [label, error_string(result), draws, triangles])
	# W19's readable phone action captions add two canvas draw batches.
	var ceiling := 103 if view == "aim" else 126 if view == "impact" else 91 if theme == "snow" else 87 if theme in ["city", "temple"] else 85
	quit(0 if result == OK and ("--ceiling" not in args or not phone or draws <= ceiling) else 1)
