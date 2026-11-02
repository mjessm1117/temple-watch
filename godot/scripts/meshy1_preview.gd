extends SceneTree
## Loads external previews without copying losing assets into the shipped tree.
func _initialize() -> void: run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	var args := OS.get_cmdline_user_args()
	var source := ProjectSettings.globalize_path("res://../art/" + ("meshy1b/" if args[0].begins_with("cover_half_temple_v2") else "meshy1/") + args[0])
	var doc := GLTFDocument.new(); var state := GLTFState.new()
	assert(doc.append_from_file(source,state) == OK)
	var model: Node3D = doc.generate_scene(state)
	var batch := preload("res://scripts/map_art_batch.gd").new()
	var parts: Array = []; batch.collect(model,Transform3D.IDENTITY,parts)
	var clay := StandardMaterial3D.new(); clay.albedo_color = Color("9a9fa6"); clay.roughness = 0.9
	for part in parts:
		if "--textured" not in args:
			for surface in part.mesh.get_surface_count(): part.mesh.surface_set_material(surface,clay)
	var bounds := AABB(); var first := true
	for part in parts:
		var box: AABB = part.transform*part.mesh.get_aabb()
		bounds = box if first else bounds.merge(box); first = false
	var height := 1.18 if args[0].begins_with("obj") else 0.8
	var width := 0.8 if args[0].begins_with("obj") else 1.0
	var factor := width/maxf(bounds.size.x,bounds.size.z)
	var fit := Vector3.ONE*minf(factor,height/bounds.size.y)
	model.scale = fit; model.position = -Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*fit
	for i in 2:
		var container := SubViewportContainer.new(); container.position = Vector2(i*640,0); container.size = Vector2(640,720); root.add_child(container)
		var viewport := SubViewport.new(); viewport.size = Vector2i(640,720); viewport.own_world_3d = true; container.add_child(viewport)
		var scene := Node3D.new(); viewport.add_child(scene)
		scene.add_child(model.duplicate())
		var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color("28323c"); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color.WHITE; e.ambient_light_energy = 0.4; env.environment = e; scene.add_child(env)
		var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-45,-35,0); light.light_energy = 1.2; scene.add_child(light)
		var camera := Camera3D.new(); scene.add_child(camera)
		camera.fov = 40 if i == 0 else 75
		camera.position = Vector3(1.5,1.6,2.3) if i == 0 else Vector3(5.3,18.0,16.5)
		camera.look_at(Vector3(0,height*0.45,0)); camera.current = true
		var label := Label.new(); label.text = args[0] + (" / close" if i == 0 else " / ~25 units"); label.position = Vector2(i*640+15,15); root.add_child(label)
	model.free()
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(source.replace(".glb",".png"))
	quit()
