extends SceneTree
const Handoff = preload("res://scripts/w36turn_handoff.gd")
const Presentation = preload("res://scripts/enemy_presentation.gd")
const Shot = preload("res://scripts/shot.gd")
var checks := 0
var failures := 0
var proof_dir := ""

class CalloutProbe extends RefCounted:
	var values: Array[String] = []
	func hud_safe_rect28() -> Rect2: return Rect2(Vector2(170, 64), Vector2(610, 245))
	func w36_show_enemy_callout(actor_name: String, reason: String, result: String) -> void:
		values = [actor_name, reason, result]

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1

func capture(name: String) -> void:
	if proof_dir == "": return
	await process_frame
	var image: Image = root.get_texture().get_image()
	check(image != null and image.save_png(proof_dir.path_join(name + ".png")) == OK, "capture " + name)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--proof="): proof_dir = arg.trim_prefix("--proof=")
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	RescueSettings.set_battle_value("auto_select", true)
	preload("res://scripts/campaign/strat_preferences.gd").set_value("motion", false)
	var game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.animate_headless = true
	game.set_process(false)
	game.cam.set_process(false)
	game.action_camera = true
	var actor: Dictionary = game.mission.living("player")[0]
	game.selected_id = int(actor.id)
	var original_id: int = game.selected_id
	var next_id: int = preload("res://scripts/input_controls.gd").next_squad(game.mission, original_id, 1, true)
	var dest := Vector2i(-1, -1)
	var reach: Dictionary = game.mission.paths(actor, int(actor.mob) * 2)
	for tile in reach.costs:
		if tile != Shot.pos(actor) and int(reach.costs[tile]) <= int(actor.mob): dest = tile; break
	check(dest.x >= 0 and next_id >= 0 and next_id != original_id, "fixture has a move and next unit")
	if dest.x >= 0:
		game._move_selected(dest)
		var deadline := Time.get_ticks_msec() + 12000
		while not game.cam.trace.has("handoff_hold_start_%d" % original_id) and Time.get_ticks_msec() < deadline:
			await process_frame
		check(game.cam.trace.has("handoff_hold_start_%d" % original_id), "scripted move reaches destination hold")
		if game.cam.trace.has("handoff_hold_start_%d" % original_id):
			await capture("after-destination-hold")
			deadline = Time.get_ticks_msec() + 2000
			while game.selected_id == original_id and Time.get_ticks_msec() < deadline: await process_frame
			var hold_ms: int = int(game.get_meta("w36turn_pan_started_ms", 0)) - int(game.get_meta("w36turn_hold_started_ms", 0))
			check(hold_ms >= 500, "destination stays targeted for at least 0.5 s (%d ms)" % hold_ms)
			check(game.selected_id == next_id and hold_ms >= 580, "visible handoff pans to next unit after hold")
			check(game.camera_tween != null, "handoff schedules a camera pan")
			if game.camera_tween != null and game.camera_tween.is_running(): await game.camera_tween.finished
			await capture("before-immediate-next-unit")
	# A drag during the hold leaves the camera and selection under player control.
	var drag_actor: int = game.selected_id
	var serial: int = int(game.get_meta("w36turn_handoff_serial", 0)) + 1
	game.set_meta("w36turn_handoff_serial", serial)
	Handoff.handoff(game, original_id, serial)
	await create_timer(0.10).timeout
	var before_drag: Vector3 = game.pivot
	var board_point := Vector2(-1, -1)
	for y in [125, 175, 225, 275]:
		for x in [220, 300, 380, 460, 540, 620, 700]:
			var candidate := Vector2(x, y)
			if game.cam.touch._control_at(game.get_viewport(), candidate) == null and preload("res://scripts/w28e_move_input.gd").unit_at(game, candidate).is_empty():
				board_point = candidate; break
		if board_point.x >= 0: break
	check(board_point.x >= 0, "fixture has free board point for touch drag")
	var down := InputEventScreenTouch.new(); down.index = 0; down.pressed = true; down.position = board_point
	var drag := InputEventScreenDrag.new(); drag.index = 0; drag.position = board_point + Vector2(50, 0); drag.relative = Vector2(50, 0)
	var up := InputEventScreenTouch.new(); up.index = 0; up.pressed = false; up.position = drag.position
	game.cam.touch.handle(down); game.cam.touch.handle(drag); game.cam.touch.handle(up)
	var manual: Vector3 = game.pivot
	await create_timer(Handoff.HOLD_SECONDS + 0.15).timeout
	check(game.camera_drag_serial24 > 0 and manual.distance_to(before_drag) > 0.01 and game.selected_id == drag_actor and game.pivot.distance_to(manual) < 0.01, "camera drag cancels automatic handoff")
	# Force a genuine deferred reaction through the presentation resolver.
	var watcher: Dictionary = game.mission.living("player")[0]
	var target: Dictionary = game.mission.living("enemy")[0]
	target.awake = true; target.spotted = true; target.detected = true
	game._refresh_figures()
	var info: Dictionary = Shot.calculate(game.mission, watcher, target)
	info.hit = 100; info.crit = 0
	var reaction := {"kind":"intent", "actor":int(watcher.id), "target":int(target.id), "from":Shot.pos(watcher), "to":Shot.pos(target), "mode":"shoot", "reaction":true, "info":info}
	game.mission.defer_resolution = true
	game.cam.skip_requested = false
	var normal_phone: Variant = game.hud_controls.phone
	var callout := CalloutProbe.new()
	game.hud_controls.phone = callout
	await Presentation.show_event(game, reaction)
	check(game.cam.trace.has("reaction_%s_to_%s" % [watcher.name, target.name]), "reaction entry names watcher and target")
	check(game.cam.trace.count("camera_start") >= 2, "reaction frames watcher then target")
	check(callout.values.size() == 3 and callout.values[0] == str(watcher.name) and callout.values[1].contains(str(target.name)) and callout.values[2] in ["Hit", "Miss"], "reaction calls guarded HUD card with names and result")
	game.hud_controls.phone = normal_phone
	target.hp = maxi(10, int(target.hp))
	game.cam.skip_requested = true
	var reaction_count: int = game.cam.trace.count("reaction_%s_to_%s" % [watcher.name, target.name])
	await Presentation.show_event(game, reaction)
	check(game.cam.trace.count("reaction_%s_to_%s" % [watcher.name, target.name]) == reaction_count + 1, "reaction also works without HUD hook")
	# Ordinary enemy activity takes the unchanged fast path.
	game.playing_enemy_events = true
	game.cam.fast_forward_w34c = true
	game.cam.skip_requested = false
	var before := Time.get_ticks_msec()
	await Presentation.show_event(game, {"kind":"reload", "actor":int(target.id)})
	var elapsed := Time.get_ticks_msec() - before
	check(elapsed <= 500, "enemy event without reaction adds at most 0.5 s (%d ms)" % elapsed)
	game.queue_free()
	for i in 4: await process_frame
	print("W36 TURN RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
