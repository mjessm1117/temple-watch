extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var name := "briefing"
	if args.has("codex"): name = "codex"
	var packed: PackedScene = load("res://scenes/%s.tscn" % name)
	if packed == null:
		push_error("Missing scene: " + name)
		quit(1)
		return
	var screen := packed.instantiate()
	root.add_child(screen)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave5-story-%s.png" % name)
	var error: Error = screen.get_viewport().get_texture().get_image().save_png(path)
	print("STORY SCREENSHOT: %s (%s)" % [path, "ok" if error == OK else "error %d" % error])
	quit(0 if error == OK else 1)
