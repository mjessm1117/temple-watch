extends SceneTree
## Battle camera, aim-light, and actual Jedi kill sequence coverage.
const InputControls = preload("res://scripts/input_controls.gd")
const Killcam = preload("res://scripts/battle16_killcam.gd")
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
	game.animate_headless = true
	game.set_process(false)
	game.action_camera = true
	var actor: Dictionary = {}
	for unit in game.mission.living("player"):
		if str(unit.get("model", "")) == "jedi" and "strike" in unit.get("kit", []): actor = unit; break
	check(not actor.is_empty(), "named Jedi striker exists")
	var enemy: Dictionary = game.mission.living("enemy")[0]
	var routes: Dictionary = game.mission.paths(actor, 2)
	var found := false
	for tile in routes.costs:
		if int(routes.costs[tile]) != 1: continue
		enemy.x = tile.x; enemy.y = tile.y; enemy.awake = true; enemy.spotted = true
		if not InputControls.valid_targets(game.mission, actor, "strike").is_empty(): found = true; break
	check(found, "adjacent legal strike target")
	enemy.hp = 1
	actor.aim = 200
	actor.damage = [20, 20]
	game.mission.rng.seed = 7
	game._refresh_figures()
	game._select(int(actor.id))
	game.action = "strike"
	game.target_id = int(enemy.id)
	game._frame_target(); game._refresh()
	await process_frame
	return game

func wait_trace(game: Node3D, marker: String, seconds: float) -> bool:
	var start := Time.get_ticks_msec()
	while not marker in game.cam.trace and Time.get_ticks_msec() - start < int(seconds * 1000.0):
		await process_frame
	return marker in game.cam.trace

func wait_done(game: Node3D, seconds: float) -> bool:
	var start := Time.get_ticks_msec()
	while game.player_attack_pending and Time.get_ticks_msec() - start < int(seconds * 1000.0):
		await process_frame
	return not game.player_attack_pending

func run() -> void:
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	var medium := "--medium" in OS.get_cmdline_user_args()
	var game := await fixture()
	check(is_equal_approx(game.pitch, deg_to_rad(53.0)), "opening pitch is 53 degrees")
	check(is_equal_approx(game.yaw, PI / 4.0), "opening yaw is three-quarter")
	check(game.zoom <= 10.5, "phone starts close to the squad")
	game.cam.end_preview()
	game.zoom = 44.0
	for i in range(4): await process_frame
	check(game.pitch >= deg_to_rad(76.0), "zoom-out reaches overhead view")
	game.zoom = 10.0
	for i in range(4): await process_frame
	check(absf(game.pitch - deg_to_rad(53.0)) < 0.02, "zoom-in restores tactical pitch")
	var old_yaw: float = game.yaw
	game._rotate_camera(PI / 2.0)
	if game.camera_tween != null: game.camera_tween.custom_step(0.29)
	check(absf(angle_difference(old_yaw, game.yaw) - PI / 2.0) < 0.02, "Q/E turn remains 90 degrees")
	game._refresh()
	var light: Node = game.hud_controls.aim_ui.lighting
	if medium:
		check(light.key != null and light.rim != null, "Medium has key and rim")
		check(light.key.shadow_enabled and light.key.shadow_blur > 1.0, "Medium key has soft shadow")
		for i in range(3): await process_frame
		check(game.camera.attributes is CameraAttributesPractical and game.camera.attributes.dof_blur_far_enabled, "Medium keeps far DOF")
	else:
		check(light.key != null and light.rim == null, "Low uses one aim light")
		check(light.key != null and not light.key.shadow_enabled, "Low aim has no shadow")
		check(light.rimmed.size() >= 2, "Low rim material covers shooter and target")
		check(light.sun_energy > game.scene_view.sun.light_energy, "Low aim dims ambient battle light")
		check(game.camera.attributes == null or not game.camera.attributes.dof_blur_far_enabled, "Low aim has no DOF")
	var event := {"actor": game.selected_id, "to": Vector2i(game.mission.unit_by_id(game.target_id).x, game.mission.unit_by_id(game.target_id).y), "killed": true}
	check(Killcam.eligible(game, event), "Jedi killing blow is eligible")
	game.action_camera = false
	check(not Killcam.eligible(game, event), "Cinematics Off suppresses close-up")
	game.action_camera = true
	if not medium:
		var enemy_id: int = game.target_id
		game._attack(enemy_id, "strike")
		check(await wait_trace(game, "jedi_killcam_close", 5.0), "actual Jedi kill reaches close-up")
		check(await wait_done(game, 2.0), "close-up returns to tactical")
		check("jedi_killcam_return" in game.cam.trace and not game.cinematic, "camera returns after kill")
		check(light.sun_energy < 0.0 and light.key == null, "aim light resets after attack")
		game.queue_free()
		for i in range(3): await process_frame
		game = await fixture()
		game._attack(game.target_id, "strike")
		check(await wait_trace(game, "jedi_killcam_close", 5.0), "second kill reaches close-up")
		game.cam.skip()
		check(await wait_done(game, 1.0), "skip ends close-up promptly")
		check("jedi_killcam_skipped" in game.cam.trace and not game.cinematic, "skip restores tactical camera")
	game.queue_free()
	print("CAM16 %s RESULTS: %d checks, %d failures" % ["MEDIUM" if medium else "LOW", checks, failures])
	quit(1 if failures else 0)
