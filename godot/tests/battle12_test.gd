extends SceneTree
const CameraRules = preload("res://scripts/battle11_camera.gd")
const InputControls = preload("res://scripts/input_controls.gd")
const Rules12 = preload("res://scripts/rules12_actions.gd")
const HudControls = preload("res://scripts/hud_controls.gd")
const Shot = preload("res://scripts/shot.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	root.size = Vector2i(844, 390)
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
	check(Rules12.ACTIONS_PER_TURN == 2, "rules grant two actions")
	check(HudControls.ap_pips(actor) == "%d/%d" % [int(actor.ap),Rules12.ACTIONS_PER_TURN], "action count follows the rules maximum")
	check(game.hud_controls.night.vitals_label.text.contains("AP " + HudControls.ap_pips(actor)), "desktop plate uses the shared action pips")
	var blue: Dictionary = m.reach_tiles(actor, 1)
	var yellow: Dictionary = m.reach_tiles(actor, 2)
	check(int(actor.mob) > 0 and blue.costs.size() > 1, "mobile selected unit has blue reach")
	check(yellow.costs.size() > blue.costs.size(), "mobile selected unit has dash reach")
	var blue_fill := 0
	var yellow_fill := 0
	for node in game.range_highlights.get_children():
		if not node is MeshInstance3D or node.material_override == null: continue
		var color: Color = node.material_override.albedo_color
		if color.is_equal_approx(HudControls.move_fill(1)): blue_fill += 1
		if color.is_equal_approx(HudControls.move_fill(2)): yellow_fill += 1
	check(blue_fill == blue.costs.size() - 1, "blue ring is drawn for one action")
	check(yellow_fill == yellow.costs.size() - blue.costs.size(), "yellow dash ring is drawn for two actions")
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
		game._frame_target(); game._refresh()
		for i in range(30): await process_frame
		check(game.hud_controls.aim_ui.panel.visible, "aim strip opens for a valid target")
		check(game.hud_controls.aim_ui.confirm.text.contains("HIT") and game.hud_controls.aim_ui.confirm.text.contains("DMG"), "confirm shows hit and damage")
		check(game.hud_controls.aim_ui.targets.get_child_count() == 1, "phone strip shows one target chip")
		var strip: PanelContainer = game.hud_controls.aim_ui.panel
		var target: Dictionary = m.unit_by_id(game.target_id)
		check(strip.get_global_rect().size.y >= 44.0, "phone aim strip meets touch height")
		check(game.hud_controls.phone.unit_card.visible and not game.hud_controls.phone.target_card.visible, "phone keeps the compact top chip and hides the plate row")
		check(game.hud_controls.phone.unit_card.text.contains(HudControls.ap_pips(actor)), "phone unit chip uses the shared action pips")
		for unit in [actor, target]:
			var at: Vector2 = game.camera.unproject_position(Vector3(unit.x, Shot.elevation(m, Shot.pos(unit)) * 0.7 + 1.0, unit.y))
			check(not strip.get_global_rect().has_point(at), "phone aim strip clears %s" % str(unit.name))
		game._cancel_order()
		check(not game.hud_controls.aim_ui.panel.visible, "cancel closes aim strip")
	else:
		check(false, "fixture has a visible shot")
	await _dispose_game(game)
	root.size = Vector2i(1366, 768)
	for i in range(3): await process_frame
	print("BATTLE12 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _dispose_game(game: Node3D) -> void:
	game.sound.player.stop()
	game.sound.player.stream = null
	game.queue_free()
	await create_timer(0.2).timeout
	for i in range(3): await process_frame
