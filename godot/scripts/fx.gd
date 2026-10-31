extends Node3D

const Audio = preload("res://scripts/audio.gd")
var view_camera: Camera3D
var overlay: Control
var _scorches: Array[Node3D] = []
var _hit_stop_serial := 0
var _time_scale_before := 1.0

func hit_stop(seconds := 0.055) -> void:
	if _hit_stop_serial == 0: _time_scale_before = Engine.time_scale
	_hit_stop_serial += 1
	var serial := _hit_stop_serial
	Engine.time_scale = 0.12
	get_tree().create_timer(minf(seconds, 0.08), true, false, true).timeout.connect(func() -> void:
		if serial == _hit_stop_serial:
			Engine.time_scale = _time_scale_before
			_hit_stop_serial = 0)

func _exit_tree() -> void:
	if _hit_stop_serial != 0: Engine.time_scale = _time_scale_before

func _cue(kind: String) -> void:
	var synth := Audio.new()
	var stream := synth._synthesize(kind)
	synth.free()
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	voice.volume_db = -20.0
	add_child(voice)
	voice.play()
	voice.finished.connect(voice.queue_free)

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
		material.emission_energy_multiplier = 2.4
	return material

func _sphere(at: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius; mesh.height = radius * 2
	var node := MeshInstance3D.new()
	node.mesh = mesh; node.material_override = _material(color)
	node.position = at; add_child(node)
	return node

func _flash(at: Vector3, color: Color, energy: float, duration: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 2.5
	light.shadow_enabled = false
	light.position = at
	add_child(light)
	var tween := create_tween()
	tween.tween_property(light, "light_energy", 0.0, duration)
	tween.tween_callback(light.queue_free)

func burst(at: Vector3, color: Color, count := 8) -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	for i in range(count):
		var spark := _sphere(at, 0.025 if i % 3 else 0.04, color)
		var vector := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.15, 1.1), rng.randf_range(-1, 1))
		var tween := create_tween().set_parallel(true)
		tween.tween_property(spark, "position", at + vector * 0.65, 0.24)
		tween.tween_property(spark, "scale", Vector3.ZERO, 0.24)
		tween.chain().tween_callback(spark.queue_free)

func _scorch(at: Vector3) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.19; mesh.bottom_radius = 0.19; mesh.height = 0.007
	var decal := MeshInstance3D.new()
	decal.mesh = mesh
	decal.material_override = _material(Color("25201e"), false)
	decal.position = Vector3(at.x, maxf(0.018, at.y - 1.08), at.z)
	add_child(decal)
	_scorches.append(decal)
	if _scorches.size() > 32:
		_scorches.pop_front().queue_free()

func bolt(from: Vector3, to: Vector3, enemy: bool, miss: bool) -> void:
	var color := Color("ff5364") if enemy else Color("70dfff")
	var direction := (to - from).normalized()
	var end := to + direction * 1.4 if miss else to
	if miss: _cue("whiz")
	_flash(from, color, 2.0, 0.09)
	burst(from, color, 4)
	var core := _sphere(from, 0.075, Color.WHITE)
	core.scale = Vector3(0.8, 0.8, 4.5)
	core.look_at(end, Vector3.UP)
	var glow := _sphere(from, 0.15, color)
	glow.scale = Vector3(0.6, 0.6, 3.0)
	glow.look_at(end, Vector3.UP)
	var beam_mesh := CylinderMesh.new(); beam_mesh.top_radius = 0.018; beam_mesh.bottom_radius = 0.018; beam_mesh.height = from.distance_to(end)
	var beam := MeshInstance3D.new(); beam.mesh = beam_mesh; beam.material_override = _material(color)
	beam.position = (from + end) * 0.5
	beam.quaternion = Quaternion(Vector3.UP, direction)
	add_child(beam)
	var beam_fade := create_tween()
	beam_fade.tween_interval(0.08)
	beam_fade.tween_property(beam, "scale", Vector3.ZERO, 0.13)
	beam_fade.tween_callback(beam.queue_free)
	if overlay != null and view_camera != null:
		var streak := Line2D.new()
		streak.points = PackedVector2Array([view_camera.unproject_position(from), view_camera.unproject_position(end)])
		streak.width = 3.0; streak.default_color = color
		overlay.add_child(streak)
		var fade := create_tween()
		fade.tween_property(streak, "modulate:a", 0.0, 0.18).set_delay(0.04)
		fade.tween_callback(streak.queue_free)
	var duration := clampf(from.distance_to(end) / 38.0, 0.11, 0.31)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(core, "position", end, duration)
	tween.tween_property(glow, "position", end, duration)
	tween.chain().tween_callback(func() -> void:
		_flash(end, Color("ffd7a4"), 0.9, 0.1)
		burst(end, Color("e8c896") if miss else color, 10)
		if miss: _scorch(end)
		core.queue_free(); glow.queue_free())

func shockwave(from: Vector3, to: Vector3) -> void:
	var wave := _sphere(from, 0.22, Color("8beafa"))
	wave.scale = Vector3(1.0, 0.25, 1.0)
	_flash(from, Color("8beafa"), 1.1, 0.16)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(wave, "position", to, 0.28)
	tween.tween_property(wave, "scale", Vector3(6, 0.12, 6), 0.36)
	tween.chain().tween_callback(func() -> void:
		burst(to, Color("9cefff"), 12)
		cover_chunks(to)
		wave.queue_free())

func saber(from: Vector3, to: Vector3) -> void:
	_cue("ignite")
	var mid := (from + to) * 0.5 + Vector3.UP * 0.45
	var trail := _sphere(mid, 0.13, Color("80eaff"))
	trail.scale = Vector3(0.8, 0.8, 4.5)
	trail.look_at(to, Vector3.UP)
	_flash(mid, Color("80eaff"), 1.0, 0.18)
	var tween := create_tween()
	tween.tween_property(trail, "position", to, 0.15)
	tween.tween_property(trail, "scale", Vector3.ZERO, 0.1)
	tween.tween_callback(trail.queue_free)
	burst(to, Color("f1fbff"), 12)
	get_tree().create_timer(0.14).timeout.connect(func() -> void:
		if is_instance_valid(self): _cue("clash"))

func cover_chunks(at: Vector3) -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	for i in range(8):
		var mesh := BoxMesh.new(); mesh.size = Vector3(0.14, 0.1, 0.14)
		var chunk := MeshInstance3D.new(); chunk.mesh = mesh
		chunk.material_override = _material(Color("9a9d98"), false)
		chunk.position = at; add_child(chunk)
		var offset := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.2, 1), rng.randf_range(-1, 1))
		var tween := create_tween().set_parallel(true)
		tween.tween_property(chunk, "position", at + offset, 0.36)
		tween.tween_property(chunk, "scale", Vector3.ZERO, 0.36).set_delay(0.1)
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
	tween.tween_property(label, "position:y", label.position.y - 75, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)
