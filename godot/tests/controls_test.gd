extends SceneTree

const Mission = preload("res://scripts/mission.gd")
const Controls = preload("res://scripts/input_controls.gd")
const Shot = preload("res://scripts/shot.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	await run_checks(self, check)
	print("CONTROLS TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

static func run_checks(runner: SceneTree, assertion: Callable) -> void:
	var m: RefCounted = Mission.new(7)
	var squad: Array[Dictionary] = m.living("player")
	var actor: Dictionary = squad[0]
	var start: Vector2i = Shot.pos(actor)
	var reach: Dictionary = m.paths(actor, int(actor.mob) * 2)
	var blue := Vector2i(-1, -1)
	var dash := Vector2i(-1, -1)
	for p in reach.costs:
		if p == start: continue
		if int(reach.costs[p]) <= int(actor.mob) and blue.x < 0: blue = p
		if int(reach.costs[p]) > int(actor.mob) and dash.x < 0: dash = p
	assertion.call(blue.x >= 0 and dash.x >= 0, "one action and dash destinations exist")
	if blue.x >= 0:
		var info: Dictionary = Controls.move_preview(m, actor, blue)
		assertion.call(int(info.ap) == 1 and info.shields.size() == 4 and info.has("flanks"), "blue preview includes AP, cover faces, and flank opportunities")
	if dash.x >= 0:
		assertion.call(int(Controls.move_preview(m, actor, dash).ap) == 2, "dash preview costs two AP")
		actor.ap = 1
		assertion.call(Controls.move_preview(m, actor, dash).is_empty(), "dash disabled with one AP")
		actor.ap = 2
	assertion.call(Controls.move_preview(m, actor, start).is_empty(), "current tile cannot be ordered")
	assertion.call(Controls.valid_targets(m, squad[2], "shoot").is_empty(), "unspotted enemies cannot be targeted")
	var enemy: Dictionary = m.living("enemy")[0]
	enemy.awake = true
	enemy.x = int(actor.x) + 1; enemy.y = int(actor.y)
	var shooter: Dictionary = squad[2]
	assertion.call(Controls.valid_targets(m, shooter, "shoot").size() == 1, "legal spotted shooter target appears")
	shooter.ap = 0
	assertion.call(Controls.valid_targets(m, shooter, "shoot").is_empty(), "shot unavailable without AP")
	shooter.ap = 2
	assertion.call(Controls.next_squad(m, int(actor.id), 1) == int(squad[1].id), "Tab advances squad")
	var tracked: RefCounted = Mission.new(7)
	var mover: Dictionary = tracked.living("enemy")[0]
	mover.awake = true
	mover.ap = 2
	tracked.phase = "enemy"
	var from: Vector2i = Shot.pos(mover)
	var destination := Vector2i(-1, -1)
	for tile in tracked.paths(mover, int(mover.mob)).costs:
		if tile != from: destination = tile; break
	if destination.x >= 0: tracked.move(int(mover.id), destination)
	assertion.call(not tracked.action_events.is_empty() and tracked.action_events[0].kind == "move" and tracked.action_events[0].from == from, "enemy action trail preserves actor and origin")
	squad[1].ap = 0
	assertion.call(Controls.next_squad(m, int(actor.id), 1, true) == int(squad[2].id), "spent squad member skipped")
	var packed: PackedScene = load("res://scenes/rescue.tscn")
	assertion.call(packed != null, "controls scene loads")
	if packed != null:
		var game: Node3D = packed.instantiate()
		runner.root.add_child(game)
		await runner.process_frame
		assertion.call(game.action_buttons["shoot"].focus_mode == Control.FOCUS_NONE, "ability button leaves Enter available for target confirmation")
		var guardian_id: int = game.selected_id
		game._select(int(game.mission.living("player")[2].id))
		var game_actor: Dictionary = game.mission.unit_by_id(game.selected_id)
		var game_enemy: Dictionary = game.mission.living("enemy")[0]
		game_enemy.awake = true
		game_enemy.x = int(game_actor.x) + 1; game_enemy.y = int(game_actor.y)
		game.mission.set_tile(Shot.pos(game_enemy) + Vector2i.RIGHT, "c")
		game._choose_action("shoot")
		assertion.call(game.target_id == int(game_enemy.id), "shoot mode selects a legal target")
		assertion.call(game.hit_big_label.text.contains("HIT") and game.shot_label.text.contains("Base aim"), "shot panel shows odds and modifiers")
		assertion.call(game.shot_label.text.contains("FLANKED") and game.shot_label.text.contains("Flanking critical chance"), "flank critical is shown before confirmation")
		game._select(guardian_id)
		game._choose_action("push")
		assertion.call(game.hit_big_label.text == "PUSH" and game.shot_label.text.contains("No hit or crit roll"), "Push presents no roll")
		var cancel := InputEventKey.new()
		cancel.keycode = KEY_ESCAPE
		cancel.pressed = true
		game._unhandled_input(cancel)
		assertion.call(game.action == "move" and game.target_id < 0, "cancel returns to movement")
		var rotate := InputEventKey.new()
		rotate.keycode = KEY_Q
		rotate.pressed = true
		game._unhandled_input(rotate)
		assertion.call(game.camera_tween != null and game.camera_tween.is_running(), "Q starts smooth camera rotation")
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel.pressed = true
		game._unhandled_input(wheel)
		assertion.call(game.camera_tween != null and game.camera_tween.is_running(), "wheel starts smooth camera zoom")
		game_actor.ap = 0
		game._after_action()
		assertion.call(game.selected_id != int(game_actor.id), "spent soldier auto selects next ready soldier")
		game._request_end_turn()
		assertion.call(game.end_turn_armed and game.mission.turn == 1, "end turn warns while actions remain")
		game._request_end_turn()
		assertion.call(game.mission.turn == 2, "second confirmation advances turn")
		game._skip_activity()
		assertion.call(not game.playing_enemy_events, "Space skips queued enemy presentation")
		game.mission.reinforcement_marker = Vector2i(12, 12)
		game._refresh()
		assertion.call(game.reinforcement_view.visible and game.reinforcement_view.shown_tile == Vector2i(12, 12), "reinforcement tile gets warm map marker")
		game.mission.reinforcement_marker = Vector2i(-1, -1)
		game._refresh()
		assertion.call(not game.reinforcement_view.visible, "marker clears after arrival")
		var cover_tile: Vector2i = game.mission.cover_hp.keys()[0]
		game.mission.damage_cover(cover_tile, 99)
		game._refresh()
		assertion.call(game.terrain_seen_revision == game.mission.terrain_revision, "changed cover rebuilds during refresh")
		var hunker_id: int = int(game.mission.living("player")[2].id)
		game._select(hunker_id)
		game._choose_action("hunker")
		assertion.call(bool(game.mission.unit_by_id(hunker_id).hunkered), "Hunker ability applies defense")
		game._select(hunker_id)
		assertion.call(game.selected_label.text.contains("HUNKERED"), "unit panel displays Hunker")
		game.sound.player.stop()
		game.sound.player.stream = null
		game._skip_activity()
		game.queue_free()
		for i in range(5): await runner.process_frame
