extends SceneTree
const InputControls = preload("res://scripts/input_controls.gd")
const Shot = preload("res://scripts/shot.gd")
const Camera = preload("res://scripts/cam_combat.gd")
const Quality = preload("res://scripts/graphics_settings.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func unit_bounds(game, unit: Dictionary) -> Rect2:
	var at: Vector3 = game.views[int(unit.id)].global_position
	var bounds := Rect2()
	var first := true
	for x in [-0.5, 0.5]:
		for y in [0.0, 2.3]:
			for z in [-0.5, 0.5]:
				var point: Vector2 = game.camera.unproject_position(at + Vector3(x, y, z))
				if first: bounds = Rect2(point, Vector2.ZERO); first = false
				else: bounds = bounds.expand(point)
	return bounds

func aim_body_bounds(game, unit: Dictionary) -> Rect2:
	var at: Vector3 = game.views[int(unit.id)].global_position
	var bounds := Rect2()
	var first := true
	for x in [-0.3, 0.3]:
		for y in [0.2, 1.85]:
			for z in [-0.3, 0.3]:
				var point: Vector2 = game.camera.unproject_position(at + Vector3(x, y, z))
				if first: bounds = Rect2(point, Vector2.ZERO); first = false
				else: bounds = bounds.expand(point)
	return bounds

func check_phone_tactical(game, unit: Dictionary, context: String) -> void:
	var phone = game.hud_controls.phone
	var bounds := unit_bounds(game, unit)
	var header_bottom: float = phone.overlay.get_child(0).get_global_rect().end.y
	var tray_top: float = phone.overlay.find_child("AbilityTray", true, false).get_global_rect().position.y
	check(bounds.position.y >= header_bottom + 8.0 and bounds.end.y <= tray_top - 8.0, context + " selected unit clears phone HUD: %s header=%.1f tray=%.1f" % [bounds,header_bottom,tray_top])
	check(bounds.position.x >= 8.0 and bounds.end.x <= 836.0, context + " selected unit stays on screen")
	var at: Vector3 = game.views[int(unit.id)].global_position
	var tile_width: float = game.camera.unproject_position(at + Vector3(0.5, 0, 0)).distance_to(game.camera.unproject_position(at + Vector3(-0.5, 0, 0)))
	check(tile_width * 7.0 <= 844.0, context + " tactical view spans at least seven tiles")

func run() -> void:
	check(Camera.AIM_BLEND < 0.4, "aim transition is under 0.4 seconds")
	check(Quality.effective_tier("high", "gl_compatibility") == "low", "Compatibility still forces Low")
	for size in [Vector2i(844, 390), Vector2i(1366, 768)]:
		await exercise(size)
	print("BATTLE13 TEST RESULTS: %d checks, %d failures" % [checks, failures])
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
	if size.x < 1000:
		var initial: Dictionary = game.mission.unit_by_id(game.selected_id)
		check_phone_tactical(game, initial, "start")
		var available_at_start := 0
		var shown_at_start := 0
		for button in game.hud_controls.phone.ability_buttons:
			if bool(button.get_meta("battle12_available", false)): available_at_start += 1
			if button.visible: shown_at_start += 1
		check(shown_at_start >= 2 and shown_at_start <= available_at_start and (shown_at_start == available_at_start or game.hud_controls.phone.more_button.visible), "phone keeps primary actions reachable through overflow at turn start")
		var another: Dictionary = game.mission.living("player")[1]
		Input.warp_mouse(Vector2(422, 195))
		game._select(int(another.id))
		game.set_process(false)
		await create_timer(0.5).timeout
		check_phone_tactical(game, another, "after selection")
		var objective: Label = game.objective_label
		var text_width: float = objective.get_theme_font("font").get_string_size(objective.text, HORIZONTAL_ALIGNMENT_LEFT, -1, objective.get_theme_font_size("font_size")).x
		check(text_width <= objective.size.x - 4.0 and objective.text_overrun_behavior != TextServer.OVERRUN_TRIM_ELLIPSIS, "phone mission objective and turn count fit")
	game.set_process(false)
	var actor: Dictionary = {}
	for unit in game.mission.living("player"):
		if "shoot" in unit.get("kit", []): actor = unit; break
	check(not actor.is_empty(), "shooter exists at %s" % size)
	if actor.is_empty(): game.queue_free(); return
	game._select(int(actor.id))
	var nearby: Dictionary = game.mission.paths(actor, 3)
	for tile in nearby.costs:
		if int(nearby.costs[tile]) == 1:
			var enemy: Dictionary = game.mission.living("enemy")[0]
			enemy.x = tile.x; enemy.y = tile.y; enemy.awake = true; enemy.spotted = true
			break
	game._refresh_figures()
	var options: Array[Dictionary] = InputControls.valid_targets(game.mission, actor, "shoot")
	check(not options.is_empty(), "visible target exists at %s" % size)
	if options.is_empty(): game.queue_free(); return
	game.action = "shoot"
	game.target_id = int(options[0].id)
	game._frame_target()
	game._refresh()
	for i in range(22): await process_frame
	var aim = game.hud_controls.aim_ui
	check(aim.panel.visible, "aim card opens at %s" % size)
	check(game.cam.preview_active, "shoulder camera holds target at %s" % size)
	game.cam.skip_preview_transition()
	check(game.cam.preview_tween == null or not game.cam.preview_tween.is_running(), "aim transition skips immediately")
	var target: Dictionary = game.mission.unit_by_id(game.target_id)
	var target_bounds := aim_body_bounds(game, target)
	var target_point: Vector3 = game.views[int(target.id)].global_position + Vector3.UP * 1.25
	var target_screen: Vector2 = game.camera.unproject_position(target_point)
	var viewport := Rect2(Vector2.ZERO, Vector2(size))
	check(viewport.has_point(target_screen) and not game.camera.is_position_behind(target_point), "aim target stays on screen at %s" % size)
	check(not aim.panel.get_global_rect().has_point(target_screen), "target clears aim card at %s" % size)
	if size.x < 1000:
		check(target_bounds.size.y >= 55.0, "phone aim target is at least 55 px tall: %s" % target_bounds)
		check(game.cam.preview_shoulder != null and game.cam.preview_shoulder.visible, "phone foreground shoulder is visible")
		check(aim.odds.text.contains("HIT") and aim.odds_detail.text.contains("DMG"), "phone aim card shows odds and damage")
	var origin := Vector3(float(actor.x), Shot.elevation(game.mission, Shot.pos(actor)) * 0.7, float(actor.y))
	var destination := Vector3(float(target.x), Shot.elevation(game.mission, Shot.pos(target)) * 0.7, float(target.y))
	var shot_direction := destination - origin; shot_direction.y = 0.0
	check((game.camera.position - origin).dot(shot_direction) < 0.0, "camera is behind shooter at %s" % size)
	check(absf((game.camera.position - origin).cross(shot_direction.normalized()).y) > 0.45, "camera is offset over shoulder at %s" % size)
	check(Camera.aim_ray_clear(game.mission, game.camera.position, target_point), "cover clears camera ray at %s" % size)
	check(viewport.encloses(aim.panel.get_global_rect()), "aim card fits at %s" % size)
	check(viewport.encloses(aim.confirm.get_global_rect()) and aim.confirm.size.y >= 44.0, "FIRE is reachable at %s" % size)
	if size.x < 1000:
		check(aim.targets.get_child(0).text.contains("HIT") and game.shot_label.text.contains("DMG"), "phone target chip shows hit and ODDS retains damage at %s" % size)
	else:
		check(aim.confirm.text.contains("HIT") and aim.confirm.text.contains("DMG"), "hit and damage remain readable at %s" % size)
	check(aim.summary.text.contains(str(target.name)) and viewport.encloses(aim.summary.get_global_rect()), "target card fits at %s" % size)
	if size.x < 1000:
		var phone = game.hud_controls.phone
		check(phone != null and phone.overlay.visible, "compact phone HUD exists")
		var count := 0
		for button in phone.ability_buttons:
			if button.visible:
				count += 1
				check(button.compact and button.hotkey != "" and button.size.y >= 40, "phone uses 48 physical pixel icon touch buttons")
		check(count <= 5 and phone.more_button.visible, "phone shows at most five actions plus More")
		check(viewport.encloses(phone.unit_card.get_global_rect()), "phone unit card fits")
		check(phone.unit_card.text.contains(str(actor.name)), "phone unit name is complete")
	else:
		check(not game.hud_controls.left_panel.visible and not game.hud_controls.right_panel.visible, "tall panels fold away during aim")
		var bar = game.hud_controls.bar
		var count := 0
		for button in bar.copies.values():
			if button.visible: count += 1; check(viewport.encloses(button.get_global_rect()), "action button fits")
		check(count <= 5 and bar.more.visible, "desktop shows at most five actions plus More")
		check(viewport.encloses(bar.more.get_global_rect()), "desktop More fits")
		var end_turn: Button = null
		for node in game.overlay.find_children("*", "Button", true, false):
			if node.text == "END TURN": end_turn = node; break
		check(end_turn != null and viewport.encloses(end_turn.get_global_rect()), "END TURN label fits")
	check(not game.scene_view.world.environment.ssao_enabled, "Low keeps SSAO disabled")
	check(not game.scene_view.sun.shadow_enabled, "Low keeps dynamic shadows disabled")
	game._cancel_order()
	check(not game.cam.preview_active and not game.cinematic and not aim.panel.visible, "cancel restores tactical view")
	game.action = "shoot"
	game.target_id = int(target.id)
	game._frame_target(); game._refresh()
	check(game.cam.preview_active, "second target selection reopens shoulder view")
	game._attack(int(target.id), "shoot")
	check(not game.cam.preview_active and not game.cinematic and game.action == "move", "fire restores tactical view")
	game.queue_free()
	for i in range(3): await process_frame
