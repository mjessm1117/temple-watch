extends SceneTree
## Neutral review only; does not modify game routing or collision.
const RAW = "res://../art/meshy3/3b/"
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

func close_panels() -> void:
	var names := ["cover_full_plains", "cover_full_snow", "cover_full_city", "cover_half_plains", "cover_half_snow", "cover_half_dock", "obj_charge", "obj_beacon", "obj_restraint"]
	for i in 9:
		var at := Vector2((i % 3) * 640, (i / 3) * 360)
		var container := SubViewportContainer.new()
		container.position = at
		container.size = Vector2(640, 360)
		root.add_child(container)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(640, 360)
		viewport.own_world_3d = true
		container.add_child(viewport)
		var scene := scene_in(viewport)
		var path: String = FINAL + names[i] + "_v1" + ("_lod1" if "--lod1" in args else "") + ".glb"
		if FileAccess.file_exists(path):
			scene.add_child(model(path))
		var theme: String = ["plains", "snow", "city", "plains", "snow", "dock", "dock", "city", "snow"][i]
		var wall := model("res://assets/maps/wall_" + ("metal" if theme in ["city", "dock"] else theme) + ".glb", 1.8, 0.9)
		wall.position.x += 1.5
		scene.add_child(wall)
		var pillar := model("res://assets/maps/pillar.glb", 2.2, 0.7)
		pillar.position.x -= 1.5
		scene.add_child(pillar)
		camera_in(scene, Vector3(1.1, 3.8, 5.5), Vector3(0, 0.9, 0), 45)
		label(names[i], at + Vector2(15, 8))
		label("column / candidate / " + theme + " wall", at + Vector2(15, 328))

func run() -> void:
	args = OS.get_cmdline_user_args()
	var preview := "--preview" in args
	root.size = Vector2i(1280, 720) if preview else Vector2i(1920, 1080)
	root.content_scale_size = root.size
	var output: String
	if "--close" in args and not preview:
		close_panels()
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		output = RAW + "lod1-review.png" if "--lod1" in args else "res://../docs/godot/shots/meshy3b-stage-close.png"
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
		quit()
		return
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
	else:
		var scene := scene_in(root)
		var close := "--close" in args
		var names := ["cover_full_plains", "cover_full_snow", "cover_full_city", "cover_half_plains", "cover_half_snow", "cover_half_dock", "obj_charge", "obj_beacon", "obj_restraint"]
		for i in 9:
			var holder := Node3D.new()
			scene.add_child(holder)
			holder.position = Vector3((i % 3 - 1) * 4.3, 0, (i / 3 - 1) * 3.1)
			var path: String = FINAL + names[i] + "_v1" + ("_lod1" if "--lod1" in args else "") + ".glb"
			if FileAccess.file_exists(path):
				holder.add_child(model(path))
			var theme: String = ["plains", "snow", "city", "plains", "snow", "dock", "dock", "city", "snow"][i]
			var wall := model("res://assets/maps/wall_" + ("metal" if theme in ["city", "dock"] else theme) + ".glb", 1.8, 0.9)
			wall.position.x += 1.2
			holder.add_child(wall)
			var tag := Label3D.new()
			tag.text = names[i] + " / " + theme + " wall"
			tag.font_size = 30
			tag.pixel_size = 0.006
			tag.position = Vector3(0.5, 0.05, 0.9)
			tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			tag.no_depth_test = true
			holder.add_child(tag)
		var pillar := model("res://assets/maps/pillar.glb", 2.8, 0.9)
		pillar.position.x -= 7.0
		scene.add_child(pillar)
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
		camera_in(scene, Vector3(3, 11, 13) if close else Vector3(5.147, 17.934, 16.64), Vector3(0, 0.65, 0), 45)
		label("MESHY 3B / " + ("ACTION CAMERA" if close else "BATTLE CAMERA / ~25 units") + " / neutral review — integration pending", Vector2(40, 35))
		label("Lane 3b: nine candidates with matching theme walls and temple column / uniform scale", Vector2(40, 990))
		output = "res://../docs/godot/shots/meshy3b-stage" + ("-close" if close else "") + ".png"
		if "--lod1" in args:
			output = RAW + "lod1-review.png"
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
	quit()
