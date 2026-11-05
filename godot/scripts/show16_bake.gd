extends SceneTree
## Bake the seven named Jedi from their battle models into lightweight UI portraits.
const Jedi = preload("res://scripts/characters/jedi_models.gd")
const SIZE := Vector2i(256, 320)

func _initialize() -> void:
	call_deferred("bake")

func bake() -> void:
	var output := ProjectSettings.globalize_path("res://assets/portraits/jedi")
	DirAccess.make_dir_recursive_absolute(output)
	for id in Jedi.NAMES.values():
		var scene := Jedi.scene_for_id(str(id), null)
		if scene == null:
			push_error("Missing Jedi model: " + str(id))
			quit(1)
			return
		var viewport := SubViewport.new()
		viewport.size = SIZE
		viewport.own_world_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var environment := WorldEnvironment.new()
		var settings := Environment.new()
		settings.background_mode = Environment.BG_COLOR
		settings.background_color = Color("102430")
		settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		settings.ambient_light_color = Color("b9d5e1")
		settings.ambient_light_energy = 0.65
		environment.environment = settings
		viewport.add_child(environment)
		var model := scene.instantiate() as Node3D
		viewport.add_child(model)
		model.rotation.y = -0.20
		var key := DirectionalLight3D.new()
		key.rotation_degrees = Vector3(-35, -35, 0)
		key.light_energy = 1.8
		key.light_color = Color("f6ead7")
		viewport.add_child(key)
		var rim := DirectionalLight3D.new()
		rim.rotation_degrees = Vector3(-15, 150, 0)
		rim.light_energy = 1.2
		rim.light_color = Color("79cfff")
		viewport.add_child(rim)
		var camera := Camera3D.new()
		camera.position = Vector3(0, 1.46, 1.75)
		camera.fov = 33
		viewport.add_child(camera)
		camera.look_at(Vector3(0, 1.43, 0))
		camera.current = true
		for frame in 5: await process_frame
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		var save_error := image.save_png(output.path_join(str(id) + ".png"))
		print("SHOW16 PORTRAIT %s %s" % [id, save_error])
		viewport.queue_free()
		await process_frame
		if save_error != OK:
			quit(1)
			return
	quit()
