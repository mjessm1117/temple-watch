extends "res://scripts/map_preview.gd"
## Real scene coverage headlessly; --capture exercises the actual GPU/shader path.
const Campaign = preload("res://scripts/campaign/state.gd")
const Quality = preload("res://scripts/graphics_settings.gd")
var checks := 0
var graphics: Node
var rendered := false
var tier := "high"

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func frames(count := 4) -> void:
	for i in count: await process_frame

func run() -> void:
	graphics = root.get_node("Graphics")
	tier = graphics.requested
	rendered = DisplayServer.get_name() != "headless"
	root.size = Vector2i(1366,768); root.content_scale_size = root.size
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	check(Quality.default_tier("Android") == "low" and Quality.default_tier("iOS") == "low","mobile defaults Low")
	check(Quality.default_tier("Linux") == "high" and Quality.default_tier("Windows") == "high","desktop defaults High")
	check(Quality.effective_tier("high","gl_compatibility") == "low","GPU fallback overrides saved High")
	check(Quality.effective_tier("medium","forward_plus") == "medium","Forward+ retains Medium")
	check(ProjectSettings.get_setting("rendering/rendering_device/fallback_to_opengl3"),"automatic OpenGL fallback stays enabled")
	await persistence()
	await resource_checks()
	var seen: Dictionary = {}
	for id in ["sabotage","envoy","h_grove","ilum","fixture","archive","relay","h_husks","cache"]:
		await show_battle(id)
		await frames()
		graphics.apply_all()
		seen[str(game.mission.spec.get("theme","temple"))] = true
		var env: Environment = game.scene_view.world.environment
		check(env != null and game.terrain.get_child_count() > 0,"battle art loads: "+id)
		check(env.ssao_enabled == (graphics.effective == "high"),"SSAO tier: "+id)
		check(game.scene_view.sun.shadow_enabled == (graphics.effective != "low"),"shadow tier: "+id)
		if id == "cache":
			await live_switch()
			await damage_check()
			if rendered and "--capture" in OS.get_cmdline_user_args():
				await create_timer(3.0).timeout
				if "--benchmark" in OS.get_cmdline_user_args(): await sample()
				await save_shot(tier.replace("medium","med"))
		if rendered: await RenderingServer.frame_post_draw
		game.queue_free(); await frames()
	check(seen.size() == 8,"all eight battle themes loaded")
	var flow = root.get_node("CampaignFlow")
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story
	flow.save_path = "user://graphics-fixture-%d.json" % OS.get_process_id()
	for scene in ["temple","galaxy","menu"]:
		var view = load("res://scenes/%s.tscn" % scene).instantiate()
		root.add_child(view); await frames(8)
		graphics.apply_all()
		if rendered: await create_timer(0.5).timeout; await RenderingServer.frame_post_draw
		check(view.is_inside_tree(),scene+" screen loads")
		if scene == "temple":
			check(view.temple_view.rooms.size() == 22,"temple rooms remain present")
			view._change_page("Settings"); await frames()
			check(view.find_child("GraphicsTier",true,false) != null,"Graphics appears in existing Presentation settings")
		if scene == "galaxy": check(view.map_view.planets.size() == 14,"galaxy planets remain present")
		if scene == "menu":
			var options = view.find_child("GraphicsTier",true,false)
			check(options != null and options.item_count == 3,"player can select all three tiers")
			if rendered and tier == "high" and "--capture" in OS.get_cmdline_user_args(): await save_shot("settings")
		view.queue_free(); await frames()
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("Graphics %s (%s): %d checks, %d failures" % [tier,RenderingServer.get_current_rendering_method(),checks,failures])
	quit(1 if failures else 0)

func show_battle(id: String) -> void:
	var source = Mission.new(17) if id == "fixture" else Mission.new(17,"res://data/maps/%s.json" % id if id.begins_with("web_") else Maps.resolve(id))
	if "--authored" in OS.get_cmdline_user_args() and source.spec.has("elevation"):
		preload("res://scripts/map_art_elevation.gd").apply(source.board,source.spec.elevation)
	game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(game)
	# Let the initial viewport resources settle before rebuilding the fixture.
	await frames()
	game.mission = Combat.adopt(source)
	for view in game.figures.get_children():
		if view.name != "Prisoner": game.figures.remove_child(view); view.queue_free()
	game.views.clear(); game.selected_id = int(game.mission.living("player")[0].id)
	game.hud.queue_free(); game.portrait_viewport.queue_free(); game.portrait_kind = ""; game.action_buttons.clear(); game._build_ui()
	game._build_terrain(); game.terrain_seen_board = game.mission.board.duplicate(); game.terrain_seen_revision = game.mission.terrain_revision
	if game.mission.modern:
		game.pivot = Vector3(float(game.mission.spec.width)*0.5,0,float(game.mission.spec.height)*0.5)
		game.zoom = maxf(float(game.mission.spec.width),float(game.mission.spec.height))*1.3
	else:
		game.pivot = Vector3(9,0,17); game.zoom = 23.0
	game.pitch = 0.8; game.yaw = 0.3; game.action_camera = true
	game._update_camera(); game._refresh(); game.scene_view.arrange_labels()
	Input.warp_mouse(Vector2(960,60))
	await process_frame
	print("ART WINDOW: ",DisplayServer.window_get_size()," viewport ",root.get_visible_rect().size)

