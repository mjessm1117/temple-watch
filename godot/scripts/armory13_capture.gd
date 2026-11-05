extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var phone := "phone" in args
	var phase := "before" if "before" in args else "after"
	root.size = Vector2i(844, 390) if phone else Vector2i(1366, 768)
	if "menu" in args:
		var menu = load("res://scenes/menu.tscn").instantiate()
		root.add_child(menu)
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		var menu_path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave13-armory-menu-%s.png" % ("phone" if phone else "desktop"))
		print("CAPTURE ", menu_path, " ", root.get_texture().get_image().save_png(menu_path))
		quit(); return
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://armory13-capture.json"
	flow.campaign = preload("res://scripts/campaign/state.gd").new()
	flow.active = true
	flow.campaign.state.launch_option = {"mission":"rescue", "n":"Detention Line"}
	flow.campaign.state.wings.forge = 2
	flow.campaign.state.research.done.append_array(["saberMk2", "saberMk3"])
	flow.campaign.state.res.credits = 500
	flow.campaign.state.res.kyber = 10
	flow.campaign.soldier("u1").gear.mk.s = 2
	var screen = load("res://scenes/squad.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.inspect(0)
	if "upgrade" in args: screen.arsenal._select_slot("weapon")
	await create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	print("PERF draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		" primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		" fps=", Engine.get_frames_per_second())
	var size_name := "phone" if phone else "desktop"
	var shot_name := "low-%s" % size_name if "low" in args else "%s-%s%s" % [phase, size_name, "-upgrade" if "upgrade" in args else ""]
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave13-armory-%s.png" % shot_name)
	print("CAPTURE ", path, " ", root.get_texture().get_image().save_png(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	quit()
