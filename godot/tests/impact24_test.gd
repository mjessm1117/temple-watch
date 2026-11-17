extends SceneTree

const Effects = preload("res://scripts/fx.gd")
const Audio = preload("res://scripts/audio.gd")
const UnitView = preload("res://scripts/unit_view.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Impact35 = preload("res://scripts/w31c_impact.gd")
class ImpactMission:
	extends RefCounted
	var spec := {}
	func unit_by_id(_id: int) -> Dictionary: return {}
class ImpactHost:
	extends Node3D
	signal battle_event(kind: String, actor_id: String, target_id: String, context: Dictionary)
	var views: Dictionary = {}
	var camera: Camera3D
	var mission := ImpactMission.new()
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func arg(key: String, fallback := "") -> String:
	for item in OS.get_cmdline_user_args():
		if item.begins_with(key + "="): return item.get_slice("=", 1)
	return fallback

func run() -> void:
	if arg("--match-legacy") == "true":
		await legacy_capture()
		return
	if arg("--perf") == "true":
		await perf()
		return
	var sound := Audio.new()
	root.add_child(sound)
	for kind in ["blaster", "saber", "force", "miss"]:
		sound.impact_layers24(kind)
		check(sound._voices.any(func(voice: AudioStreamPlayer): return voice.playing), "B3 %s layered sound" % kind)
	var fx := Effects.new()
	var host := ImpactHost.new()
	root.add_child(host)
	host.add_child(fx)
	var children_before := fx.get_child_count()
	fx.impact24_cue("unknown", Vector3.ZERO)
	check(fx.get_child_count() == children_before, "Contract 5 unknown cue has no effect")
	for kind in ["hit", "crit", "kill", "saber", "force"]:
		fx.impact24_cue(kind, Vector3(0, 1, 0))
	check(fx._billboards != null and fx._billboards.cursor > 0, "B3 pooled emissive shapes and sparks")
	fx.impact24_cue("miss_near", Vector3(1, 1, 0))
	check(fx._scorches.size() == 1, "B11 surface scorch on near miss")
	var scorch_pos: Vector3 = fx._scorches.back().position
	check(scorch_pos.distance_to(Vector3(1, 0.018, 0)) < 0.2, "B11 scorch lands beside target")
	fx.bolt(Vector3(-3, 1, 0), Vector3(0, 1, 0), false, true)
	await create_timer(0.4).timeout
	check(fx._scorches.size() >= 2 and fx._scorches.back().position.x > 1.0, "B11 missed bolt passes target before surface hit")
	var before_land: int = fx._billboards.cursor
	fx.impact24_cue("leap_land", Vector3(0, 1, 0))
	check(fx.get_children().any(func(node: Node): return node is MeshInstance3D), "B8 landing shock ring")
	check(fx._billboards.cursor != before_land, "B8 landing dust uses billboard pool")
	fx.impact24_cue("cover_break", Vector3(0, 1, 0))
	check(fx.get_child_count() > children_before + 1, "B14 cover chunks")
	var view := UnitView.new()
	root.add_child(view)
	view.setup({"id": 1, "side": "player", "class_name": "Soldier", "model": "trooper"}, load("res://assets/models/units/trooper.glb"), Vector3.ZERO)
	host.views[1] = view
	fx.impact24_cue("miss_near", Vector3(0, 1, 0))
	check(view.pose_motion != null and view.pose_motion.is_running(), "B11 near miss flinches target")
	view.travel24([Vector3(1, 0, 0)], false)
	var walk_frames := 0
	while view.position.distance_to(Vector3(1, 0, 0)) > 0.02 and walk_frames < 100:
		await process_frame
		walk_frames += 1
	view.position = Vector3.ZERO
	view.travel24([Vector3(1, 0, 0)], true)
	var dash_frames := 0
	while view.position.distance_to(Vector3(1, 0, 0)) > 0.02 and dash_frames < 100:
		await process_frame
		dash_frames += 1
	check(is_equal_approx(UnitView.travel_speed24(true) / UnitView.travel_speed24(false), 1.4) and dash_frames < 100 and walk_frames < 100, "B7 dash cadence is 1.4x walk")
	check(view.footfalls >= 2, "B14 foot contacts trigger steps")
	view.position = Vector3.ZERO
	view.travel24([Vector3(1, 0, 0)], false, ["vault"])
	var peak_y := 0.0
	for i in 25:
		await process_frame
		peak_y = maxf(peak_y, view.position.y)
	check(peak_y > 0.2, "B7 vault segment has a hop")
	for kind in ["climb", "door"]:
		view.position = Vector3.ZERO
		view.travel24([Vector3(1, 0, 0)], false, [kind])
		peak_y = 0.0
		for i in 25:
			await process_frame
			peak_y = maxf(peak_y, view.position.y)
		check(peak_y > (0.18 if kind == "climb" else 0.07), "B7 %s segment has a step beat" % kind)
	view.position = Vector3.ZERO
	view.travel24([Vector3(1, 0, 0)], false, ["unknown"])
	peak_y = 0.0
	for i in 25:
		await process_frame
		peak_y = maxf(peak_y, view.position.y)
	check(peak_y < 0.01, "Contract 5 unknown route segment falls back to walk")
	var step_views: Array[Node3D] = []
	for i in 3:
		var step_view := UnitView.new()
		root.add_child(step_view)
		step_view.foot = AudioStreamPlayer.new()
		step_view.foot.stream = sound.sounds["step"]
		step_view.add_child(step_view.foot)
		step_view._footstep()
		step_views.append(step_view)
	var playing_steps := 0
	for step_view in step_views:
		if step_view.foot.playing: playing_steps += 1
	check(playing_steps <= 2, "B14 footsteps cap at two concurrent voices")
	for step_view in step_views: step_view.queue_free()
	check(UnitView.choose_fall24(Vector3(0, 0, -1)) == 0 and UnitView.choose_fall24(Vector3(0, 0, 1)) == 1 and UnitView.choose_fall24(Vector3(1, 0, 0)) == 2, "B9 hit direction selects three fall variants")
	var phone35 := SubViewport.new()
	phone35.size = Vector2i(390, 844)
	root.add_child(phone35)
	var host35 := ImpactHost.new()
	phone35.add_child(host35)
	var camera35 := Camera3D.new()
	phone35.add_child(camera35)
	camera35.current = true
	camera35.position = Vector3(0, 3, 8)
	camera35.look_at(Vector3(0, 1, 0))
	host35.camera = camera35
	var figures35 := Node3D.new()
	host35.add_child(figures35)
	var victim35 := UnitView.new()
	figures35.add_child(victim35)
	victim35.setup({"id": 35, "side": "enemy", "class_name": "Soldier", "model": "trooper"}, load("res://assets/models/units/trooper.glb"), Vector3.ZERO)
	host35.views[35] = victim35
	var shooter35 := UnitView.new()
	figures35.add_child(shooter35)
	shooter35.setup({"id": 36, "side": "player", "class_name": "Soldier", "model": "trooper"}, load("res://assets/models/units/trooper.glb"), Vector3(-2, 0, 0))
	host35.views[36] = shooter35
	host35.battle_event.emit("hit", "36", "35", {"damage": 2})
	var flashed35: Array[MeshInstance3D] = []
	Impact35._meshes(victim35.model, flashed35)
	check(flashed35.any(func(mesh: MeshInstance3D): return mesh.has_meta("d35_flash_active")), "D35 successful shot flashes target mesh")
	check(victim35.impact_motion35 != null and victim35.impact_motion35.is_running(), "D35 successful shot starts directional flinch")
	check(Impact35.spark_pool != null and Impact35.spark_pool.amount == 6, "D35 hit reuses six faction particles")
	host35.battle_event.emit("crit", "36", "35", {"damage": 4})
	check(int(camera35.get_meta("d35_shake_serial", 0)) > 0 and camera35.v_offset != 0.0, "D35 crit starts additive screen shake")
	await create_timer(0.28).timeout
	check(not flashed35.any(func(mesh: MeshInstance3D): return mesh.has_meta("d35_flash_active")), "D35 flash restores material after fade")
	check(absf(camera35.h_offset) < 0.001 and absf(camera35.v_offset) < 0.001, "D35 shake restores camera offsets")
	host35.battle_event.emit("miss", "36", "35", {"damage": 0})
	check(phone35.get_children().any(func(node: Node): return node is CPUParticles2D and node.name == "D35MissPuff"), "D35 missed shot emits dust puff")
	check(phone35.size == Vector2i(390, 844) and Impact35.spark_pool != null and phone35.get_children().filter(func(node: Node): return node is CPUParticles2D or node is GPUParticles2D).size() == 2, "D35 portrait impact uses two particle emitters within six draw calls")
	phone35.queue_free()
	view.fall24(99, Vector3.RIGHT)
	check(view.alive, "Contract 5 unknown fall variant has no effect")
	view.queue_free()
	for variant in 3:
		var body := UnitView.new()
		root.add_child(body)
		body.model = Node3D.new()
		body.add_child(body.model)
		body.fall24(variant, Vector3.RIGHT)
		await create_timer(0.82).timeout
		check(not body.alive and (absf(body.model.rotation.z) > 0.3 or absf(body.model.rotation.x) > 0.3), "B9 fall variant %d holds body" % variant)
		body.queue_free()
	var view_script: Script = UnitView
	var cap: Array = view_script.get("_corpses")
	check(UnitView.CORPSE_CAP == 6 and cap.size() <= 6, "B9 corpse cap persists")
	fx.impact24_cue("blast", Vector3(0, 1, 0))
	check(fx._billboards.capacity == 12, "B10 Low smoke uses bounded pool")
	await create_timer(1.55).timeout
	check(fx._billboards.slots.all(func(slot: Dictionary): return float(slot.age) >= float(slot.life)), "B10 smoke culls within 1.5 seconds")
	host.queue_free()
	sound.queue_free()
	await process_frame
	print("impact24: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func legacy_capture() -> void:
	var size_text := arg("--size", "1280x720").split("x")
	var size := Vector2i(int(size_text[0]), int(size_text[1]))
	root.size = size
	root.content_scale_size = size
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.set_process(false)
	game.phase_banner.hide()
	game.hud_controls.night.phase_plate.hide()
	var target: Dictionary = game.mission.living("player")[0]
	var victim: Node3D = game.views[int(target.id)]
	var at := victim.global_position + Vector3.UP * 1.1
	game.pivot = victim.global_position
	game.zoom = 10.0
	game._update_camera()
	var cue := arg("--cue")
	match cue:
		"hit":
			game.fx.bolt(at + Vector3(-2.5, 0.25, 0), at, false, false)
			game.fx.impact24_cue("hit", at)
			victim.act("hit")
		"kill": victim.fall24(2, Vector3.RIGHT)
		"blast": game.fx.ability("grenade", at + Vector3(-2.5, 0, 0), at)
	await create_timer(1.2 if cue == "kill" else 0.35 if cue == "blast" else 0.09).timeout
	game.phase_banner.hide()
	game.hud_controls.night.phase_plate.hide()
	await RenderingServer.frame_post_draw
	var capture_error := root.get_texture().get_image().save_png(arg("--output"))
	print("IMPACT24_LEGACY_CAPTURE %s %s error=%d" % [cue, str(size), capture_error])
	game.queue_free()
	await process_frame
	quit(0 if capture_error == OK else 1)

func sample(frames: int, capture_path: String = "") -> Dictionary:
	var times: Array[float] = []
	var peak_draws := 0
	var peak_tris := 0
	var previous := Time.get_ticks_usec()
	for i in frames:
		await process_frame
		if i == 4 and capture_path != "":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(capture_path)
		var now := Time.get_ticks_usec()
		times.append(float(now - previous) / 1000.0)
		previous = now
		peak_draws = maxi(peak_draws, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		peak_tris = maxi(peak_tris, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	times.sort()
	return {"p95_ms": times[mini(int(times.size() * 0.95), times.size() - 1)], "peak_ms": times.back(), "peak_draws": peak_draws, "peak_tris": peak_tris}

func perf() -> void:
	var size_text := arg("--size", "390x844").split("x")
	var size := Vector2i(int(size_text[0]), int(size_text[1]))
	DisplayServer.window_set_size(size)
	root.size = size
	root.content_scale_size = size
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://impact24-perf-%d.json" % OS.get_process_id()
	var campaign = Campaign.new("normal")
	campaign.select_mission(0)
	campaign.state.flow_stage = "battle"
	flow.campaign = campaign
	flow.story = campaign.story
	flow.active = true
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 20: await process_frame
	flow.active = false
	game.demo_mode = true
	game.animate_headless = true
	game.phase_banner.hide()
	var target: Dictionary = game.mission.living("enemy")[0]
	var at: Vector3 = game.views[int(target.id)].global_position + Vector3.UP
	game.pivot = at
	game.zoom = 12.0
	game._update_camera()
	for i in 12: await process_frame
	var cue := arg("--cue")
	if cue != "":
		if game.hud_controls.phone != null and game.hud_controls.phone.alerts != null:
			game.hud_controls.phone.alerts.hide()
			game.hud_controls.phone.alerts.set_process(false)
		match cue:
			"hit":
				game.fx.impact24_cue("hit", at)
				game.views[int(target.id)].act("hit")
			"miss": game.fx.bolt(at + Vector3(-3, 0, 0), at, false, true)
			"fall": game.views[int(target.id)].fall24(2, Vector3.RIGHT)
			"blast": game.fx.impact24_cue("blast", at)
			"move": game.views[int(target.id)].travel24([game.views[int(target.id)].position + Vector3.RIGHT], true, ["vault"])
		var capture_delay := 0.62 if cue == "fall" else 0.35 if cue == "blast" else 0.24 if cue == "miss" else 0.13 if cue == "move" else 0.07
		await create_timer(capture_delay).timeout
		await RenderingServer.frame_post_draw
		var capture_error := root.get_texture().get_image().save_png(arg("--output"))
		print("IMPACT24_CAPTURE %s %s error=%d" % [cue, str(size), capture_error])
		game.queue_free()
		await process_frame
		quit(0 if capture_error == OK else 1)
		return
	var idle := await sample(35)
	game.fx.blast(at)
	var output := arg("--output")
	var blast := await sample(45, output)
	print("IMPACT24_PERF " + JSON.stringify({"size": str(size), "adapter": RenderingServer.get_video_adapter_name(), "idle": idle, "blast": blast}))
	game.queue_free()
	await process_frame
	quit()
