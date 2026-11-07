extends SceneTree
## Isolated art stage. Loads staged GLBs directly; does not change the game roster.
const SHOT_DIR := "res://../docs/godot/shots/"
var scene: Node3D

func _initialize() -> void:
	run.call_deferred()

func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	return m

func box(size: Vector3, pos: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = material(color)
	scene.add_child(node)

func unit(path: String, x: float, height: float) -> void:
	var packed: PackedScene = load(path)
	assert(packed != null, "missing staged model " + path)
	var model: Node3D = packed.instantiate()
	scene.add_child(model)
	model.position = Vector3(x, 0.02, 0)
	model.scale = Vector3.ONE * (height / 1.8)
	var animation := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation:
		var desired := "idle"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--clip="):
				desired = arg.trim_prefix("--clip=")
		for name in animation.get_animation_list():
			if str(name).to_lower() == desired.to_lower():
				animation.play(name)
				break

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var kind := "heavy" if "--heavy" in args else ("trooper" if "--trooper" in args else ("scout" if "--scout" in args else "sniper"))
	var portrait := "--portrait" in args
	root.size = Vector2i(384, 480) if portrait else Vector2i(844, 390)
	root.content_scale_size = root.size
	scene = Node3D.new()
	root.add_child(scene)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("263342")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.72
	world.environment = env
	scene.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.light_energy = 1.25
	light.shadow_enabled = true
	scene.add_child(light)
	box(Vector3(7.8, 0.12, 4.2), Vector3(0, -0.07, 0), Color("566373"))
	for i in range(-3, 4):
		box(Vector3(0.015, 0.005, 4.2), Vector3(float(i), 0.003, 0), Color("8291a0"))
	for i in range(-2, 3):
		box(Vector3(7.8, 0.005, 0.015), Vector3(0, 0.003, float(i)), Color("8291a0"))
	box(Vector3(0.62, 0.68, 0.44), Vector3(-2.75, 0.34, -0.8), Color("a39578"))
	box(Vector3(0.50, 0.48, 0.48), Vector3(2.8, 0.24, -0.65), Color("a39578"))
	if portrait:
		var path := "res://assets/units/w17/" + kind + ("_lod1" if "--lod" in args else "") + ".glb" if kind in ["sniper", "heavy"] else "res://assets/models/units/" + kind + ".glb"
		unit(path, 0, 2.1 if kind == "heavy" else 1.78)
	else:
		unit("res://assets/models/units/trooper.glb", -2.25, 1.78)
		unit("res://assets/models/units/scout.glb", -0.85, 1.78)
		unit("res://assets/units/w17/" + kind + ".glb", 1.25, 2.1 if kind == "heavy" else 1.78)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position = (Vector3(2.5, 1.85, 4.7) if "--three-quarter" in args else Vector3(0, 1.55, 4.7)) if portrait else Vector3(2.9, 3.6, 6.1)
	camera.look_at(Vector3(0, 1.05, 0) if portrait else Vector3(0, 0.9, 0))
	camera.fov = 43 if portrait else 48
	camera.current = true
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var suffix := ""
	for arg in args:
		if arg.begins_with("--clip="):
			suffix = "-" + arg.trim_prefix("--clip=")
	if "--lod" in args:
		suffix += "-lod"
	var output := "res://../art/w17/portrait-" + kind + ("-three-quarter" if "--three-quarter" in args else "-front") + suffix + ".png" if portrait else SHOT_DIR + "w17-art-" + kind + "-battle-low.png"
	var error := image.save_png(ProjectSettings.globalize_path(output))
	print("W17_ART_CAPTURE ", kind, " ", image.get_width(), "x", image.get_height(), " save=", error)
	quit(0 if error == OK else 1)
