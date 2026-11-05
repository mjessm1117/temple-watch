extends SceneTree
## Wave 15 cinematic behavior and Low budget checks.
const InputControls = preload("res://scripts/input_controls.gd")
const Prefs = preload("res://scripts/campaign/strat_preferences.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func fixture() -> Node3D:
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.set_process(false)
	game.animate_headless = true
	var actor: Dictionary = {}
	for unit in game.mission.living("player"):
		if "shoot" in unit.get("kit", []): actor = unit; break
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
	if options.is_empty(): return game
	game.target_id = int(options[0].id)
	game._frame_target(); game._refresh()
	await process_frame
	return game

func wait_done(game: Node3D, seconds: float) -> bool:
	var start := Time.get_ticks_msec()
	while game.player_attack_pending and Time.get_ticks_msec() - start < int(seconds * 1000.0):
		await process_frame
	return not game.player_attack_pending

func run() -> void:
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	if "--medium" in OS.get_cmdline_user_args():
		var medium_game := await fixture()
		for i in range(4): await process_frame
		var medium_pool: Node = medium_game.get_node_or_null("Cine15PropPools")
		check(medium_pool != null and medium_pool.find_children("*", "OmniLight3D", true, false).size() == 2, "Medium uses two prop lamps")
		check(medium_game.hud_controls.aim_ui.lighting.key != null and medium_game.hud_controls.aim_ui.lighting.rim != null, "Medium aim has key and rim lights")
		check(medium_game.hud_controls.aim_ui.lighting.vignette != null, "Medium aim has vignette")
		check(medium_game.camera.attributes is CameraAttributesPractical and medium_game.camera.attributes.dof_blur_far_enabled, "Medium aim has far DOF")
		medium_game.queue_free()
		print("CINE15 MEDIUM RESULTS: %d checks, %d failures" % [checks, failures])
		quit(1 if failures else 0)
		return
	Prefs.set_value("cine", true)
	var game := await fixture()
	check(game.target_id >= 0, "fixture has a target")
	var pool: Node = game.get_node_or_null("Cine15PropPools")
	check(pool != null, "theme lighting pool exists")
	if pool != null:
		check(pool.find_children("*", "MeshInstance3D", true, false).size() <= 2, "Low uses at most two pool decals")
		check(pool.find_children("*", "OmniLight3D", true, false).is_empty(), "Low adds no prop lights")
	check(game.hud_controls.aim_ui.lighting.background_tint != null, "Low aim has background tint")
	check(game.hud_controls.aim_ui.lighting.vignette == null, "Low aim has no vignette")
	check(game.camera.attributes == null or not game.camera.attributes.dof_blur_far_enabled, "Low aim has no DOF")
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	if draws > 0: check(draws <= 103, "Low phone aim draws <= 103: %d" % draws)
	else: check(pool != null and pool.get_child_count() <= 2, "headless Low scene stays within three added meshes")
	if DisplayServer.get_name() == "headless":
		for view in ["aim", "tactical"]:
			var output: Array = []
			var command := PackedStringArray(["-a", OS.get_executable_path(), "--path", ProjectSettings.globalize_path("res://"), "--rendering-method", "gl_compatibility", "-s", "scripts/cine15_capture.gd", "--", "--after", "--phone", "--" + view, "--theme=temple", "--ceiling"])
			var status := OS.execute("xvfb-run", command, output, true)
			check(status == 0, "rendered Low phone %s draw ceiling: %s" % [view, str(output)])
	var start := Time.get_ticks_msec()
	game._attack(game.target_id, "shoot")
	await process_frame
	check(game.player_attack_pending and "camera_start" in game.cam.trace, "fire starts cinematic")
	check(await wait_done(game, 1.9), "cinematic returns to tactical within 2 seconds")
	check(not game.cinematic and game.action == "move", "fire ends in tactical")
	var shot_ms := Time.get_ticks_msec() - start
	check(shot_ms >= 800 and shot_ms <= 1600, "shot beat lasts 0.8–1.6 seconds: %d ms" % shot_ms)
	game.queue_free()
	for i in range(3): await process_frame

	game = await fixture()
	game._attack(game.target_id, "shoot")
	await process_frame
	game.cam.skip()
	check(await wait_done(game, 1.0), "tap skip ends shot")
	check(game.cam.skip_requested and not game.cinematic, "skip restores camera")
	game.queue_free()
	for i in range(3): await process_frame

	game = await fixture()
	game.hud_controls.aim_ui._toggle_cine()
	check(not game.action_camera and not bool(Prefs.get_value("cine")), "setting persists off")
	game._attack(game.target_id, "shoot")
	check(await wait_done(game, 1.0), "off completes shot")
	check(not "camera_start" in game.cam.trace and not game.cinematic, "off creates no camera beat")
	game.queue_free()
	Prefs.set_value("cine", true)
	print("CINE15 TEST RESULTS: %d checks, %d failures, shot=%d ms, headless draws=%d" % [checks, failures, shot_ms, draws])
	quit(1 if failures else 0)
