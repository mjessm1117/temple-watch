extends RefCounted
## Small presentation beats kept out of the crowded FX script.

static func apply_hit_shake(camera: Camera3D, intensity: float, duration_ms: int) -> void:
	if camera == null or not is_instance_valid(camera) or intensity <= 0.0 or duration_ms <= 0 or not camera.is_inside_tree(): return
	if camera.has_meta("w31c_shake_active") and bool(camera.get_meta("w31c_shake_active")): return
	camera.set_meta("w31c_shake_active", true)
	var height := maxf(1.0, float(camera.get_viewport().get_visible_rect().size.y))
	var pixel_world := camera.size / height if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else 0.025
	var amount := minf(intensity, 2.0) * pixel_world
	var offset := Vector3.ZERO
	var frames := mini(3, maxi(1, ceili(float(duration_ms) / 16.67)))
	for frame in frames:
		if not is_instance_valid(camera) or not camera.is_inside_tree(): return
		var next := Vector3(amount * (1.0 if frame % 2 == 0 else -0.6), amount * (0.35 if frame % 2 == 0 else -0.2), 0.0)
		camera.position += next - offset
		offset = next
		await camera.get_tree().process_frame
	if is_instance_valid(camera):
		camera.position -= offset
		camera.remove_meta("w31c_shake_active")

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
