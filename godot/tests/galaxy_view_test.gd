extends SceneTree
const Data = preload("res://scripts/campaign/data.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Intel = preload("res://scripts/campaign/galaxy_intel.gd")
var checks := 0
var failures := 0
var capture := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func frames(count: int = 5) -> void:
	for i in count: await process_frame

func shot(label: String) -> void:
	if not capture: return
	await create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	var suffix := "-1920" if root.size.x == 1920 else ""
	var path := "res://../docs/godot/shots/wave6-galaxy-%s%s.png" % [label,suffix]
	check(root.get_texture().get_image().save_png(path) == OK,"capture " + label)
	print("GALAXY SCREENSHOT: " + path)

func run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	root.size = Vector2i(1920,1080) if "--large" in OS.get_cmdline_user_args() else Vector2i(1366,768)
	DisplayServer.window_set_size(root.size)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://galaxy-view-test-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story
	change_scene_to_file("res://scenes/galaxy.tscn"); await frames()
	var view = current_scene
	check(view != null,"Galaxy scene loads")
	if view == null: quit(1); return
	var map = view.map_view
	print("GALAXY VIEWPORT: window %s, root %s, map %s, 3D %s" % [DisplayServer.window_get_size(),root.size,map.size,map.viewport.size])
	check(map.planets.size() == Data.get_table("galaxy","PLANETS").size(),"Every data planet has a 3D node")
	for title in Data.get_table("galaxy","PLANETS"):
		check(map.planets.has(title) and map.planets[title].has_node("Surface") and map.planets[title].has_node("Atmosphere"),"Rendered biome and atmosphere: " + title)
	check(map.regions.size() == Data.get_table("galaxy","REGIONS").size(),"Every region has a node")
	check(map.offers.size() == flow.campaign.state.options.size(),"Every mission offer has a marker")
	check(view.detail.size.x <= 365,"Briefing fits the sidebar")
	check(map.size.x >= 400 and map.size.y >= 330,"Map fits minimum readable size")
	await shot("overview")
	for title in map.planets:
		check(Rect2(Vector2(10,10),map.size-Vector2(20,20)).has_point(map.projected(map.planets[title].position)),"Overview includes %s (%s in %s)" % [title,map.projected(map.planets[title].position),map.size])
	if capture and root.size.x == 1920:
		var timings: Array[float] = []; var previous := Time.get_ticks_usec()
		for sample in 180:
			await process_frame
			var now := Time.get_ticks_usec(); timings.append(float(now-previous)/1000.0); previous = now
		timings.sort()
		print("GALAXY PERFORMANCE: median %.2f ms, p95 %.2f ms, %d frames at 1920x1080" % [timings[90],timings[171],timings.size()])
	var first_position: Vector3 = map.planets["Ilum"].position
	await frames(10)
	check(map.planets["Ilum"].position != first_position,"Planet orbit drifts")
	for row in Data.get_table("galaxy","REGIONS"):
		view._region(str(row[0])); check(view.region == row[0] and view.page == "Regions","Region is reachable: " + str(row[0]))
	view._planet("Ilum"); await frames()
	check(map.focused == "Ilum" and view.page == "Regions","Quiet planet flies to regional panel")
	view._back(); check(map.focused.is_empty() and is_equal_approx(map.zoom,79.0),"Back restores overview and zoom without leaving scene")
	for tab in ["Briefing","Regions","Field ops","Teams"]:
		view._tab(tab); check(view.page == tab,"Reachable tab: " + tab)
	flow.campaign.state.unrest.outer = 4; flow.campaign.state.orderDark = 32
	view._tab("Field ops"); view._toggle_field("u1"); view._toggle_field("u2"); view._send_field("convoy")
	check(flow.campaign.state.field.list.size() == 1 and map.ships.size() == 1,"Field team has a traveling shuttle")
	check(flow.campaign.soldier("u1").assign != "","Field deployment reserves the selected soldiers")
	flow.campaign.state.ops = {"list":[{"id":"op-proof","k":"ritual","st":"open"}],"mods":[]}
	map.refresh_signals()
	check(map.operations.size() == 1,"Active Sith operation gets a map marker")
	var op_planet := Intel.operation_planet(flow.campaign,flow.campaign.state.ops.list[0])
	map._pick(map.projected(map.planets[op_planet].position)+Vector2(-26,-25))
	check(view.page == "Regions" and view.region == Data.get_table("galaxy","PLANETS")[op_planet].reg,"Sith marker opens its region intelligence")
	view._region("outer"); await shot("darkness")
	check(Intel.unrest(flow.campaign,"outer") == 4,"Regional unrest uses campaign state")
	view._tab("Field ops"); await shot("field-ops")
	# Independent offers on the same planet must preserve their original indexes.
	var original: Array = flow.campaign.state.options.duplicate(true)
	var second: Dictionary = original[0].duplicate(true); second.n = "Parallel relay signal"
	flow.campaign.state.options.append(second); map.refresh_signals()
	check(map.marker_position(0).distance_to(map.marker_position(1)) > 30,"Co-located offers remain individually clickable")
	flow.campaign.state.options = original; map.refresh_signals()
	var mission_id := str(original[0].mission)
	var click := InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT
	click.position = map.marker_position(0); click.pressed = true; map.gui_input.emit(click)
	click.pressed = false; map.gui_input.emit(click); await frames()
	check(map.focused == Intel.planet_for(flow.story.mission(mission_id)),"Offer flies to the correct planet")
	await create_timer(0.45).timeout
	await shot("briefing")
	check(view.detail.position.x < 1.0,"Briefing slide settles inside sidebar")
	view._launch(); await frames()
	check(current_scene.scene_file_path.ends_with("briefing.tscn"),"Selected offer opens existing briefing")
	check(str(flow.campaign.state.launch_option.mission) == mission_id,"Briefing receives unchanged mission ID")
	check(int(flow.campaign.state.launch_index) == 0,"Briefing receives unchanged offer index")

	# A different offer, not just index zero, must retain its identity through launch.
	second.mission = "rescue"; second.n = "Identity test rescue"
	flow.campaign.state.options.append(second)
	change_scene_to_file("res://scenes/galaxy.tscn"); await frames()
	view = current_scene; map = view.map_view
	map._pick(map.marker_position(1)); await frames()
	check(view.selected == 1,"Picking second marker selects its original index")
	view._launch(); await frames()
	check(str(flow.campaign.state.launch_option.mission) == "rescue" and int(flow.campaign.state.launch_index) == 1,"Second offer launches its own mission ID, not first offer")
	flow.campaign.state.options = []
	change_scene_to_file("res://scenes/galaxy.tscn"); await frames()
	view = current_scene; view._launch()
	check(current_scene == view and view.launch_button.disabled,"Empty campaign stays safe with launch disabled")
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("Galaxy view: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
