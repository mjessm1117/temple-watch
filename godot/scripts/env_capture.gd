extends SceneTree

# Reproducible art stills. Run with -s res://scripts/env_capture.gd -- overview|closeup.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	var overview := "overview" in OS.get_cmdline_user_args()
	if overview:
		game.pivot = Vector3(12.5, 0, 11.0)
		game.zoom = 51.0
		game.pitch = 1.02
	else:
		game.pivot = Vector3(14.5, 0, 19.0)
		game.zoom = 11.0
		game.pitch = 0.95
		game.yaw = 0.2
		# A staged camera view: the squad is posed behind the mission's real cover.
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
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://../docs/godot/shots/art-overview.png" if overview else "res://../docs/godot/shots/art-closeup.png"
	var error: Error = game.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("ART SCREENSHOT: %s (%s)" % [path, "ok" if error == OK else "error %d" % error])
	quit(0 if error == OK else 1)
