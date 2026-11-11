extends SceneTree
const Presets = preload("res://scripts/gfx_theme_presets.gd")
const Effects = preload("res://scripts/fx.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	var graphics: Node = root.get_node("Graphics")
	check(graphics.effective == "low", "Compatibility fixture uses Low")
	var gate = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(gate)
	for i in 5: await process_frame
	graphics.apply_all()
	var env: Environment = gate.scene_view.world.environment
	var grade: Dictionary = Presets.low_grade(str(gate.mission.spec.get("theme", "temple")))
	check(env.fog_enabled and env.fog_density > 0.0 and env.fog_height_density > 0.0, "Low haze is active")
	check(is_equal_approx(env.adjustment_contrast, grade.contrast) and is_equal_approx(env.adjustment_saturation, grade.saturation), "Low uses theme grade")
	check(not gate.scene_view.sun.shadow_enabled, "Low key shadow stays within draw budget")
	var pool: Node = gate.get_node_or_null("Cine15PropPools")
	check(pool != null, "theme pool exists")
	if pool != null:
		var ambient = pool.get_node_or_null("LightfxAmbient")
		check(ambient != null and ambient.multimesh.instance_count == 5, "Low ambient pool cap")
		check(pool.find_children("*", "OmniLight3D", true, false).is_empty(), "Low adds no local lights")
		var contacts = pool.get_node_or_null("LightfxContactDarkening")
		check(contacts != null and contacts.multimesh.instance_count == 12, "contact darkening shares one draw")
	var fx: Node3D = gate.fx
	check(fx.get_node_or_null("LightfxBillboards") == null, "static scene avoids a billboard draw")
	fx.blast(Vector3(2, 1, 2))
	var billboards = fx.get_node_or_null("LightfxBillboards")
	check(billboards != null and billboards.multimesh.instance_count == 12, "Low billboard pool cap")
	check(billboards.cursor > 0 and fx.get_child_count() < 24, "blast layers use bounded pool")
	check(fx._scorches.size() <= 12, "Low decal cap")
	fx._scorch(Vector3(2, 1, 2))
	fx._scorches.back().set_meta("born_ms", Time.get_ticks_msec() - 6000)
	fx._process(0.0)
	check(fx._scorches.is_empty(), "scorch expires within five seconds")
	for view in gate.views.values():
		if view.has_method("set_saber_halo"):
			check(view.get("saber_halo_enabled") == true or view.get_node_or_null("SaberHalo") != null, "halo enabled across tiers")
	gate.mission.spec.theme = "jungle"
	gate._build_terrain()
	graphics.apply_all()
	await process_frame
	var jungle_grade: Dictionary = Presets.low_grade("jungle")
	check(gate.scene_view.world.environment.fog_light_color.is_equal_approx(jungle_grade.fog), "jungle haze follows theme")
	check(gate.get_node_or_null("Cine15PropPools/LightfxAmbient").rise != 0.22, "jungle motes differ from embers")
	check(graphics.select_tier("medium", false) == OK and graphics.effective == "low", "Medium request falls back to Low on Compatibility")
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	if draws > 0: check(draws <= 270, "headless draw regression ceiling: %d" % draws)
	gate.queue_free()
	await process_frame
	print("lightfx23: %d checks, %d failures, draws=%d" % [checks, failures, draws])
	quit(1 if failures else 0)
