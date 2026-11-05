extends SceneTree
## Run under xvfb after import. Static SubViewport portraits keep battle/Temple draw cost low.

const PEOPLE := {
	"kira":"jedi", "tor":"jedi", "rhal":"trooper", "ilsa":"scout", "bren":"trooper", "grak":"trooper",
	"satele":"jedi", "jace":"trooper", "varra":"trooper", "council":"jedi",
	"ressa":"jedi", "kell":"jedi", "bo":"trooper", "mira":"scout", "ilo":"trooper", "rusk":"sithHeavy",
	"sava":"jedi", "tem":"jedi", "dace":"trooper", "kiri":"scout", "halden":"trooper", "bruk":"sithHeavy",
	"malgus":"sithHeavy", "kaan":"sithHeavy", "bane":"sithHeavy", "ro":"agent"
}

func _initialize() -> void:
	call_deferred("bake")

func bake() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/story/portraits14"))
	for key in PEOPLE:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(256,320)
		viewport.own_world_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var env := WorldEnvironment.new()
		var setting := Environment.new()
		setting.background_mode = Environment.BG_COLOR
		setting.background_color = Color("0b1720")
		setting.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		setting.ambient_light_color = Color("abc4d0")
		setting.ambient_light_energy = 0.7
		env.environment = setting
		viewport.add_child(env)
		var model: Node3D = load("res://assets/models/units/%s.glb" % PEOPLE[key]).instantiate()
		viewport.add_child(model)
		var bounds := _bounds(model)
		model.scale = Vector3.ONE * (2.0 / maxf(bounds.size.y,0.1))
		model.rotation.y = 0.2 if key in ["kira","ilsa","satele"] else -0.2
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-35,-35,0)
		light.light_energy = 2.0
		light.light_color = Color("f7dfbf")
		viewport.add_child(light)
		var rim := OmniLight3D.new()
		rim.position = Vector3(-1.5,2.0,-0.5)
		rim.light_color = Color("e87a67") if key in ["malgus","kaan","bane","ro"] else Color("5dc6e6")
		rim.light_energy = 3.0
		viewport.add_child(rim)
		var camera := Camera3D.new()
		camera.position = Vector3(0,1.64,1.8)
		camera.fov = 30
		viewport.add_child(camera)
		camera.look_at(Vector3(0,1.64,0))
		camera.current = true
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		var frame := Color("bd665a") if key in ["malgus","kaan","bane","ro"] else Color("59bac9")
		image.fill_rect(Rect2i(0,0,256,5),frame)
		image.fill_rect(Rect2i(0,315,256,5),frame)
		image.fill_rect(Rect2i(0,0,5,320),frame)
		image.fill_rect(Rect2i(251,0,5,320),frame)
		var path := "res://assets/story/portraits14/%s.png" % key
		var error := image.save_png(path)
		print("PORTRAIT %s %s" % [key,error])
		viewport.queue_free()
		await process_frame
	quit()

func _bounds(node: Node3D) -> AABB:
	var result := AABB()
	if node is MeshInstance3D: result = node.global_transform * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var b := _bounds(child)
			if b.size != Vector3.ZERO: result = b if result.size == Vector3.ZERO else result.merge(b)
	return result
