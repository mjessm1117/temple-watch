extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if args.size() else "menu"
	if args.has("--large"): root.size = Vector2i(1920,1080)
	var screen = load("res://scenes/%s.tscn" % ("dialogue" if mode == "debrief" else mode)).instantiate()
	if mode == "debrief":
		var story = load("res://scripts/story/story_engine.gd").new()
		screen.set_campaign_state(story.state)
		screen.show_scene(story.start_debrief({"mission_id":"relay","won":true}))
	root.add_child(screen)
	await create_timer(5).timeout
	if screen.has_method("_reveal"): screen._reveal()
	await create_timer(1.0).timeout
	var start := Time.get_ticks_usec()
	for i in 120: await process_frame
	var fps := 120000000.0 / float(Time.get_ticks_usec()-start)
	await RenderingServer.frame_post_draw
	var suffix := "-1920" if args.has("--large") else ""
	var path := "res://../docs/godot/shots/wave6-screens-%s%s.png" % [mode,suffix]
	var result := root.get_texture().get_image().save_png(path)
	print("SCREENSHOT ",path," status ",result," fps ",fps)
	quit(result)
