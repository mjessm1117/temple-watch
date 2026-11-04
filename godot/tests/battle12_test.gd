extends SceneTree
const CameraRules = preload("res://scripts/battle11_camera.gd")
const InputControls = preload("res://scripts/input_controls.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	root.size = Vector2i(1366, 768)
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game); await process_frame
	game.demo_mode = true
	game.set_process(false)
	var m: RefCounted = game.mission
	check(is_equal_approx(game.zoom, CameraRules.selected_zoom(m)), "selected unit starts close")
	check(CameraRules.selected_zoom(m) <= CameraRules.start_zoom(m) / 2.0, "selected view is at least twice as close")
	check(CameraRules.target_zoom(m, 14.0) > CameraRules.selected_zoom(m), "distant shooter and target fit together")
	check(CameraRules.clamp_zoom(200.0) == 65.0, "manual zoom out remains available")
	check(game.hud_controls.aim_ui != null, "aim strip exists")
	var actor: Dictionary = m.unit_by_id(game.selected_id)
	for ally in m.living("player"):
		if "shoot" in ally.get("kit", []): actor = ally; game.selected_id = int(ally.id); break
	for enemy in m.living("enemy"):
		enemy.awake = true; enemy.spotted = true
	var nearby: Dictionary = m.paths(actor, 3)
	for tile in nearby.costs:
		if int(nearby.costs[tile]) == 1:
			var enemy: Dictionary = m.living("enemy")[0]
			enemy.x = tile.x; enemy.y = tile.y
			break
	var options: Array[Dictionary] = InputControls.valid_targets(m, actor, "shoot")
	if not options.is_empty():
		game.action = "shoot"; game.target_id = int(options[0].id)
		game._show_shot(); game.hud_controls.aim_ui.refresh()
		check(game.hud_controls.aim_ui.panel.visible, "aim strip opens for a valid target")
		check(game.hud_controls.aim_ui.confirm.text.contains("HIT") and game.hud_controls.aim_ui.confirm.text.contains("DMG"), "confirm shows hit and damage")
		check(game.hud_controls.aim_ui.targets.get_child_count() == mini(options.size(), 2), "all legal enemies appear in target strip")
		game._cancel_order()
		check(not game.hud_controls.aim_ui.panel.visible, "cancel closes aim strip")
	else:
		check(false, "fixture has a visible shot")
	game.queue_free(); await process_frame
	print("BATTLE12 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
