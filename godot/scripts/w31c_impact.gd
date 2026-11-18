extends RefCounted
## Battle impact presentation. 2D particles use one draw call per emitter.

static var spark_pool: GPUParticles2D
static var pixel: Texture2D

static func faction_color(kind: String) -> Color:
	match kind:
		"jedi": return Color("cce8ff")
		"droid": return Color("c8ffcc")
		_: return Color("ffd8a8")

static func battle_event(view: Node3D, kind: String, shooter: Vector3, camera: Camera3D, damage: int = 0) -> void:
	if view == null or not is_instance_valid(view): return
	match kind:
		"hit":
			hit_flash(view)
			if view.has_method("hit_flinch35"): view.hit_flinch35(shooter, camera)
			spawn_hit_sparks(view, camera)
			if camera != null: apply_hit_shake(camera, 2.0, 250)
		"crit":
			if camera != null: apply_hit_shake(camera, 4.0, 250)
		"miss":
			if damage == 0: spawn_miss_puff(view, shooter, camera)

static func _meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D: out.append(node)
	for child in node.get_children(): _meshes(child, out)

static func hit_flash(view: Node3D) -> void:
	var model: Node3D = view.get("model")
	if model == null or not model.is_inside_tree(): return
	var color := faction_color(str(view.get("impact_kind35")))
	var meshes: Array[MeshInstance3D] = []
	_meshes(model, meshes)
	for mesh in meshes:
		# Saber glow uses a live shader material that gameplay updates directly.
		if mesh.material_override is ShaderMaterial: continue
		if mesh.has_meta("d35_flash_active"): continue
		var original: Material = mesh.material_override
		var active := mesh.get_active_material(0)
		var return_color: Color = active.albedo_color if active is StandardMaterial3D else Color.WHITE
		var flash := StandardMaterial3D.new()
		flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flash.albedo_color = color
		flash.emission_enabled = true
		flash.emission = color
		flash.emission_energy_multiplier = 1.4
		mesh.material_override = flash
		mesh.set_meta("d35_flash_active", true)
		var tween := mesh.create_tween()
		tween.tween_interval(0.12)
		tween.tween_property(flash, "albedo_color", return_color, 0.08)
		tween.tween_callback(func() -> void:
			if is_instance_valid(mesh):
				mesh.material_override = original
				mesh.remove_meta("d35_flash_active"))

static func _pixel_texture() -> Texture2D:
	if pixel != null: return pixel
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	pixel = ImageTexture.create_from_image(image)
	return pixel

static func _screen_point(view: Node3D, camera: Camera3D) -> Vector2:
	return camera.unproject_position(view.global_position + Vector3.UP) if camera != null and is_instance_valid(camera) else Vector2.ZERO

static func spawn_miss_puff(view: Node3D, shooter: Vector3, camera: Camera3D) -> CPUParticles2D:
	if camera == null or not is_instance_valid(camera): return null
	var puff := CPUParticles2D.new()
	puff.name = "D35MissPuff"
	puff.amount = 10
	puff.one_shot = true
	puff.explosiveness = 1.0
	puff.lifetime = 0.3
	puff.texture = _pixel_texture()
	puff.color = Color("cccccc")
	puff.initial_velocity_min = 32.0
	puff.initial_velocity_max = 54.0
	puff.spread = 10.0
	puff.gravity = Vector2.ZERO
	puff.scale_amount_min = 1.5
	puff.scale_amount_max = 2.5
	var target_screen := _screen_point(view, camera)
	var source_screen := camera.unproject_position(shooter + Vector3.UP)
	var away := target_screen - source_screen
	puff.direction = away.normalized() if away.length_squared() > 0.01 else Vector2.RIGHT
	puff.position = target_screen
	camera.get_viewport().add_child(puff)
	puff.emitting = true
	var lifetime := puff.create_tween()
	lifetime.tween_interval(0.5)
	lifetime.tween_callback(puff.queue_free)
	return puff

static func spawn_hit_sparks(view: Node3D, camera: Camera3D) -> GPUParticles2D:
	if camera == null or not is_instance_valid(camera): return null
	var viewport := camera.get_viewport()
	if not is_instance_valid(spark_pool) or spark_pool.get_parent() != viewport:
		spark_pool = GPUParticles2D.new()
		spark_pool.name = "D35FactionSparks"
		spark_pool.amount = 6
		spark_pool.one_shot = true
		spark_pool.explosiveness = 1.0
		spark_pool.lifetime = 0.2
		spark_pool.texture = _pixel_texture()
		var process := ParticleProcessMaterial.new()
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		process.initial_velocity_min = 45.0
		process.initial_velocity_max = 80.0
		process.spread = 180.0
		process.gravity = Vector3.ZERO
		var fade := Gradient.new()
		fade.set_color(0, Color.WHITE)
		fade.set_color(1, Color(1, 1, 1, 0))
		var ramp := GradientTexture1D.new()
		ramp.gradient = fade
		process.color_ramp = ramp
		spark_pool.process_material = process
		viewport.add_child(spark_pool)
	spark_pool.position = _screen_point(view, camera)
	spark_pool.modulate = faction_color(str(view.get("impact_kind35")))
	spark_pool.restart()
	spark_pool.emitting = true
	return spark_pool

static func apply_hit_shake(camera: Camera3D, intensity: float, duration_ms: int) -> void:
	if camera == null or not is_instance_valid(camera) or intensity <= 0.0 or duration_ms <= 0 or not camera.is_inside_tree(): return
	var serial := int(camera.get_meta("d35_shake_serial", 0)) + 1
	camera.set_meta("d35_shake_serial", serial)
	var height := maxf(1.0, camera.get_viewport().get_visible_rect().size.y)
	var pixel_world := camera.size / height if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else 20.0 * tan(deg_to_rad(camera.fov) * 0.5) / height
	var amplitude := minf(intensity, 4.0) * pixel_world
	var duration := float(duration_ms) / 1000.0
	var step := duration / 10.0
	# Pre-kick: set v_offset immediately so the shake is visible on the same frame
	camera.v_offset = amplitude
	# Tween: oscillate with decaying amplitude back to 0
	var t := camera.create_tween()
	t.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	for v in [-amplitude * 0.65, amplitude * 0.4, -amplitude * 0.22, amplitude * 0.1, 0.0]:
		t.tween_property(camera, "v_offset", v, step * 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.finished.connect(func() -> void:
		if not is_instance_valid(camera) or int(camera.get_meta("d35_shake_serial", 0)) != serial: return
		camera.v_offset = 0.0
		camera.h_offset = 0.0
		if camera.has_meta("d35_shake_serial"): camera.remove_meta("d35_shake_serial")
	)

static func enlarge_contact_flash(fx_node: Node3D, zoom_factor: float) -> MeshInstance3D:
	if fx_node == null or not is_instance_valid(fx_node): return null
	var flash := MeshInstance3D.new()
	flash.name = "W31CContactFlash"
	var mesh := SphereMesh.new()
	mesh.radius = 0.32
	mesh.height = 0.64
	flash.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.94, 0.78, 0.8)
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 2.0
	flash.material_override = material
	fx_node.add_child(flash)
	flash.scale = Vector3.ONE * clampf(zoom_factor, 1.0, 3.2)
	var tween := fx_node.create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", flash.scale * 1.35, 0.14)
	tween.tween_property(flash, "transparency", 1.0, 0.14)
	tween.chain().tween_callback(func() -> void:
		flash.queue_free()
		if fx_node.name == "W31CContactAnchor": fx_node.queue_free())
	return flash
