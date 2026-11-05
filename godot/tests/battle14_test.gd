extends SceneTree
## Battle composition and presentation checks at the phone and desktop sizes.
const InputControls = preload("res://scripts/input_controls.gd")
const Shot = preload("res://scripts/shot.gd")
const Quality = preload("res://scripts/graphics_settings.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func body_bounds(game, unit: Dictionary) -> Rect2:
	var at: Vector3 = game.views[int(unit.id)].global_position
	var bounds := Rect2()
	var first := true
	for x in [-0.3, 0.3]:
		for y in [0.2, 1.85]:
			for z in [-0.3, 0.3]:
				var screen: Vector2 = game.camera.unproject_position(at + Vector3(x, y, z))
				if first: bounds = Rect2(screen, Vector2.ZERO); first = false
				else: bounds = bounds.expand(screen)
	return bounds

func check_tactical(game, unit: Dictionary, size: Vector2i, label: String) -> void:
	var bounds := body_bounds(game, unit)
	var center := bounds.get_center()
	check(center.x >= size.x * 0.2 and center.x <= size.x * 0.8 and center.y >= size.y * 0.2 and center.y <= size.y * 0.8, label + " selected unit in middle 60%: " + str(center))
	check(bounds.size.y >= 40.0, label + " selected unit at least 40 px tall: " + str(bounds.size.y))
	check(bounds.position.y > 55 and bounds.end.y < 305, label + " selected unit clears phone HUD")

func run() -> void:
	check(Quality.effective_tier("high", "gl_compatibility") == "low", "Compatibility remains Low")
	for size in [Vector2i(844, 390), Vector2i(1366, 768)]: await exercise(size)
	print("BATTLE14 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func exercise(size: Vector2i) -> void:
	DisplayServer.window_set_size(size)
	root.size = size
	root.content_scale_size = size
	await process_frame
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.set_process(false)
	var phone := size.x < 1000
	if phone:
		var first: Dictionary = game.mission.unit_by_id(game.selected_id)
		check_tactical(game, first, size, "phone start")
		var squad: Array[Dictionary] = game.mission.living("player")
		if squad.size() > 1:
			game._select(int(squad[1].id))
			if game.camera_tween != null and game.camera_tween.is_running(): game.camera_tween.kill()
			game.pivot = Vector3(squad[1].x, 0, squad[1].y)
			game.zoom = preload("res://scripts/battle11_camera.gd").selected_zoom(game.mission)
			game._update_camera()
			check_tactical(game, squad[1], size, "phone second")
	var actor: Dictionary = {}
	for unit in game.mission.living("player"):
		if "shoot" in unit.get("kit", []): actor = unit; break
	check(not actor.is_empty(), "shooter exists at %s" % size)
	if actor.is_empty(): game.queue_free(); return
	game._select(int(actor.id))
	if game.camera_tween != null and game.camera_tween.is_running(): game.camera_tween.kill()
	game.pivot = Vector3(actor.x, 0, actor.y)
	game.zoom = preload("res://scripts/battle11_camera.gd").selected_zoom(game.mission)
	game._update_camera()
	if phone:
		var cover_visible := false
		for y in range(game.mission.spec.height):
			for x in range(game.mission.spec.width):
				if Shot.cover(game.mission, Vector2i(x, y), Vector2i(x + 2, y)) <= 0: continue
				var screen: Vector2 = game.camera.unproject_position(Vector3(x, 0.5, y))
				if screen.x > 0 and screen.x < size.x and screen.y > 60 and screen.y < 290: cover_visible = true
		check(cover_visible, "phone tactical camera shows nearby cover")
	var nearby: Dictionary = game.mission.paths(actor, 3)
	for tile in nearby.costs:
		if int(nearby.costs[tile]) == 1:
			var enemy: Dictionary = game.mission.living("enemy")[0]
			enemy.x = tile.x; enemy.y = tile.y; enemy.awake = true; enemy.spotted = true
			break
	game._refresh_figures()
	game.action = "shoot"
	var options: Array[Dictionary] = InputControls.valid_targets(game.mission, actor, "shoot")
	check(not options.is_empty(), "shoot target exists at %s" % size)
	if options.is_empty(): game.queue_free(); return
	game.target_id = int(options[0].id)
	game._frame_target(); game._refresh()
	for i in range(35): await process_frame
	var target: Dictionary = game.mission.unit_by_id(game.target_id)
	var aim = game.hud_controls.aim_ui
	var viewport := Rect2(Vector2.ZERO, Vector2(size))
	var shooter_bounds := body_bounds(game, actor)
	var target_bounds := body_bounds(game, target)
	check(aim.panel.visible and viewport.encloses(aim.panel.get_global_rect()), "aim card fits at %s" % size)
	check(not shooter_bounds.intersects(target_bounds), "aim silhouettes separate at %s" % size)
	check(aim.sight.visible and aim.sight.source_point.distance_to(aim.sight.target_point) > 25.0, "reticle and sightline connect units at %s" % size)
	check(game.views[int(actor.id)].aim_ready, "shooter takes a ready pose at %s" % size)
	check(aim.confirm.text.contains("HIT") and aim.confirm.text.contains("DMG"), "fire, hit chance and damage remain visible at %s" % size)
	check(not game.scene_view.world.environment.ssao_enabled and not game.scene_view.sun.shadow_enabled, "Low lighting and post settings unchanged at %s" % size)
	if phone:
		check(shooter_bounds.size.y >= 55 and target_bounds.size.y >= 55, "both phone units are at least 55 px tall")
		check(not game.hud_controls.phone.ability_tray.visible, "phone action tray folds during aim")
		check(game.cam.preview_shoulder != null and game.cam.preview_shoulder.visible and not game.views[int(actor.id)].model.visible, "foreground shooter shoulder fills the phone aim view")
	else:
		check(not game.hud_controls.desktop_bottom.visible, "desktop action tray folds during aim")
		check(aim.panel.get_global_rect().get_area() <= float(size.x * size.y) * 0.25, "desktop aim HUD uses at most a quarter of the screen")
	for ally in game.mission.living("player"):
		if int(ally.id) != int(actor.id): check(not game.views[int(ally.id)].visible, "nearby allies clear the aim view")
	var from: Vector3 = game.views[int(actor.id)].global_position + Vector3.UP
	var to: Vector3 = game.views[int(target.id)].global_position + Vector3.UP
	var fx_children: int = game.fx.get_child_count()
	game.fx.bolt(from, to, false, true)
	game.fx.float_text(to, "MISS", Color.WHITE)
	check(game.fx.get_child_count() > fx_children, "bolt, miss whiff and shot read spawn")
	game._cancel_order()
	check(not aim.sight.visible and not game.views[int(actor.id)].aim_ready, "cancel clears sight and ready pose")
	if phone: check(game.cam.preview_shoulder == null and game.views[int(actor.id)].model.visible, "cancel restores the original shooter model")
	for ally in game.mission.living("player"):
		check(game.views[int(ally.id)].visible, "allies return after aim")
	var fov: float = game.camera.fov
	game.cam.impact_beat(to)
	await create_timer(0.14).timeout
	check(game.cam.beat_tween != null and game.cam.beat_tween.is_running(), "kill or crit camera beat starts")
	if phone:
		var press := InputEventScreenTouch.new()
		press.index = 0; press.position = Vector2(400, 150); press.pressed = true
		game.cam.touch.handle(press)
		var release := InputEventScreenTouch.new()
		release.index = 0; release.position = press.position; release.pressed = false
		game.cam.touch.handle(release)
	else: game.cam.skip()
	await process_frame
	check(game.cam.skip_requested and is_equal_approx(game.camera.fov, fov), "tap skip restores camera FOV")
	game.queue_free()
	for i in range(3): await process_frame
