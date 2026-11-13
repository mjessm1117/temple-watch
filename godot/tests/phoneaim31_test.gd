extends SceneTree
const Layout = preload("res://scripts/hud_phone_layout.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const InputControls = preload("res://scripts/input_controls.gd")
const Cam = preload("res://scripts/cam_combat.gd")
const Shot = preload("res://scripts/shot.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func actor_box(eye: Vector3, look: Vector3, actor: Vector3, viewport: Vector2) -> Rect2:
	var bounds := Rect2()
	var first := true
	for x in [-0.38, 0.38]:
		for z in [-0.38, 0.38]:
			for y in [0.0, 1.9]:
				var point: Vector2 = Cam.aim_screen_point(eye, look, actor + Vector3(x, y, z), viewport) * viewport
				if first: bounds = Rect2(point, Vector2.ZERO); first = false
				else: bounds = bounds.expand(point)
	return bounds

func run() -> void:
	for size in [Vector2(844, 390), Vector2(390, 844)]:
		var boxes: Dictionary = Layout.boxes(size)
		var controls: Array[Rect2] = [boxes.plate, boxes.tray, boxes.end, boxes.camera]
		for box in controls:
			check(box.size.x >= 44 and box.size.y >= 44, "%s control target size" % size)
			check(Rect2(Vector2.ZERO, size).encloses(box), "%s control inside viewport" % size)
		for i in controls.size():
			for j in range(i + 1, controls.size()):
				check(not controls[i].intersects(controls[j]), "%s controls separated" % size)
		check(not boxes.map.intersects(boxes.tray), "%s map clear of tray" % size)
		check(not boxes.map.intersects(boxes.camera), "%s map clear of camera rail" % size)
	Phone.test_touch = 1; Phone.test_mobile = 1; Phone.test_scale = 1; Phone.test_window_size = Vector2i(390, 844)
	root.size = Vector2i(600, 1200); root.content_scale_size = Vector2i(390, 844)
	DisplayServer.window_set_size(root.size)
	var flow: Node = root.get_node("CampaignFlow")
	flow.save_path = "user://phoneaim31-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	var game: Node = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 8: await process_frame
	root.size = Vector2i(600, 1200); root.content_scale_size = Vector2i(390, 844)
	game.hud_controls.phone._relayout()
	await process_frame
	var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
	var enemies: Array[Dictionary] = game.mission.living("enemy")
	check(not actor.is_empty() and not enemies.is_empty(), "rescue has shooter and target")
	if not actor.is_empty() and not enemies.is_empty():
		var enemy: Dictionary = enemies[0]
		var origin := Vector3(actor.x, Shot.elevation(game.mission, Shot.pos(actor)) * 0.7, actor.y)
		var destination := Vector3(enemy.x, Shot.elevation(game.mission, Shot.pos(enemy)) * 0.7, enemy.y)
		var viewport := Vector2(390, 844)
		var eye: Vector3 = Cam.aim_shoulder(game.mission, origin, destination, true, viewport)
		var frame: Dictionary = Cam.portrait_frame31(eye, origin, destination, viewport)
		var box: Rect2 = actor_box(frame.eye, frame.look, origin, viewport)
		check(Rect2(Vector2.ZERO, viewport).intersects(box), "portrait shooter box intersects screen")
		check(Layout.boxes(viewport).map.grow(-14).encloses(box), "portrait shooter box inside safe map")
		game.action = "shoot"; game.target_id = int(enemy.id)
		enemy.awake = true; enemy.spotted = true
		game.hud_controls.phone._refresh_odds()
		game.hud_controls.aim_ui.refresh()
		game.hud_controls._sync_aim_confirm31()
		game.cam.skip_preview_transition()
		await process_frame
		var phone = game.hud_controls.phone
		var aim = game.hud_controls.aim_ui
		var actual_size: Vector2 = game.get_viewport().get_visible_rect().size
		var actual_box := Rect2()
		var first_corner := true
		for x in [-0.38, 0.38]:
			for z in [-0.38, 0.38]:
				for y in [0.0, 1.9]:
					var screen: Vector2 = game.camera.unproject_position(origin + Vector3(x, y, z))
					if first_corner: actual_box = Rect2(screen, Vector2.ZERO); first_corner = false
					else: actual_box = actual_box.expand(screen)
		check(Rect2(Vector2.ZERO, actual_size).intersects(actual_box), "live portrait aim shooter box intersects screen")
		check(game.views[int(actor.id)].model.visible and game.cam.preview_source_model == null, "portrait keeps world shooter figure visible")
		var headers := 0
		if phone.odds_plate.visible and phone.odds_hit.visible and phone.odds_hit.text.contains("% HIT"): headers += 1
		if aim.panel.visible and aim.odds.is_visible_in_tree() and aim.odds.text.contains("% HIT"): headers += 1
		for chip in aim.targets.get_children():
			if chip is Button and chip.is_visible_in_tree() and chip.text.contains("% HIT"): headers += 1
		if aim.confirm.text.contains("% HIT"): headers += 1
		check(headers == 1, "portrait aim hierarchy has one hit odds header")
		check(phone.odds_hit.text.contains("% CRIT") and not aim.confirm.text.contains("HIT"), "crit shares odds header and confirm has no duplicate")
		var grid: Node = game.highlights.get_node_or_null("MapArtGrid")
		if grid == null:
			for child in game.highlights.get_children():
				if child.has_method("move_preview_state28"): grid = child
		check(grid != null and grid.evac_label28.visible, "EVAC label is visible")
		if grid != null:
			var evac: Vector2i = Maps.point(game.mission.spec.evac[0])
			var center_y: float = Shot.elevation(game.mission, evac) * 0.7
			check(grid.evac_label28.position.y - center_y >= 0.5, "EVAC label above unit tile center")
		game.cam.end_preview()
		game.action = "move"
		var route: Dictionary = game.mission.paths(actor, int(actor.mob) * 2)
		var found := false
		for tile in route.costs:
			if found: break
			if tile == Shot.pos(actor) or int(route.costs[tile]) > int(actor.mob) * int(actor.ap): continue
			for offset in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
				var source: Vector2i = tile + offset
				if not game.mission.in_bounds(source) or source == Shot.pos(actor) or source == tile: continue
				enemy.x = source.x; enemy.y = source.y
				var preview: Dictionary = InputControls.move_preview(game.mission, actor, tile)
				if preview.is_empty() or int(InputControls.sight26(game.mission, actor, tile).seen_by) == 0: continue
				check(preview.has("first_danger_tile") and preview.first_danger_tile.x >= 0, "route preview reports first danger tile")
				check(InputControls.preview26(game.mission, tile, int(actor.id)).first_danger_tile == preview.first_danger_tile, "route safety shares exact danger tile")
				found = true
				break
		check(found, "known enemy line of sight route found")
	game.queue_free()
	await process_frame
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	Phone.test_touch = -1; Phone.test_mobile = -1; Phone.test_scale = 0; Phone.test_window_size = Vector2i.ZERO
	print("PHONEAIM31 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
