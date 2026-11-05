extends SceneTree
## Battle-camera A/B, with both GLBs loaded in the same live rescue scene.

func _initialize() -> void:
	capture.call_deferred()

func capture() -> void:
	var model := ""
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--model="): model = arg.trim_prefix("--model=")
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if model.is_empty() or output.is_empty():
		push_error("Need --model=relative/path.glb and --output=path")
		quit(1); return
	var original := "res://assets/" + model
	var candidate := "res://assets/models_v2/" + model.get_file().trim_suffix(".glb") + "_v2.glb"
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.set_process(false)
	game.pivot = Vector3(14.5, 0, 19.0)
	game.zoom = 11.0 if model.begins_with("models/units/") else 17.0
	game.pitch = 0.95
	game.yaw = 0.2
	game._refresh()
	for view in game.views.values(): view.visible = false
	var is_unit := model.begins_with("models/units/")
	var group := Node3D.new()
	game.add_child(group)
	var prop_scale := {
		"relay": Vector3.ONE,
		"gantry": Vector3(2.5 / 0.638, 6.4 / 1.896, 2.5 / 0.638),
		"statue": Vector3(2.1 / 0.683, 5.8 / 1.898, 2.1 / 0.683),
		"shuttle": Vector3(7.5 / 1.895, 3.2 / 0.485, 7.5 / 1.895)
	}
	var base_y := {"relay": -0.951, "gantry": -0.947, "statue": -0.951, "shuttle": -0.243}
	for index in 2:
		var path := original if index == 0 else candidate
		var instance: Node3D = load(path).instantiate()
		group.add_child(instance)
		instance.position = Vector3(12.5 + index * 4.0, 0, 19)
		instance.scale = Vector3.ONE * 1.2 if is_unit else prop_scale.get(model.get_file().trim_suffix(".glb"), Vector3.ONE)
		if not is_unit:
			instance.position.y = -float(base_y.get(model.get_file().trim_suffix(".glb"), 0.0)) * instance.scale.y
		var label := Label3D.new()
		label.text = "ORIGINAL" if index == 0 else "V2"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 28
		label.pixel_size = 0.005
		label.outline_size = 8
		label.position = Vector3(0, 2.5 if is_unit else 6.0, 0)
		instance.add_child(label)
	game._update_camera()
	game.hud.visible = false
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(output)
	print("BLENDER2 CAPTURE %s %s %s" % [model, image.get_size(), error])
	quit(0 if error == OK else 1)
