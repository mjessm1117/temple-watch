extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	var args := OS.get_cmdline_user_args()
	var mode := "move"
	for item in args:
		if item in ["move", "flank", "reinforcement"]: mode = item
	game.action_camera = false
	if mode == "move":
		game.pivot = Vector3(6, 0, 21)
		game.zoom = 18.0
		game.pitch = 0.92
		var destination := Vector2i(4, 20)
		game.preview_tile = destination
		game.hovered = destination
		game._refresh()
	elif mode == "flank":
		var soldier: Dictionary = game.mission.living("player")[2]
		var enemy: Dictionary = game.mission.living("enemy")[0]
		enemy.x = 10; enemy.y = 21; enemy.awake = true
		game.mission.set_tile(Vector2i(11, 21), "c")
		game.selected_id = int(soldier.id)
		game.pivot = Vector3(8, 0, 21)
		game.zoom = 16.0
		game.pitch = 0.9
		game._refresh()
		game._choose_action("shoot")
		if not game.shot_label.text.contains("FLANKED"):
			push_error("Flank capture has no flank breakdown")
			quit(1)
			return
	else:
		for i in range(3): game.mission.end_turn()
		game.pivot = Vector3(23, 0, 15)
		game.zoom = 16.0
		game.pitch = 0.9
		game._refresh()
		if not game.reinforcement_view.visible:
			push_error("Reinforcement capture has no entry marker")
			quit(1)
			return
	game._update_camera()
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave4-final-%s.png" % mode)
	var error: Error = game.get_viewport().get_texture().get_image().save_png(path)
	print("FINAL SCREENSHOT: %s (%s)" % [path, "ok" if error == OK else "error %d" % error])
	quit(0 if error == OK else 1)
