extends SceneTree
## Neutral review only; does not modify game routing or collision.
const RAW = "res://../art/meshy4/"
const FINAL = "res://assets/maps/meshy4/"
var args: PackedStringArray

func _initialize() -> void:
	run.call_deferred()

func model(path: String, height: float = 0.0, width: float = 1.0, clay: bool = false) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	assert(doc.append_from_file(ProjectSettings.globalize_path(path), state) == OK)
	var result: Node3D = doc.generate_scene(state)
	var parts: Array = []
	var batch := preload("res://scripts/map_art_batch.gd").new()
	batch.collect(result, Transform3D.IDENTITY, parts)
	var bounds := AABB()
	var first := true
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("9a9fa6")
	material.roughness = 0.9
	for part in parts:
		var box: AABB = part.transform * part.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		if clay:
			for surface in part.mesh.get_surface_count():
				part.mesh.surface_set_material(surface, material)
	if height > 0:
		var factor := width / maxf(bounds.size.x, bounds.size.z)
		var fit := Vector3.ONE * minf(factor, height / bounds.size.y)
		result.scale = fit
		result.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * fit
	return result

func scene_in(viewport: Viewport) -> Node3D:
	var scene := Node3D.new()
	viewport.add_child(scene)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("28323c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.55
	world.environment = env
	scene.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	scene.add_child(light)
	return scene

func camera_in(scene: Node3D, position: Vector3, target: Vector3, fov: float) -> void:
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.fov = fov
	camera.position = position
	camera.look_at(target)
	camera.current = true

func label(text: String, at: Vector2) -> void:
	var item := Label.new()
	item.text = text
	item.position = at
	item.add_theme_font_size_override("font_size", 22)
	root.add_child(item)

func run() -> void:
	args = OS.get_cmdline_user_args()
	var preview := "--preview" in args
	root.size = Vector2i(1280, 720) if preview else Vector2i(1920, 1080)
	root.content_scale_size = root.size
	var output: String
	if preview:
		var file := args[1]
		var height := 1.85 if file.begins_with("cover_full") else (0.8 if file.begins_with("cover_half") or file.begins_with("obj_charge") else 1.6)
		for i in 2:
			var container := SubViewportContainer.new()
			container.position = Vector2(i * 640, 0)
			container.size = Vector2(640, 720)
			root.add_child(container)
			var viewport := SubViewport.new()
			viewport.size = Vector2i(640, 720)
			viewport.own_world_3d = true
			container.add_child(viewport)
			var scene := scene_in(viewport)
			scene.add_child(model(RAW + file, height, 1.0, true))
			camera_in(scene, Vector3(2.4, 2.6, 3.7) if i == 0 else Vector3(5.147, 17.934, 16.64), Vector3(0, height * 0.45, 0), 40 if i == 0 else 45)
			label(file + (" / close" if i == 0 else " / ~25 units"), Vector2(i * 640 + 15, 15))
		output = RAW + file.replace(".glb", ".png")
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
	quit()
