extends SceneTree
## Uniform-scale source versus side trim, clay and textured, rendered in a real window.
func _initialize() -> void: run.call_deferred()

func run() -> void:
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i(1920,1080)
	var sources := ["res://../art/meshy1c/cover_half_temple_v2.B.raw.glb","res://assets/maps/meshy1/cover_half_temple_v3.glb"]
	for i in 4:
		var doc := GLTFDocument.new(); var state := GLTFState.new()
		assert(doc.append_from_file(ProjectSettings.globalize_path(sources[i%2]),state) == OK)
		var model: Node3D = doc.generate_scene(state)
		var parts: Array = []
		preload("res://scripts/map_art_batch.gd").new().collect(model,Transform3D.IDENTITY,parts)
		var bounds := AABB(); var first := true
		for part in parts:
			var box: AABB = part.transform*part.mesh.get_aabb()
			bounds = box if first else bounds.merge(box); first = false
			if i < 2:
				var clay := StandardMaterial3D.new(); clay.albedo_color = Color("9a9fa6"); clay.roughness = 0.9
				for surface in part.mesh.get_surface_count(): part.mesh.surface_set_material(surface,clay)
		var factor := 0.8/bounds.size.y if i%2 == 0 else 1.0
		model.scale = Vector3.ONE*factor
		model.position = -Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
		var container := SubViewportContainer.new(); container.position = Vector2((i%2)*960,(i/2)*540); root.add_child(container)
		var viewport := SubViewport.new(); viewport.size = Vector2i(960,540); viewport.own_world_3d = true; container.add_child(viewport)
		var scene := Node3D.new(); viewport.add_child(scene); scene.add_child(model)
		var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR
		e.background_color = Color("28323c"); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color.WHITE; e.ambient_light_energy = 0.5; env.environment = e; scene.add_child(env)
		var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-45,-35,0); light.light_energy = 1.2; scene.add_child(light)
		var camera := Camera3D.new(); scene.add_child(camera); camera.fov = 35
		camera.position = Vector3(1.6,1.4,2.7); camera.look_at(Vector3(0,0.4,0)); camera.current = true
		var label := Label.new(); label.position = container.position+Vector2(25,20)
		label.text = ("B whole" if i%2 == 0 else "B side trim / v3") + (" / clay" if i < 2 else " / textured")
		label.text += "\nUniform W x H x D: %.3f x %.3f x %.3f" % [bounds.size.x*factor,bounds.size.y*factor,bounds.size.z*factor]
		root.add_child(label)
	await create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../docs/godot/shots/meshy1d-trim.png"))
	quit()
