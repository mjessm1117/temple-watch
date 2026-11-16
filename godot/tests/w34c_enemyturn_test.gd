extends SceneTree
const Timing = preload("res://scripts/w34c_enemy_timing.gd")
const Presentation = preload("res://scripts/enemy_presentation.gd")
const Card = preload("res://scripts/w31e_enemy_card.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("W34C: " + label)

func run() -> void:
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	var game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.animate_headless = true
	game.set_process(false)
	game.action_camera = true
	game.playing_enemy_events = true
	var enemy: Dictionary = game.mission.living("enemy")[0]
	var player: Dictionary = game.mission.living("player")[0]
	enemy.awake = true; enemy.spotted = true
	game._refresh_figures()
	var far := Vector3(10000, 0, 10000)
	check(not Timing.visible_move(game, far, [far + Vector3.RIGHT]), "offscreen route is invisible")
	var actor: Node3D = game.views.get(int(enemy.id))
	var original: Vector3 = actor.position
	actor.position = far
	var trace_before: int = game.cam.trace.count("camera_start")
	await Presentation.show_event(game, {"kind":"reload", "actor":int(enemy.id)})
	check(game.cam.trace.count("camera_start") == trace_before and Card.current(game) == null, "invisible reload has no camera trip or card")
	actor.position = original
	var held := Time.get_ticks_msec()
	await game.cam.hold_drama_w34c()
	check(Time.get_ticks_msec() - held >= 800, "dramatic hold lasts at least 0.8 seconds")
	var tap := InputEventScreenTouch.new(); tap.pressed = true; tap.position = Vector2(120, 200)
	game.cam._input(tap)
	check(game.cam.fast_forward_w34c, "screen tap enables enemy fast forward")
	var fast_start := Time.get_ticks_msec()
	await game.cam.wait(0.4)
	check(Time.get_ticks_msec() - fast_start < 80, "tap skips ordinary waits")
	var shot := {"kind":"attack", "actor":int(enemy.id), "target":int(player.id), "from":Vector2i(enemy.x,enemy.y), "to":Vector2i(player.x,player.y), "mode":"shoot", "enemy":true, "outcome":"hits", "damage":2, "killed":false}
	var shot_start := Time.get_ticks_msec()
	await Presentation.show_event(game, shot)
	check(game.cam.trace.has("impact_%d" % int(enemy.id)), "fast forward resolves damage")
	var card: PanelContainer = Card.current(game)
	check(card != null and card.get_node("CardLines/ActionResult").text == "HIT", "fast forward preserves hit result")
	await game.cam.hold_drama_until_w34c(int(game.get_meta("w34c_drama_started_ms")))
	check(Time.get_ticks_msec() - shot_start >= 800, "fast forward preserves the full shot beat")
	var destination: Vector3 = actor.position + Vector3.RIGHT
	actor.motion = actor.create_tween()
	actor.motion.tween_property(actor, "position", destination, 0.2)
	game.quiet_motions.append(actor)
	game.quiet_targets[int(enemy.id)] = destination
	Presentation.release_quiet_w34c(game)
	check(game.quiet_motions.is_empty() and actor.motion.is_running(), "handoff does not wait for resolved movement")
	await actor.motion.finished
	check(actor.position.distance_to(destination) < 0.01, "movement reaches its committed destination")
	game.playing_enemy_events = false
	game.queue_free()
	for i in 4: await process_frame
	print("W34C RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