func persistence() -> void:
	var config := "user://graphics-test-%d.cfg" % OS.get_process_id()
	var overrides := config+".override"
	var kept := ConfigFile.new(); kept.set_value("test","untouched",42); kept.save(overrides)
	for value in ["low","medium","high"]:
		check(graphics.save_tier(value,config,overrides) == OK,"save "+value)
		check(graphics.read_tier(config) == value,"reload "+value)
		var loaded := ConfigFile.new(); loaded.load(overrides)
		var method := "gl_compatibility" if value == "low" else "forward_plus"
		check(loaded.get_value("rendering","renderer/rendering_method") == method and loaded.get_value("rendering","renderer/rendering_method.mobile") == method,"restart override "+value)
		check(loaded.get_value("test","untouched") == 42,"preserve unrelated override")
	kept = ConfigFile.new(); kept.set_value("graphics","tier","bogus"); kept.save(config)
	check(graphics.read_tier(config) == Quality.default_tier(),"invalid config defaults safely")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(config)); DirAccess.remove_absolute(ProjectSettings.globalize_path(overrides))

func damage_check() -> void:
	var art = game.terrain.get_child(0)
	var saved: Dictionary = game.mission.cover_hp.duplicate()
	game.mission.cover_hp[Vector2i(0,0)] = 3
	art.refresh_damage(); await frames()
	var expected := "MultiMeshInstance3D" if RenderingServer.get_current_rendering_method() == "gl_compatibility" else "Decal"
	check(art.damage_root.find_children("*",expected,true,false).size() > 0,"cover damage has a visible representation")
	game.mission.cover_hp = saved
	art.refresh_damage(); await frames()

func resource_checks() -> void:
	var pixels := Image.create(2048,512,false,Image.FORMAT_RGBA8)
	pixels.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(pixels)
	var material := StandardMaterial3D.new(); material.albedo_texture = texture
	var mesh := BoxMesh.new(); mesh.material = material
	var view := MeshInstance3D.new(); view.mesh = mesh; root.add_child(view)
	await frames()
	var resources = graphics.resources
	resources.apply(view,true)
	check(view.mesh.surface_get_material(0).albedo_texture.get_width() == 1024,"Low texture cap")
	check(texture.get_width() == 2048 and mesh.material == material,"source art remains untouched")
	resources.apply(view,false)
	check(view.mesh == mesh and mesh.material.albedo_texture == texture,"High restores original texture and mesh")
	view.queue_free(); await frames()

func live_switch() -> void:
	var before := hash([game.mission.board,game.mission.units,game.mission.cover_hp,game.mission.objective_state,game.mission.turn])
	for value in ["high","low","medium","high",tier]:
		check(graphics.select_tier(value,false) == OK,"live switch "+value)
		await frames()
		var env: Environment = game.scene_view.world.environment
		check(before == hash([game.mission.board,game.mission.units,game.mission.cover_hp,game.mission.objective_state,game.mission.turn]),"no gameplay mutation: "+value)
		check(env.glow_enabled == (graphics.effective != "low"),"live glow: "+value)
		var glow := float(preload("res://scripts/gfx_theme_presets.gd").get_preset("ruins").glow)
		check(is_equal_approx(env.glow_intensity,glow*(0.65 if graphics.effective == "medium" else 1.0)),"restored glow intensity: "+value)
		var lod_count := 0
		for instance in game.find_children("*","MultiMeshInstance3D",true,false):
			if not instance.has_meta("graphics_lod"): continue
			lod_count += 1
			if graphics.effective == "low":
				check(instance.visible == (int(instance.get_meta("graphics_lod")) == 1),"Low uses every LOD1 group")
				check(instance.visibility_range_begin == 0 and instance.visibility_range_end == 0,"Low LOD has no distance holes")
			elif graphics.effective == "high":
				check(instance.visible and instance.visibility_range_begin == instance.get_meta("graphics_visibility_range_begin") and instance.visibility_range_end == instance.get_meta("graphics_visibility_range_end"),"High restores every LOD range")
		check(lod_count > 2,"multiple LOD groups tested")
		for particle in game.find_children("*","GPUParticles3D",true,false)+game.find_children("*","CPUParticles3D",true,false):
			var baseline := int(particle.get_meta("graphics_amount"))
			check(particle.amount == maxi(1,roundi(baseline*(0.2 if graphics.effective == "low" else 0.5 if graphics.effective == "medium" else 1.0))),"live particles")

func save_shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://../docs/godot/shots/tiers-%s.png" % label) == OK,"capture "+label)

func sample() -> void:
	var times: Array[float] = []; var previous := Time.get_ticks_usec()
	var draws := 0; var triangles := 0
	for i in 600:
		await process_frame
		var now := Time.get_ticks_usec(); times.append(float(now-previous)/1000.0); previous = now
		draws = maxi(draws,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		triangles = maxi(triangles,int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	var total := 0.0
	for ms in times: total += ms
	times.sort()
	var result := {"tier":tier,"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"map":"cache","dimensions":"34x34","resolution":"1366x768","samples":times.size(),"fps_avg":1000.0/(total/times.size()),"fps_p95":1000.0/times[int(times.size()*0.05)],"frame_ms_p95":times[int(times.size()*0.95)],"fps_at_p95_frame":1000.0/times[int(times.size()*0.95)],"draw_calls_max":draws,"primitives_max":triangles}
	print("TIERS BENCHMARK: "+JSON.stringify(result))
	var file := FileAccess.open("res://../docs/godot/tiers/%s.json" % tier,FileAccess.WRITE); file.store_string(JSON.stringify(result,"\t")+"\n")
	if tier == "low":
		check(draws > 0 and draws <= 150,"Low draws <= 150: %d" % draws)
		check(triangles > 0 and triangles <= 300000,"Low primitives <= 300K: %d" % triangles)
