extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Data = preload("res://scripts/campaign/data.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int = 5) -> void:
	for i in count: await process_frame

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var phone := "--phone" in args
	root.size = Vector2i(844,390) if phone else Vector2i(1366,768)
	DisplayServer.window_set_size(root.size)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://galaxy15-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story
	change_scene_to_file("res://scenes/galaxy.tscn")
	await frames(20)
	var view = current_scene
	check(view != null, "Galaxy scene loads")
	if view == null: quit(1); return
	var map = view.map_view
	check(map.planets.size() == Data.get_table("galaxy", "PLANETS").size(), "All planets present")
	for title in Data.get_table("galaxy", "PLANETS"):
		var surface: MeshInstance3D = map.planets[title].get_node("Surface")
		var material: ShaderMaterial = surface.material_override
		check(material != null and material.shader.resource_path.ends_with("galaxy15/planet.gdshader"), "Theme material: " + title)
		check(material.get_shader_parameter("land") != null and material.get_shader_parameter("ocean") != null, "Theme colors: " + title)
	var route: MeshInstance3D = map.world.get_node("TravelLines")
	check(route.get_meta("route_count") >= 7 and route.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() > 100, "Connected worlds have curved hyperspace routes")
	var sith: MeshInstance3D = map.world.get_node("SithTerritory")
	check(float(sith.material_override.get_shader_parameter("danger")) > 0.5, "Sith territory has a red tinted border")
	check(map.world.has_node("SpiralNebula") and map.world.has_node("Starfield"), "Spiral dust and parallax star field")
	if phone:
		check(not map.world.has_node("FarDust"), "Low has at most two backdrop layers")
		check(bool(map.planets["Ilum"].get_node("Surface").material_override.get_shader_parameter("low_mode")), "Low uses cheaper planet shading")
	else: check(map.world.has_node("FarDust"), "Desktop has distant dust layer")
	await create_timer(1.0).timeout
	var draws := 0
	var triangles := 0
	for i in 30:
		await process_frame
		draws = maxi(draws, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		triangles = maxi(triangles, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	print("GALAXY15 PERF %s: draws=%d primitives=%d renderer=%s" % ["phone" if phone else "desktop",draws,triangles,RenderingServer.get_current_rendering_method()])
	if phone and draws > 0: check(draws <= 117, "Low phone draw calls stay within 102 + 15%")
	if "--capture" in args:
		await RenderingServer.frame_post_draw
		var stage := "before" if "--before" in args else "after"
		var size_name := "phone" if phone else "desktop"
		var path := "res://../docs/godot/shots/wave15-intfix-galaxy-%s-%s.png" % [stage,size_name] if "--intfix" in args else "res://../docs/godot/shots/wave15-galaxy-%s-%s.png" % [stage,size_name]
		check(root.get_texture().get_image().save_png(path) == OK, "Overview capture")
		print("GALAXY15 SHOT " + path)
	view._select(0)
	await frames(30)
	check(not map.focused.is_empty() and map.zoom < map.overview_zoom, "Selecting a mission focuses its planet")
	check(view.page == "Briefing" and view.launch_button.visible, "Briefing remains reachable")
	if phone:
		var more: Button = view.find_child("BriefingMore", true, false)
		check(more != null and more.visible, "MORE button remains reachable on phone")
		if more != null: more.pressed.emit(); check(view.phone_more, "MORE opens full briefing")
	if "--capture" in args:
		await RenderingServer.frame_post_draw
		var selected_path := "res://../docs/godot/shots/wave15-intfix-galaxy-selected-%s.png" % ("phone" if phone else "desktop") if "--intfix" in args else "res://../docs/godot/shots/wave15-galaxy-selected-%s.png" % ("phone" if phone else "desktop")
		check(root.get_texture().get_image().save_png(selected_path) == OK, "Selected planet capture")
		print("GALAXY15 SHOT " + selected_path)
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("Galaxy15: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
