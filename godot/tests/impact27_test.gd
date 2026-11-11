extends SceneTree

const FX = preload("res://scripts/fx.gd")
const Sound = preload("res://scripts/audio.gd")
const UnitView = preload("res://scripts/unit_view.gd")
const Signature = preload("res://scripts/w27d_ability_signature.gd")
const FeelBeats = preload("res://scripts/w24_feelcam_beats.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func arg(key: String, fallback := "") -> String:
	for item in OS.get_cmdline_user_args():
		if item.begins_with(key + "="): return item.get_slice("=", 1)
	return fallback

func run() -> void:
	if arg("--impact-cue") != "":
		await capture()
		return
	var sound := Sound.new()
	root.add_child(sound)
	var fx := FX.new()
	root.add_child(fx)
	var shapes := {}
	var sounds := {}
	var timings := {}
	for id in ["rapidFire", "suppress", "push", "pull", "forceHeal", "barrier", "saberThrow", "grenade"]:
		var profile: Dictionary = Signature.profile(id)
		check(not profile.is_empty(), id + " signature")
		shapes[profile.get("shape", "")] = true
		sounds[profile.get("sound", "")] = true
		timings[profile.get("spacing", 0.0)] = true
		check(sound.sounds.has(str(profile.get("sound", ""))), id + " synthesized cue")
		var before_cursor: int = fx._billboards.cursor if fx._billboards != null else 0
		var before_mesh := 0
		for node in fx.get_children():
			if node is MeshInstance3D: before_mesh += 1
		fx.ability(id, Vector3(-2, 1, 0), Vector3(0, 1, 0))
		await create_timer(0.025).timeout
		var after_mesh := 0
		for node in fx.get_children():
			if node is MeshInstance3D: after_mesh += 1
		check((fx._billboards != null and fx._billboards.cursor != before_cursor) or after_mesh > before_mesh, id + " creates visible geometry")
		if id == "barrier":
			check(fx.get_children().any(func(node: Node) -> bool: return node is MeshInstance3D and node.mesh is CylinderMesh and node.mesh.radial_segments == 6), "barrier has hexagonal silhouette")
	check(shapes.size() == 8 and sounds.size() == 8 and timings.size() == 8, "eight distinct shape, timing, and sound families")
	check(fx.impact_budget27().particles_max <= 12 and fx.impact_budget27().draws_per_beat <= 4, "bounded impact budget")
	var camera := Camera3D.new()
	root.add_child(camera)
	var overlay := Control.new()
	root.add_child(overlay)
	fx.setup(camera, overlay)
	camera.position = Vector3(0, 0, 8)
	var near := fx.contact_scale27(Vector3.ZERO)
	camera.position = Vector3(0, 0, 32)
	var far := fx.contact_scale27(Vector3.ZERO)
	check(far > near * 1.5, "contact size grows with camera distance")
	var view := UnitView.new()
	root.add_child(view)
	view.setup({"id":3, "side":"enemy", "class_name":"Soldier", "model":"trooper"}, load("res://assets/models/units/trooper.glb"), Vector3.ZERO)
	view.travel24([Vector3(1,0,0), Vector3(2,0,0), Vector3(3,0,0)], true, ["vault", "climb", "door"])
	await create_timer(1.0).timeout
	for kind in ["vault", "climb", "door"]:
		check(view.route_beats27.has(kind + "_contact") and view.route_beats27.has(kind + "_land"), kind + " contact and landing")
	fx.bolt(Vector3(-3,1,0), Vector3(0,1,0), false, true)
	fx.float_text(Vector3(0,2,0), "MISS", Color.WHITE, true)
	FeelBeats.nudge(view, Vector3.RIGHT, true)
	check(overlay.get_children().any(func(node: Node) -> bool: return node is Label and node.text == "MISS"), "forced miss emits MISS text")
	await create_timer(0.4).timeout
	check(fx._scorches.size() > 0, "forced miss passes and scorches past target")
	view.fall24(-1, Vector3.RIGHT)
	check(view.route_beats27.any(func(beat: String) -> bool: return beat.begins_with("fall_")), "forced kill emits fall")
	print("IMPACT27 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func capture() -> void:
	var size_text := arg("--size", "844x390").split("x")
	var size := Vector2i(int(size_text[0]), int(size_text[1]))
	DisplayServer.window_set_size(size)
	root.size = size
	root.content_scale_size = size
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 15: await process_frame
	game.demo_mode = true
	game.set_process(false)
	game.phase_banner.hide()
	var target: Dictionary = game.mission.living("enemy")[0]
	target.awake = true
	target.spotted = true
	game._refresh_figures()
	var view: Node3D = game.views.get(int(target.id), game.views.values()[0])
	game.highlights.hide()
	game.range_highlights.hide()
	game.hover_highlights.hide()
	if view.status_label != null: view.status_label.hide()
	game.phase_banner.hide()
	game.hud_controls.night.phase_plate.hide()
	if game.hud_controls.phone != null and game.hud_controls.phone.alerts != null:
		game.hud_controls.phone.alerts.hide()
		game.hud_controls.phone.alerts.set_process(false)
	var at: Vector3 = view.global_position + Vector3.UP
	game.pivot = view.global_position
	game.zoom = 23.0
	game._update_camera()
	for i in 8: await process_frame
	var cue := arg("--impact-cue")
	match cue:
		"blaster": game.fx.bolt(at + Vector3.LEFT * 3, at, false, false)
		"saber": game.fx.saber(at + Vector3.LEFT * 2, at)
		"force": game.fx.ability("push", at + Vector3.LEFT * 2, at)
		"blast": game.fx.ability("grenade", at + Vector3.LEFT * 2, at)
		"miss":
			game.fx.bolt(at + Vector3.LEFT * 3, at, false, true)
			game.fx.float_text(at + Vector3.UP, "MISS", Color.WHITE, true)
			FeelBeats.nudge(view, Vector3.RIGHT, true)
		"kill":
			game.fx.impact24_cue("kill", at)
			game.fx.float_text(at + Vector3.UP, "KILL", Color("ffca70"), true)
			view.fall24(-1, Vector3.RIGHT)
		"move": view.travel24([view.position + Vector3.RIGHT], true, ["vault"])
		_:
			push_error("unknown capture cue " + cue)
			quit(1)
			return
	await create_timer(0.14 if cue == "move" else 0.10 if cue == "force" else 0.27 if cue == "blast" else 0.16 if cue in ["blaster", "saber"] else 0.30 if cue == "miss" else 0.18).timeout
	await RenderingServer.frame_post_draw
	var output := arg("--output")
	var error := root.get_texture().get_image().save_png(output)
	print("IMPACT27_CAPTURE %s %s error=%d" % [cue, str(size), error])
	quit(0 if error == OK else 1)
