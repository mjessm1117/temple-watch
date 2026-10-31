extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	game.pivot = Vector3(14.5, 0, 19.0)
	game.zoom = 11.0
	game.pitch = 0.95
	game.yaw = 0.2
	var squad = game.mission.living("player")
	for i in range(squad.size()):
		squad[i].x = [13, 14, 15, 16][i]
		squad[i].y = [19, 19, 20, 20][i]
	game._refresh()
	for unit in squad:
		var view = game.views[int(unit.id)]
		if view.motion != null: view.motion.kill()
		view.position = Vector3(int(unit.x), 0, int(unit.y))
	game._update_camera()
	game.hud.visible = false
	game.fx.bolt(Vector3(14, 1.2, 19), Vector3(18, 1.2, 17), false, false)
	await create_timer(0.09).timeout
	await RenderingServer.frame_post_draw
	var path := "res://../docs/godot/shots/wave4-fx-shot.png"
	var err: Error = game.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("FX SCREENSHOT: %s (%s)" % [path, "ok" if err == OK else "error %d" % err])
	quit(0 if err == OK else 1)
