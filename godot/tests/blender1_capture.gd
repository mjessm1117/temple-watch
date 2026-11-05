extends SceneTree
## Baseline battle-camera captures for the Blender 1 asset audit.

func _initialize() -> void:
	capture.call_deferred()

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var subject := "units"
	var output := ""
	for arg in args:
		if arg.begins_with("--subject="): subject = arg.trim_prefix("--subject=")
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if output.is_empty() or subject not in ["units", "props"]:
		push_error("Specify --subject=units|props and --output=path")
		quit(1)
		return
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.set_process(false)
	if subject == "units":
		var squad: Array = game.mission.living("player")
		for i in range(mini(squad.size(), 4)):
			squad[i].x = 13 + i
			squad[i].y = 19 + i % 2
		game.pivot = Vector3(14.5, 0, 19.0)
		game.zoom = 11.0
	else:
		game.pivot = Vector3(12.5, 0, 11.0)
		game.zoom = 17.0
	game.pitch = 0.95
	game.yaw = 0.2
	game._refresh()
	if subject == "units":
		for unit in game.mission.living("player"):
			var view: Node3D = game.views[int(unit.id)]
			if view.motion != null: view.motion.kill()
			view.position = Vector3(int(unit.x), 0, int(unit.y))
	game._update_camera()
	game.hud.visible = false
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(output)
	print("BLENDER1 CAPTURE %s %s %s" % [subject, image.get_size(), error])
	quit(0 if error == OK else 1)
