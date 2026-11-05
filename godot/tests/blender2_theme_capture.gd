extends SceneTree
## Same battle camera across all eight map themes for the shortlist.

func _initialize() -> void:
	capture.call_deferred()

func capture() -> void:
	var theme := ""
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--theme="): theme = arg.trim_prefix("--theme=")
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if theme.is_empty() or output.is_empty():
		quit(1); return
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.set_process(false)
	game.mission.spec["theme"] = theme
	game.terrain_seen_revision = -1
	game.pivot = Vector3(12.5, 0, 11.0)
	game.zoom = 17.0
	game.pitch = 0.95
	game.yaw = 0.2
	game._refresh()
	game._update_camera()
	game.hud.visible = false
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(output)
	print("BLENDER2 THEME %s %s" % [theme, error])
	quit(0 if error == OK else 1)
