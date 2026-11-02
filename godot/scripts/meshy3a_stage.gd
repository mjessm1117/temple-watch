extends SceneTree
## Neutral review only; does not modify game routing or collision.
const RAW = "res://../art/meshy3/raw3a/"
const FINAL = "res://assets/maps/meshy3/"
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
		print(path, " source W:H:D ", bounds.size, " ratio ", bounds.size / bounds.size.y)
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
		var height := 1.85 if file.begins_with("cover_full") else (0.8 if file.begins_with("cover_half") else 1.8)
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
			scene.add_child(model((FINAL if "--final" in args else RAW) + file, height, 1.0, "--textured" not in args))
			camera_in(scene, Vector3(2.4, 2.6, 3.7) if i == 0 else Vector3(5.147, 17.934, 16.64), Vector3(0, height * 0.45, 0), 40 if i == 0 else 45)
			label(file + (" / close" if i == 0 else " / ~25 units"), Vector2(i * 640 + 15, 15))
		output = RAW + file.replace(".glb", ".png")
	else:
		var scene := scene_in(root)
		var close := "--close" in args
		var themes := ["temple", "ruins", "caves", "jungle"]
		for col in 4:
			for row in 4:
				var theme: String = themes[col]
				var holder := Node3D.new()
				scene.add_child(holder)
				holder.position = Vector3((col - 1.5) * 3.3, 0, (row - 1.5) * 2.3)
				var title: String
				if row == 0:
					title = theme + " wall REF"
					var path := "res://assets/maps/wall_" + theme + ".glb"
					if theme == "temple":
						path = "res://assets/maps/wall.glb"
					holder.add_child(model(path, 1.85, 1.0))
				elif row == 2 and col == 0:
					title = "half temple / other batch"
				elif row == 3:
					holder.position.x += 1.25
					holder.position.z = -5.7
					title = "temple column REF"
					holder.add_child(model("res://assets/maps/pillar.glb", 2.8, 0.9))
				else:
					title = "cover_" + ("full_" if row == 1 else "half_") + theme
					var path := FINAL + title + "_v1" + ("_lod1" if "--lod1" in args else "") + ".glb"
					if FileAccess.file_exists(path):
						holder.add_child(model(path))
					else:
						title += " / rejected"
				var tag := Label3D.new()
				tag.text = title
				tag.font_size = 30
				tag.pixel_size = 0.005
				tag.position = Vector3(0, 0.12, 0.8)
				tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				tag.no_depth_test = true
				holder.add_child(tag)
		var floor_mesh := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(22, 14)
		floor_mesh.mesh = plane
		floor_mesh.position.y = -0.03
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("48515a")
		mat.roughness = 1.0
		floor_mesh.material_override = mat
		scene.add_child(floor_mesh)
		camera_in(scene, Vector3(2.5, 10.0, 13.5) if close else Vector3(5.147, 17.934, 16.64), Vector3(0, 0.65, 0), 45)
		label("MESHY 3a / " + ("ACTION CAMERA" if close else "BATTLE CAMERA / ~25 units") + " / neutral review — integration pending", Vector2(40, 35))
		label("Temple / Ruins / Caves / Jungle    |    Theme walls / full and half cover / temple columns", Vector2(40, 990))
		output = "res://../docs/godot/shots/meshy3a-stage" + ("-close" if close else "") + ".png"
		if "--lod1" in args:
			output = RAW + "lod1-review.png"
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
	quit()
