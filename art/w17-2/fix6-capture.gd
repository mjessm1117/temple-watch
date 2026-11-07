extends SceneTree

const NAMES := ["trooper", "scout", "sniper", "heavy", "tech", "droid", "officer"]

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(384, 480)
	root.content_scale_size = root.size
	var stage := Node3D.new()
	root.add_child(stage)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("263342")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.72
	world.environment = env
	stage.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.light_energy = 1.25
	stage.add_child(light)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.current = true
	for kind in NAMES:
		var path: String = "res://assets/models/units/" + kind + ".glb" if kind in ["trooper", "scout"] else "res://assets/units/w17/" + kind + ".glb"
		var model: Node3D = load(path).instantiate()
		stage.add_child(model)
		model.scale = Vector3.ONE * (1.78 / 1.8)
		var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		for view in ["front", "three-quarter"]:
			camera.position = Vector3(0, 1.55, 4.7) if view == "front" else Vector3(2.5, 1.85, 4.7)
			camera.look_at(Vector3(0, 1.05, 0))
			camera.fov = 43
			if player:
				player.play("idle")
				player.advance(0.35)
			await process_frame
			await RenderingServer.frame_post_draw
			var filename: String = "/tmp/w17-fix6-" + kind + "-" + view + ".png"
			var err := root.get_texture().get_image().save_png(filename)
			assert(err == OK, "capture " + filename)
			print("W17_FIX6_CAPTURE ", filename)
		if kind not in ["trooper", "scout"]:
			camera.position = Vector3(2.5, 1.85, 4.7)
			camera.look_at(Vector3(0, 1.05, 0))
			player.play("shoot")
			player.advance(0.35)
			await process_frame
			await RenderingServer.frame_post_draw
			var filename: String = "/tmp/w17-fix6-" + kind + "-shoot.png"
			var err := root.get_texture().get_image().save_png(filename)
			assert(err == OK, "capture " + filename)
			print("W17_FIX6_CAPTURE ", filename)
		model.queue_free()
		await process_frame
	quit()
