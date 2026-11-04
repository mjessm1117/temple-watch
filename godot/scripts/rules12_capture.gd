extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var phone := "--phone" in OS.get_cmdline_user_args()
	var size := Vector2i(844, 390) if phone else Vector2i(1366, 768)
	root.size = size
	root.content_scale_size = size
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.set_process(false)
	var squad: Array = game.mission.living("player")
	game.selected_id = int(squad[0].id)
	game.action = "move"
	game.pivot = Vector3(float(squad[0].x), 0.0, float(squad[0].y))
	game.zoom = 12.0
	game.pitch = 0.83
	game._update_camera()
	game._refresh()
	await create_timer(0.8).timeout
	game.phase_banner.visible = false
	for frame in 3: await process_frame
	var name := "wave12-rules-phone.png" if phone else "wave12-rules-desktop.png"
	var output := ProjectSettings.globalize_path("res://../docs/godot/shots/" + name)
	var err := root.get_texture().get_image().save_png(output)
	print("RULES12 CAPTURE: %s (%s)" % [output, error_string(err)])
	game.queue_free()
	quit(0 if err == OK else 1)
