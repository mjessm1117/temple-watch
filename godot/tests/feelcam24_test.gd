extends SceneTree
const Camera24 = preload("res://scripts/cam_combat.gd")
const Beats24 = preload("res://scripts/w24_feelcam_beats.gd")
const Presentation = preload("res://scripts/enemy_presentation.gd")
const Shot = preload("res://scripts/shot.gd")
const Killcam = preload("res://scripts/battle16_killcam.gd")
var checks := 0
var failures := 0
var proof_path24 := ""

class FXProbe extends Node3D:
	var cues: Array[String] = []
	var stops: Array[float] = []
	func impact24_cue(kind: String, _pos: Vector3, _power: float = 1.0) -> void: cues.append(kind)
	func hit_stop(seconds: float = 0.055) -> void: stops.append(seconds)
	func float_text(_pos: Vector3, _word: String, _color: Color, _large: bool = false) -> void: pass

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func proof24(name: String) -> void:
	if proof_path24 != "": root.get_texture().get_image().save_png(proof_path24 + "/" + name + ".png")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--proof="): proof_path24 = arg.trim_prefix("--proof=")
	root.size = Vector2i(390, 844)
	root.content_scale_size = root.size
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "cam_sensitivity", 1.6)
	cfg.save("user://controls24.cfg")
	var game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.animate_headless = true
	game.action_camera = true
	game.set_process(false)
	check(absf(game.camera_sensitivity24 - 1.6) < 0.01, "PC camera reads controls24.cfg sensitivity")
	game.zoom = 6.0; game._update_camera()
	check(game.zoom == 9.0 and Camera24.RETURN_BLEND24 <= 0.35, "shared 9-65 zoom and <=350 ms return")
	game.zoom = 80.0; game._update_camera()
	check(game.zoom == 65.0, "shared zoom upper clamp")
	game.zoom = 12.0; game._update_camera()
	if proof_path24 != "" and game.hud_controls.phone != null and game.hud_controls.phone.alerts != null: game.hud_controls.phone.alerts.hide()
	var busy: Array[bool] = []
	game.input_busy_changed24.connect(func(value: bool) -> void: busy.append(value))
	game.player_attack_pending = true; game._sync_input_busy24()
	game.player_attack_pending = false; game._sync_input_busy24()
	check(busy == [true, false] and not game.is_input_busy24(), "K11 busy state and edge signal")
	var wheel := InputEventMouseButton.new(); wheel.button_index = MOUSE_BUTTON_WHEEL_UP; wheel.pressed = true
	game._unhandled_input(wheel)
	check(game.camera_tween != null and game.camera_tween.is_running(), "mouse wheel produces immediate camera response")
	game.cancel_camera_glide24()
	var touch_down := InputEventScreenTouch.new(); touch_down.index = 0; touch_down.pressed = true; touch_down.position = Vector2(190, 420)
	var touch_up := InputEventScreenTouch.new(); touch_up.index = 0; touch_up.pressed = false; touch_up.position = touch_down.position
	game.cam.touch.handle(touch_down); game.cam.touch.handle(touch_up)
	check(game.cam.touch.fingers.is_empty(), "touch press and release leave no held gesture")
	var ally: Dictionary = game.mission.living("player")[0]
	var enemy: Dictionary = game.mission.living("enemy")[0]
	enemy.awake = true; enemy.spotted = true; game._refresh_figures()
	var from := Vector3(ally.x, 0.0, ally.y)
	var to := Vector3(enemy.x, 0.0, enemy.y)
	var eye := Camera24.aim_shoulder(game.mission, from, to, true, Vector2(390, 844))
	var look := to + Vector3.UP * 1.25
	var original_screen := Camera24.aim_screen_point(eye, look, look, Vector2(390, 844)) * Vector2(390, 844)
	var covered := Rect2(original_screen - Vector2(45, 45), Vector2(90, 90))
	game.cam.set_battle_safe_rect24(covered)
	check(game.cam.safe_rect24 == covered, "contract 3 receives HUD safe rect")
	var safe_eye := Camera24.aim_shoulder(game.mission, from, to, true, Vector2(390, 844), covered)
	var safe_look := Camera24.safe_look24(safe_eye, look, look, Vector2(390, 844), 58.0, covered)
	var safe_screen := Camera24.aim_screen_point(safe_eye, safe_look, look, Vector2(390, 844)) * Vector2(390, 844)
	var shooter_screen := Camera24.aim_screen_point(safe_eye, safe_look, from + Vector3.UP * 1.18, Vector2(390, 844)) * Vector2(390, 844)
	check(not covered.has_point(safe_screen) and not covered.has_point(shooter_screen), "B4 safe rect excludes shooter and target in portrait")
	game.cam.set_battle_safe_rect24(Rect2())
	var route := [Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3)]
	game.preview_route24(route)
	check(game.camera_tween != null and game.camera_tween.is_running(), "contract 4 long route gives gentle camera hint")
	game.cancel_camera_glide24()
	check(not game.camera_tween.is_running(), "K2 cancels select and route glides")
	await game.cam.frame(from, to)
	var shot_eye: Vector3 = game.camera.position
	game.cam.finish()
	check(game.cam.return_tween24 != null and game.cam.return_tween24.is_running(), "B4 shot return blends instead of snapping")
	for i in range(5): await process_frame
	check(game.camera.position.distance_to(shot_eye) > 0.01 and game.cinematic, "B4 return shows intermediate frames")
	proof24("camera-return-mid")
	var drag_pivot := Vector3(5, 0, 5)
	game.cancel_camera_glide24(); game.pivot = drag_pivot; game._update_camera()
	game.cam.finish()
	check(game.pivot.distance_to(drag_pivot) < 0.01 and not game.cinematic, "B4 player drag owns pivot during camera beat")
	var old_fx: Node3D = game.fx
	var probe := FXProbe.new(); game.add_child(probe); game.fx = probe
	var victim: Node3D = game.views.get(int(enemy.id))
	if proof_path24 != "": game.cam.set_process(false); game.camera.position = victim.position + Vector3(3.0, 3.0, 6.0); game.camera.look_at(victim.position + Vector3.UP, Vector3.UP)
	var hit := {"kind":"attack", "actor":int(ally.id), "target":int(enemy.id), "mode":"shoot", "outcome":"hits", "damage":2, "killed":false}
	Beats24.impact(game, hit, from, to, victim)
	for i in range(4): await process_frame
	proof24("hit-impulse")
	check(probe.cues.is_empty() and probe.stops == [0.055], "B3 normal hit leaves cue to fx and keeps 55 ms hit-stop")
	var miss := hit.duplicate(); miss.damage = 0; miss.outcome = "misses"
	var dodge_origin: Vector3 = victim.model.position
	Beats24.impact(game, miss, from, to, victim)
	for i in range(1 if proof_path24 != "" else 4): await process_frame
	check(probe.cues.back() == "miss_near" and victim.model.position.distance_to(dodge_origin) > 0.02, "B11 miss places near-miss impact and visible dodge")
	proof24("miss-dodge")
	var kill := hit.duplicate(); kill.killed = true
	Beats24.impact(game, kill, from, to, victim)
	check(probe.cues.back() == "kill" and probe.cues.count("kill") == 1, "B9 kill adds one emphasis cue")
	ally.hp = 1
	var clutch := {"kind":"attack", "actor":int(enemy.id), "target":int(ally.id), "mode":"shoot", "damage":1}
	Beats24.clutch(game, clutch, from)
	var first_text: String = game.phase_banner.text
	Beats24.clutch(game, clutch, from)
	check(first_text.contains("1 HP") and game.clutch_turn24 == int(game.mission.turn) and probe.stops.size() == 3, "B14 clutch triggers once per turn")
	var start: Vector3 = game.views[int(ally.id)].position
	var landing: Vector3 = start + Vector3(2, 0, 0)
	if proof_path24 != "": game.pivot = start; game.zoom = 11.0; game._update_camera()
	if proof_path24 != "": game.camera.position = start + Vector3(3.0, 3.0, 6.0); game.camera.look_at(start + Vector3.UP, Vector3.UP)
	Beats24.leap(game, int(ally.id), start, landing)
	var arc_height := 0.0
	var arc_captured := false
	var arc_deadline := Time.get_ticks_msec() + 170
	while Time.get_ticks_msec() < arc_deadline:
		await process_frame
		arc_height = maxf(arc_height, game.views[int(ally.id)].position.y - start.y)
		if not arc_captured and arc_height > 0.6: proof24("leap-arc"); arc_captured = true
	var landing_deadline := Time.get_ticks_msec() + 800
	while (game.views[int(ally.id)].position.distance_to(landing) > 0.01 or probe.cues.back() != "leap_land") and Time.get_ticks_msec() < landing_deadline: await process_frame
	proof24("leap-land")
	check(arc_height > 0.5 and game.views[int(ally.id)].position.distance_to(landing) < 0.01 and probe.cues.back() == "leap_land", "B8 leap start, arc, land and cue")
	game.fx = old_fx; probe.queue_free()
	game.playing_enemy_events = true
	if proof_path24 != "": game.phase_banner.modulate.a = 1.0
	var skip_key := InputEventKey.new(); skip_key.keycode = KEY_SPACE; skip_key.pressed = true
	game._unhandled_input(skip_key)
	check(game.cam.skip_requested, "busy key input offers skip response")
	game.cam.skip_requested = false
	var reason_event := {"kind":"reload", "actor":int(enemy.id), "intent_reason24":"Objective"}
	await Presentation.show_event(game, reason_event)
	proof24("enemy-intent")
	check(game.phase_banner.text == "Objective", "B6 enemy action displays intent reason")
	game.playing_enemy_events = false
	game.cam.skip_requested = true; game.cam.finish()
	check(game.cam.trace.has("camera_return24") or not game.cinematic, "enemy camera releases input")
	game.cam.skip_requested = false
	var jedi: Dictionary = {}
	for unit in game.mission.living("player"):
		if str(unit.get("model", "")) == "jedi" and not preload("res://scripts/characters/jedi_models.gd").id_for(unit).is_empty(): jedi = unit; break
	check(not jedi.is_empty(), "named Jedi kill-camera fixture")
	if not jedi.is_empty():
		var kill_event := {"actor":int(jedi.id), "target":int(enemy.id), "to":Vector2i(enemy.x, enemy.y), "killed":true}
		var kill_start := Time.get_ticks_msec()
		await Killcam.play(game, kill_event)
		var kill_ms := Time.get_ticks_msec() - kill_start
		check(kill_ms <= 300, "W22 Jedi kill-camera stays <=300 ms: %d" % kill_ms)
		print("FEELCAM24 KILLCAM: %d ms" % kill_ms)
	game.queue_free()
	for i in range(3): await process_frame
	print("FEELCAM24 RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
