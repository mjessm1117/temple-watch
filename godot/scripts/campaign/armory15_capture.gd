extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var phone := "phone" in args
	var phase := "before" if "before" in args else "after"
	root.size = Vector2i(844, 390) if phone else Vector2i(1366, 768)
	DisplayServer.window_set_size(root.size)
	root.content_scale_size = root.size
	var graphics = root.get_node("Graphics")
	graphics.effective = "low" if phone else "high"
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://armory15-capture.json"
	flow.campaign = preload("res://scripts/campaign/state.gd").new()
	flow.active = true
	flow.campaign.state.launch_option = {"mission":"rescue", "n":"Detention Line"}
	flow.campaign.state.wings.forge = 2
	flow.campaign.state.research.done.append_array(["saberMk2", "saberMk3"])
	flow.campaign.state.res.credits = 500
	flow.campaign.state.res.kyber = 10
	flow.campaign.soldier("u1").gear.mk.s = 2
	if "different" in args:
		flow.campaign.soldier("u1").col = "#c58cff"
		flow.campaign.soldier("u1").gear.armor = "armoredRobes"
	if "--intfix-kira" in args:
		flow.campaign.soldier("u1").gear.armor = "armoredRobes"
		flow.campaign.soldier("u1").gear.mk["armor:armoredRobes"] = 2
	if "trooper" in args:
		flow.campaign.soldier("u3").gear.armor = "heavy"
		flow.campaign.soldier("u3").gear.mk["armor:heavy"] = 2
	var screen = load("res://scenes/squad.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	if "--intfix-dax" in args:
		var dax_index: int = screen.selected.find("u3")
		screen.inspect(dax_index if dax_index >= 0 else 2)
	else:
		screen.inspect(2 if "trooper" in args else 0)
	screen.arsenal._select_slot("weapon")
	await create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	var draws := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var tris := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var fps := Engine.get_frames_per_second()
	var suffix := "phone-low" if phone else "desktop-high"
	var variant := "-different" if "different" in args else "-trooper" if "trooper" in args else ""
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave15-intfix-armory-%s.png" % ("dax-desktop-high" if "--intfix-dax" in args else "kira-desktop-high")) if "--intfix-kira" in args or "--intfix-dax" in args else ProjectSettings.globalize_path("res://../docs/godot/shots/wave15-armory-%s-%s%s.png" % [phase, suffix, variant])
	print("ARMORY15 PERF %s %s%s draws=%d triangles=%d fps=%d" % [phase, suffix, variant, draws, tris, fps])
	print("ARMORY15 SHOT %s result=%d" % [path, root.get_texture().get_image().save_png(path)])
	screen.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	quit()
