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
		var seed := _seed(key)
		var villain: bool = key in ["malgus","kaan","bane","ro"]
		var council: bool = key == "council"
		var viewport := SubViewport.new()
		viewport.size = Vector2i(256,320)
		viewport.own_world_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var env := WorldEnvironment.new()
		var setting := Environment.new()
		setting.background_mode = Environment.BG_COLOR
		setting.background_color = Color("071b31") if council else Color("100b12") if villain else Color("0b1720")
		setting.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		setting.ambient_light_color = Color("abc4d0")
		setting.ambient_light_energy = 0.3 if villain else 0.75
		env.environment = setting
		viewport.add_child(env)
		var model: Node3D = load("res://assets/models/units/%s.glb" % PEOPLE[key]).instantiate()
		viewport.add_child(model)
		var bounds := _bounds(model)
		model.scale = Vector3.ONE * (2.0 / maxf(bounds.size.y,0.1))
		model.rotation.y = (-0.48 if seed % 2 == 0 else 0.48) + float(seed % 5 - 2) * 0.035
		model.rotation.z = float(seed % 7 - 3) * 0.025
		_tint(model,seed,villain,council)
		if council:
			model.position.x = 0.0
			for side in [-1,1]:
				var member: Node3D = load("res://assets/models/units/jedi.glb").instantiate()
				viewport.add_child(member)
				member.scale = model.scale * 0.84
				member.position = Vector3(float(side)*0.54,0.12,0.22)
				member.rotation.y = -float(side)*0.35
				_tint(member,seed + side + 4,false,true)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-40,-45 if seed % 2 == 0 else 45,0)
		light.light_energy = 1.45 if villain else 2.1
		light.light_color = Color("74d7ff") if council else Color("ff5650") if villain else Color.from_hsv(float(seed % 24)/24.0,0.23,1.0)
		viewport.add_child(light)
		var rim := OmniLight3D.new()
		rim.position = Vector3(-1.5 if seed % 2 == 0 else 1.5,2.0,-0.5)
		rim.light_color = Color("e83a38") if villain else Color("42bfff") if council else Color.from_hsv(float((seed + 9) % 24)/24.0,0.55,1.0)
		rim.light_energy = 2.1 if villain else 3.0
		viewport.add_child(rim)
		var camera := Camera3D.new()
		camera.position = Vector3(float(seed % 5 - 2)*0.09,1.57 + float(seed % 4)*0.035,2.15 if council else 1.7 + float(seed % 4)*0.08)
		camera.fov = 35 if council else 29 + seed % 5
		viewport.add_child(camera)
		camera.look_at(Vector3(0,1.62,0))
		camera.current = true
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		if council:
			for y in image.get_height():
				for x in image.get_width():
					var pixel := image.get_pixel(x,y)
					var glow := (pixel.r + pixel.g + pixel.b) / 3.0
					image.set_pixel(x,y,Color(glow*0.28,glow*0.72,glow, pixel.a))
		var frame := Color("711b25") if villain else Color("4aa7de") if council else Color.from_hsv(float((seed + 12) % 30)/30.0,0.55,0.78)
		image.fill_rect(Rect2i(0,0,256,5),frame)
		image.fill_rect(Rect2i(0,315,256,5),frame)
		image.fill_rect(Rect2i(0,0,5,320),frame)
		image.fill_rect(Rect2i(251,0,5,320),frame)
		# A broad, indexed stripe stays readable when the portrait is scaled for phone.
		var accent := Color("d42f39") if villain else Color("a6e7ff") if council else Color.from_hsv(float(seed % 30)/30.0,0.8,0.95)
		image.fill_rect(Rect2i(8 + seed % 6 * 31,8,22,8),accent)
		image.fill_rect(Rect2i(8,290,18 + seed % 7 * 20,5),accent)
		if council:
			image.fill_rect(Rect2i(10,238,236,43),Color("092d4a"))
			for index in 3:
				var cx := 81 + index*47
				for y in 10:
					image.fill_rect(Rect2i(cx-y,248+y,2*y+1,1),Color("6cc9f4"))
			image.fill_rect(Rect2i(22,272,212,3),Color("8fddff"))
			image.fill_rect(Rect2i(82,282,92,3),Color("8fddff"))
		var path := "res://assets/story/portraits14/%s.png" % key
		var error := image.save_png(path)
		print("PORTRAIT %s %s" % [key,error])
		viewport.queue_free()
		await process_frame
	quit()

func _seed(key: String) -> int:
	var value := 17
	for ch in key.to_utf8_buffer(): value = (value * 31 + int(ch)) % 100003
	return value

func _tint(node: Node, seed: int, villain: bool, council: bool) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_active_material(surface)
			if source is BaseMaterial3D:
				var material := (source as BaseMaterial3D).duplicate() as BaseMaterial3D
				var colour := Color("5da8d3") if council else Color("9e343c") if villain else Color.from_hsv(float(seed % 18)/18.0,0.26 + float(seed % 4)*0.055,0.94)
				material.albedo_color *= colour
				mesh.set_surface_override_material(surface,material)
	for child in node.get_children(): _tint(child,seed,villain,council)

func _bounds(node: Node3D) -> AABB:
	var result := AABB()
	if node is MeshInstance3D: result = node.global_transform * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var b := _bounds(child)
			if b.size != Vector3.ZERO: result = b if result.size == Vector3.ZERO else result.merge(b)
	return result
