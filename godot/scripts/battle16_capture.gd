extends SceneTree
## Render three frames from a real Jedi killing blow at native window size.
const InputControls = preload("res://scripts/input_controls.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var phone := "--phone" in OS.get_cmdline_user_args()
	var size := Vector2i(844, 390) if phone else Vector2i(1366, 768)
	root.borderless = true; root.unresizable = true
	root.size = size; root.content_scale_size = size
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.animate_headless = true
	game.set_process(false)
	game.action_camera = true
	var actor: Dictionary = {}
	for unit in game.mission.living("player"):
		if str(unit.get("model", "")) == "jedi" and "strike" in unit.get("kit", []): actor = unit; break
	if actor.is_empty(): push_error("No Jedi striker"); quit(2); return
	var enemy: Dictionary = game.mission.living("enemy")[0]
	var found := false
	for tile in game.mission.paths(actor, 2).costs:
		if int(game.mission.paths(actor, 2).costs[tile]) != 1: continue
		enemy.x = tile.x; enemy.y = tile.y; enemy.awake = true; enemy.spotted = true
		if not InputControls.valid_targets(game.mission, actor, "strike").is_empty(): found = true; break
	if not found: push_error("No legal Jedi strike target"); quit(3); return
	enemy.hp = 1
	actor.aim = 200
	actor.damage = [20, 20]
	game.mission.rng.seed = 7
	game._refresh_figures()
	game._select(int(actor.id))
	game.action = "strike"
	game.target_id = int(enemy.id)
	game._frame_target(); game._refresh()
	if game.camera_tween != null and game.camera_tween.is_running(): game.camera_tween.kill()
	game._update_camera()
	for i in range(12): await process_frame
	game.phase_banner.hide()
	game.hud_controls.night.phase_plate.hide()
	game._attack(int(enemy.id), "strike")
	var start := Time.get_ticks_msec()
	while not "jedi_killcam_start" in game.cam.trace and Time.get_ticks_msec() - start < 5000:
		await process_frame
	if not "jedi_killcam_start" in game.cam.trace:
		push_error("Jedi killing blow did not start close-up: %s" % str(game.cam.trace)); quit(4); return
	var prefix := "phone-low" if phone else "desktop-high"
	for index in range(3):
		await create_timer(0.04 if index == 0 else 0.12 if index == 1 else 0.22).timeout
		await RenderingServer.frame_post_draw
		var path := ProjectSettings.globalize_path("res://../docs/godot/shots/w16-intfix-%s-kill-%d.png" % [prefix, index + 1])
		var result := root.get_texture().get_image().save_png(path)
		var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var triangles := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		print("CAM16 KILL %s frame=%d result=%s draws=%d triangles=%d" % [prefix, index + 1, error_string(result), draws, triangles])
		if result != OK: quit(5); return
	while game.player_attack_pending and Time.get_ticks_msec() - start < 6000: await process_frame
	print("CAM16 KILL trace=%s pending=%s" % [game.cam.trace, game.player_attack_pending])
	quit(0 if not game.player_attack_pending and "jedi_killcam_return" in game.cam.trace else 6)
