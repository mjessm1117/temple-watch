extends Node3D

var view_camera: Camera3D
var overlay: Control

func setup(cam: Camera3D, ui: Control) -> void:
	view_camera = cam
	overlay = ui

func _material(color: Color, glow := true) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 3.0
	return material

func _sphere(at: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius; mesh.height = radius * 2
	var node := MeshInstance3D.new()
	node.mesh = mesh; node.material_override = _material(color)
	node.position = at; add_child(node)
	return node

func burst(at: Vector3, color: Color, count := 8) -> void:
	var random := RandomNumberGenerator.new()
	random.randomize()
	for i in range(count):
		var spark := _sphere(at, 0.045, color)
		var vector := Vector3(random.randf_range(-1, 1), random.randf_range(0.2, 1.3), random.randf_range(-1, 1))
		var tween := create_tween().set_parallel(true)
		tween.tween_property(spark, "position", at + vector * 0.7, 0.38)
		tween.tween_property(spark, "scale", Vector3.ZERO, 0.38)
		tween.chain().tween_callback(spark.queue_free)

func bolt(from: Vector3, to: Vector3, enemy: bool, miss: bool) -> void:
	var color := Color("ff5364") if enemy else Color("70dfff")
	var direction := (to - from).normalized()
	var end := to + direction * 1.4 if miss else to
	burst(from, color, 5)
	var core := _sphere(from, 0.09, color)
	core.scale = Vector3(0.7, 0.7, 7.0)
	core.look_at(end, Vector3.UP)
	var beam_mesh := CylinderMesh.new(); beam_mesh.top_radius = 0.027; beam_mesh.bottom_radius = 0.027; beam_mesh.height = from.distance_to(end)
	var beam := MeshInstance3D.new(); beam.mesh = beam_mesh; beam.material_override = _material(color)
	beam.position = (from + end) * 0.5
	beam.quaternion = Quaternion(Vector3.UP, (end - from).normalized())
	add_child(beam)
	if overlay != null and view_camera != null:
		var streak := Line2D.new()
		streak.points = PackedVector2Array([view_camera.unproject_position(from), view_camera.unproject_position(end)])
		streak.width = 4.0
		streak.default_color = color
		overlay.add_child(streak)
		var fade := create_tween()
		fade.tween_property(streak, "modulate:a", 0.0, 0.34).set_delay(0.07)
		fade.tween_callback(streak.queue_free)
	var tween := create_tween()
	tween.tween_property(core, "position", end, maxf(0.34, from.distance_to(end) / 36.0))
	tween.tween_callback(func() -> void:
		burst(end, Color("d9b586") if miss else color, 12)
		core.queue_free()
		beam.queue_free())

func shockwave(from: Vector3, to: Vector3) -> void:
	var wave := _sphere(from, 0.22, Color("8beafa"))
	wave.scale = Vector3(1.0, 0.25, 1.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(wave, "position", to, 0.28)
	tween.tween_property(wave, "scale", Vector3(6, 0.15, 6), 0.38)
	tween.chain().tween_callback(func() -> void:
		burst(to, Color("9cefff"), 15)
		wave.queue_free())

func saber(from: Vector3, to: Vector3) -> void:
	var mid := (from + to) * 0.5 + Vector3.UP * 0.45
	var trail := _sphere(mid, 0.13, Color("80eaff"))
	trail.scale = Vector3(0.8, 0.8, 4.5)
	trail.look_at(to, Vector3.UP)
	var tween := create_tween()
	tween.tween_property(trail, "position", to, 0.16)
	tween.tween_property(trail, "scale", Vector3.ZERO, 0.16)
	tween.tween_callback(trail.queue_free)
	burst(to, Color("b6f8ff"), 10)

func cover_chunks(at: Vector3) -> void:
	var random := RandomNumberGenerator.new(); random.randomize()
	for i in range(10):
		var mesh := BoxMesh.new(); mesh.size = Vector3(0.18, 0.12, 0.18)
		var chunk := MeshInstance3D.new(); chunk.mesh = mesh
		chunk.material_override = _material(Color("9a9d98"), false)
		chunk.position = at; add_child(chunk)
		var offset := Vector3(random.randf_range(-1.1, 1.1), random.randf_range(0.3, 1.2), random.randf_range(-1.1, 1.1))
		var tween := create_tween().set_parallel(true)
		tween.tween_property(chunk, "position", at + offset, 0.45)
		tween.tween_property(chunk, "scale", Vector3.ZERO, 0.45).set_delay(0.12)
		tween.chain().tween_callback(chunk.queue_free)

func float_text(at: Vector3, value: String, color: Color, large := false) -> void:
	if overlay == null or view_camera == null: return
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 31 if large else 23)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	overlay.add_child(label)
	label.position = view_camera.unproject_position(at) - Vector2(35, 18)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 75, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)
