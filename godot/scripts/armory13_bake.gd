extends SceneTree
## Offline SubViewport bake of the same simple gear shapes used on the loadout actor.
const OUT := "res://assets/loadout/icons13/"
const INK := Color("a8cbd4")
const GOLD := Color("e0bd78")

func _initialize() -> void:
	call_deferred("bake")

func box(parent: Node3D, size: Vector3, at: Vector3, color: Color, angle := 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new(); mesh.size = size; node.mesh = mesh
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.metallic = 0.32; mat.roughness = 0.35
	node.material_override = mat; node.position = at; node.rotation.z = angle; parent.add_child(node)
	return node

func ball(parent: Node3D, size: float, at: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new(); var mesh := SphereMesh.new()
	mesh.radius = size; mesh.height = size * 2; mesh.radial_segments = 16; mesh.rings = 8
	node.mesh = mesh; node.position = at
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.metallic = 0.18
	node.material_override = mat; parent.add_child(node)

func gear(parent: Node3D, kind: String) -> void:
	match kind:
		"armor_jedi", "armor_troop":
			var model_name := "jedi" if kind == "armor_jedi" else "trooper"
			var model: Node3D = load("res://assets/loadout/models/%s.glb" % model_name).instantiate()
			model.position.y = -0.68; parent.add_child(model)
		"saber":
			box(parent, Vector3(0.17, 0.42, 0.2), Vector3(0, -0.45, 0), Color("839ba4"))
			box(parent, Vector3(0.3, 0.08, 0.26), Vector3(0, -0.2, 0), GOLD)
			box(parent, Vector3(0.085, 1.12, 0.1), Vector3(0, 0.36, 0), Color("76d8ee"))
		"blaster":
			box(parent, Vector3(1.25, 0.22, 0.28), Vector3(0, 0.15, 0), Color("657e89"))
			box(parent, Vector3(0.32, 0.16, 0.33), Vector3(-0.32, 0.36, 0), INK)
			box(parent, Vector3(0.19, 0.5, 0.22), Vector3(-0.18, -0.18, 0), Color("344c56"), -0.25)
			box(parent, Vector3(0.22, 0.38, 0.22), Vector3(-0.52, 0.05, 0), GOLD)
		"armor":
			box(parent, Vector3(0.94, 1.0, 0.4), Vector3.ZERO, Color("627e8b"))
			box(parent, Vector3(0.28, 0.72, 0.44), Vector3(-0.31, 0.12, 0), INK, -0.16)
			box(parent, Vector3(0.28, 0.72, 0.44), Vector3(0.31, 0.12, 0), INK, 0.16)
			box(parent, Vector3(0.5, 0.11, 0.46), Vector3(0, -0.21, 0), GOLD)
		"utility":
			box(parent, Vector3(0.9, 0.78, 0.32), Vector3.ZERO, Color("afc2c4"))
			box(parent, Vector3(0.58, 0.13, 0.38), Vector3(0, 0, 0), Color("68d2b8"))
			box(parent, Vector3(0.13, 0.55, 0.38), Vector3(0, 0, 0), Color("68d2b8"))
		"module":
			box(parent, Vector3(0.9, 0.44, 0.42), Vector3.ZERO, Color("698390"))
			for x in [-0.28, 0.28]:
				box(parent, Vector3(0.13, 0.75, 0.18), Vector3(x, 0, 0), GOLD)
		"armor_mod":
			box(parent, Vector3(0.8, 0.87, 0.27), Vector3.ZERO, Color("7e9da5"))
			box(parent, Vector3(0.38, 0.5, 0.3), Vector3(0, 0.02, 0), GOLD)
		"form":
			box(parent, Vector3(0.16, 1.28, 0.16), Vector3(-0.23, 0, 0), Color("7bd8ee"), -0.46)
			box(parent, Vector3(0.16, 1.28, 0.16), Vector3(0.23, 0, 0), Color("7bd8ee"), 0.46)
		"crystal":
			var node := MeshInstance3D.new(); var mesh := PrismMesh.new()
			mesh.size = Vector3(0.7, 1.15, 0.55); node.mesh = mesh
			var mat := StandardMaterial3D.new(); mat.albedo_color = Color("6fcbe3"); mat.metallic = 0.25
			node.material_override = mat; parent.add_child(node)
		"path":
			ball(parent, 0.35, Vector3(0, 0.36, 0), GOLD)
			box(parent, Vector3(0.77, 0.7, 0.25), Vector3(0, -0.35, 0), Color("6c929c"))
			box(parent, Vector3(0.16, 0.3, 0.3), Vector3(0, -0.34, 0), GOLD)

func bake() -> void:
	var viewport := SubViewport.new(); viewport.size = Vector2i(128, 128)
	viewport.transparent_bg = true; viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene := Node3D.new(); viewport.add_child(scene)
	var camera := Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.2; camera.position = Vector3(1.9, 1.5, 3.5); scene.add_child(camera)
	camera.look_at(Vector3.ZERO); camera.current = true
	var key := DirectionalLight3D.new(); key.rotation_degrees = Vector3(-42, -35, 0)
	key.light_energy = 2.0; scene.add_child(key)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-20, 135, 0)
	fill.light_color = Color("6dcbe6"); fill.light_energy = 0.8; scene.add_child(fill)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("8fa8b3")
	env.environment.ambient_light_energy = 0.6; scene.add_child(env)
	for kind in ["saber", "blaster", "armor_jedi", "armor_troop", "utility", "module", "armor_mod", "form", "crystal", "path"]:
		camera.size = 1.35 if kind.begins_with("armor_") else 2.2
		var item := Node3D.new(); scene.add_child(item); gear(item, kind)
		await process_frame; await RenderingServer.frame_post_draw
		var output := ProjectSettings.globalize_path(OUT + kind + ".png")
		print("BAKE ", kind, " ", viewport.get_texture().get_image().save_png(output))
		item.queue_free(); await process_frame
	quit()
