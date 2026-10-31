extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1920, 1080)
	var mode := "galaxy" if "galaxy" in OS.get_cmdline_user_args() else "temple"
	var scene: PackedScene = load("res://scenes/%s.tscn" % mode)
	var view: Control = scene.instantiate()
	root.add_child(view)
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave5-campaign-%s.png" % mode)
	var shot := root.get_texture().get_image()
	if shot.get_width() != 1920 or shot.get_height() != 1080:
		shot.resize(1920, 1080, Image.INTERPOLATE_BILINEAR)
	var error := shot.save_png(path)
	print("CAMPAIGN SCREENSHOT: %s (%s)" % [path, "ok" if error == OK else "error %d" % error])
	quit(0 if error == OK else 1)
