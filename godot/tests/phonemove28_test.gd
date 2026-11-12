extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Shot = preload("res://scripts/shot.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("PHONEMOVE28 FAIL ", label)

func touch(game: Node, point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0; event.position = point; event.pressed = down
	game.cam.touch.handle(event)

func tap(game: Node, point: Vector2) -> void:
	touch(game, point, true)
	touch(game, point, false)

func drag(game: Node, from: Vector2, to: Vector2) -> void:
	touch(game, from, true)
	var event := InputEventScreenDrag.new()
	event.index = 0; event.position = to; event.relative = to - from
	game.cam.touch.handle(event)
	touch(game, to, false)

func candidates(game: Node, actor: Dictionary) -> Array:
	var out: Array = []
	var route: Dictionary = game.mission.paths(actor, int(actor.mob) * 2)
	var safe: Rect2 = game.cam._map_rect28().grow(-48)
	for tile in route.costs:
		if tile == Shot.pos(actor) or int(route.costs[tile]) > int(actor.mob) * int(actor.ap): continue
		var point: Vector2 = game.camera.unproject_position(Vector3(tile.x, Shot.elevation(game.mission, tile) * 0.7 + 0.2, tile.y))
		if not safe.has_point(point): continue
		if point.distance_to(game.camera.unproject_position(Vector3(actor.x, Shot.elevation(game.mission, Shot.pos(actor)) * 0.7 + 1, actor.y))) < 75: continue
		out.append({"tile": tile, "point": point})
	return out

func run_case(size: Vector2i) -> void:
	root.size = size; root.content_scale_size = size
	DisplayServer.window_set_size(size)
	Phone.test_touch = 1; Phone.test_mobile = 1; Phone.test_scale = 1
	var flow: Node = root.get_node("CampaignFlow")
	flow.save_path = "user://phonemove28-%d-%d.json" % [size.x, OS.get_process_id()]
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	var game: Node = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 8: await process_frame
	var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
	var original := Shot.pos(actor)
	var grid: Node = game.highlights.get_node_or_null("MapArtGrid")
	if grid == null:
		for child in game.highlights.get_children():
			if child.has_method("move_preview_state28"): grid = child
	check(grid != null, "%s grid exists" % size)
	if grid != null:
		check(grid.reach_edges28 > 0 and grid.reach_view28.visible and grid.reach_view28.multimesh.instance_count > 0, "%s selected reach visible" % size)
		check(grid.evac_batches_hidden28 > 0 and grid.evac_label28.visible, "%s evac ring ladder replaced" % size)
	var choices := candidates(game, actor)
	check(choices.size() >= 2, "%s has two visible move tiles" % size)
	if choices.size() >= 2:
		var first: Dictionary = choices[0]
		var second: Dictionary = choices[choices.size() - 1]
		tap(game, first.point)
		check(game.preview_tile == first.tile and Shot.pos(actor) == original, "%s first tap previews only" % size)
		check(int(game.cam.move_preview_state28().cost) in [1, 2], "%s exposes AP cost" % size)
		game.hud_controls.phone.popup.visible = true
		tap(game, first.point)
		check(game.preview_tile == first.tile and Shot.pos(actor) == original, "%s popup blocks map tap" % size)
		game.hud_controls.phone.popup.visible = false
		game.hud_controls.night.pause_back.visible = true
		tap(game, first.point)
		check(game.preview_tile == first.tile and Shot.pos(actor) == original, "%s pause blocks map tap" % size)
		game.hud_controls.night.pause_back.visible = false
		await process_frame
		var button_point: Vector2 = grid.move_controls24.get_global_rect().get_center()
		var button_pan: Vector3 = game.pivot
		drag(game, button_point, button_point + Vector2(72, 10))
		check(game.pivot.distance_to(button_pan) < 0.01 and game.preview_tile == first.tile, "%s button drag does not pan" % size)
		tap(game, second.point)
		check(game.preview_tile == second.tile and Shot.pos(actor) == original, "%s retargets" % size)
		tap(game, Vector2(-20, -20))
		check(game.preview_tile.x < 0, "%s sky cancels" % size)
		tap(game, first.point)
		var before_pan: Vector3 = game.pivot
		drag(game, second.point, second.point + Vector2(75, 25))
		check(game.preview_tile == first.tile and Shot.pos(actor) == original, "%s drag does not commit" % size)
		check(game.pivot.distance_to(before_pan) > 0.05, "%s drag pans" % size)
		var unit_point: Vector2 = game.camera.unproject_position(Vector3(actor.x, Shot.elevation(game.mission, original) * 0.7 + 1, actor.y))
		before_pan = game.pivot
		drag(game, unit_point, unit_point + Vector2(65, 20))
		check(game.pivot.distance_to(before_pan) < 0.01, "%s unit drag does not pan" % size)
		tap(game, unit_point)
		check(game.preview_tile.x < 0, "%s unit tap cancels" % size)
		var updated := candidates(game, actor)
		if not updated.is_empty():
			var target: Dictionary = updated[0]
			tap(game, target.point)
			check(game.preview_tile == target.tile and Shot.pos(actor) == original, "%s move tap one" % size)
			tap(game, target.point)
			check(Shot.pos(actor) == target.tile, "%s move tap two" % size)
	game.queue_free()
	await process_frame
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))

func run() -> void:
	if "--perf" in OS.get_cmdline_user_args():
		await perf_case()
		quit(0)
		return
	await run_case(Vector2i(956, 440))
	await run_case(Vector2i(844, 390))
	await confirm_case()
	Phone.test_touch = -1; Phone.test_mobile = -1; Phone.test_scale = 0
	print("PHONEMOVE28 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func confirm_case() -> void:
	root.size = Vector2i(844, 390); root.content_scale_size = root.size
	Phone.test_touch = 1; Phone.test_mobile = 1; Phone.test_scale = 1
	var flow: Node = root.get_node("CampaignFlow")
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	var game: Node = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 8: await process_frame
	var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
	var choices := candidates(game, actor)
	check(not choices.is_empty(), "confirm button has visible tile")
	if not choices.is_empty():
		var target: Dictionary = choices[0]
		tap(game, target.point)
		await process_frame
		var grid: Node = game.highlights.get_children().filter(func(child): return child.has_method("move_preview_state28"))[0]
		var press := InputEventScreenTouch.new()
		press.index = 0; press.pressed = true; press.position = Vector2(150, 22)
		grid.move_controls24._gui_input(press)
		check(Shot.pos(actor) == target.tile, "confirm button commits preview")
	game.queue_free()
	await process_frame

func perf_case() -> void:
	root.size = Vector2i(390, 844); root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	Phone.test_touch = 1; Phone.test_mobile = 1; Phone.test_scale = 1
	var flow: Node = root.get_node("CampaignFlow")
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	var game: Node = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	var peak := 0
	for i in 150:
		await process_frame
		peak = maxi(peak, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	print("PHONEMOVE28 PORTRAIT LOW DRAWS: ", peak)
	game.queue_free()
