extends Node
## Aim-only lighting. Low gets one local key and a mesh rim; higher tiers add a shadow and DOF.
var game: Node3D
var key: OmniLight3D
var rim: OmniLight3D
var background_tint: ColorRect
var vignette: TextureRect
var target_id := -1
var rimmed: Dictionary = {}
var rim_material: ShaderMaterial
var sun_energy := -1.0
var ambient_energy := -1.0

func _ready() -> void:
	process_priority = 10
	set_process(true)

func _tier() -> String:
	var graphics := game.get_node_or_null("/root/Graphics")
	return str(graphics.effective) if graphics else "low"

func sync(actor: Dictionary, target: Dictionary) -> void:
	if actor.is_empty() or target.is_empty(): reset(); return
	_clear_rim()
	target_id = int(target.id)
	var source := Vector3(float(actor.x), 1.5, float(actor.y))
	var destination := Vector3(float(target.x), 1.4, float(target.y))
	var direction := (destination - source).normalized()
	var side := Vector3(-direction.z, 0.0, direction.x)
	if _tier() == "low":
		if sun_energy < 0.0 and game.scene_view.sun != null:
			sun_energy = game.scene_view.sun.light_energy
			game.scene_view.sun.light_energy = sun_energy * 0.58
		if ambient_energy < 0.0 and game.scene_view.world != null:
			ambient_energy = game.scene_view.world.environment.ambient_light_energy
			game.scene_view.world.environment.ambient_light_energy = ambient_energy * 0.7
		if rim != null: rim.queue_free(); rim = null
		if key == null:
			key = OmniLight3D.new(); key.name = "Cine16LowAimKey"; key.shadow_enabled = false; game.add_child(key)
		key.shadow_enabled = false
		key.position = source.lerp(destination, 0.5) + side * 1.2 + Vector3.UP * 1.5
		key.omni_range = maxf(6.0, source.distance_to(destination) * 0.6 + 3.0)
		key.light_color = Color("ffd097"); key.light_energy = 2.4
		if rim_material == null:
			rim_material = ShaderMaterial.new()
			rim_material.shader = preload("res://assets/env/unit_rim.gdshader")
			rim_material.set_shader_parameter("rim_color", Color(0.12, 0.72, 1.0, 1.0))
		for id in [int(actor.id), int(target.id)]:
			var view: Node3D = game.views.get(id)
			if view != null: _rim_model(view.model)
		if game.cam.preview_shoulder != null: _rim_model(game.cam.preview_shoulder)
		if background_tint == null:
			background_tint = ColorRect.new(); background_tint.name = "Cine15LowTint"
			background_tint.color = Color(0.01, 0.025, 0.05, 0.10)
			background_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
			background_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			game.overlay.add_child(background_tint)
			game.overlay.move_child(background_tint, 0)
		_clear_vignette()
		return
	_restore_low_mood()
	_clear_tint()
	if key == null:
		key = OmniLight3D.new(); key.name = "Cine15AimKey"; key.omni_range = 7.0
		key.light_color = Color("ffe2ad"); game.add_child(key)
	if rim == null:
		rim = OmniLight3D.new(); rim.name = "Cine15TargetRim"; rim.omni_range = 5.0
		rim.light_color = Color("88cfff"); rim.shadow_enabled = false; game.add_child(rim)
	key.shadow_enabled = true
	key.shadow_blur = 1.4
	key.position = source + side * 1.1 + Vector3.UP * 1.3
	rim.position = destination - direction * 0.6 - side * 0.8 + Vector3.UP * 1.1
	key.light_energy = 0.9; rim.light_energy = 1.25
	if vignette == null and game.overlay != null:
		vignette = TextureRect.new(); vignette.name = "Cine15Vignette"
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vignette.texture = _vignette_texture()
		vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		game.overlay.add_child(vignette)
		game.overlay.move_child(vignette, 0)

func _vignette_texture() -> ImageTexture:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var distance := Vector2((float(x) - 31.5) / 31.5, (float(y) - 31.5) / 31.5).length()
			image.set_pixel(x, y, Color(0.02, 0.03, 0.06, smoothstep(0.55, 1.4, distance) * 0.24))
	return ImageTexture.create_from_image(image)

func _process(_delta: float) -> void:
	if target_id < 0 or not is_instance_valid(game) or game.camera == null: return
	var aim_open: bool = game.hud_controls != null and game.hud_controls.aim_ui != null and game.hud_controls.aim_ui.panel.visible
	if not aim_open or game.player_attack_pending: reset(); return
	var tier := _tier()
	if tier == "low": return
	if game.camera.attributes == null: game.camera.attributes = CameraAttributesPractical.new()
	var attrs := game.camera.attributes as CameraAttributesPractical
	if attrs != null:
		attrs.dof_blur_far_enabled = true
		var target_view: Node3D = game.views.get(target_id)
		if target_view != null:
			attrs.dof_blur_far_distance = game.camera.global_position.distance_to(target_view.global_position) + 2.5
		attrs.dof_blur_far_transition = 6.0

func reset() -> void:
	target_id = -1
	_clear_rim()
	_restore_low_mood()
	_clear_lights(); _clear_tint(); _clear_vignette()
	if is_instance_valid(game) and game.camera != null and game.camera.attributes is CameraAttributesPractical:
		game.camera.attributes.dof_blur_far_enabled = false

func _clear_lights() -> void:
	if key != null: key.queue_free(); key = null
	if rim != null: rim.queue_free(); rim = null

func _rim_model(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if not rimmed.has(mesh):
			rimmed[mesh] = mesh.material_overlay
			mesh.material_overlay = rim_material
	for child in node.get_children(): _rim_model(child)

func _clear_rim() -> void:
	for mesh in rimmed:
		if is_instance_valid(mesh): mesh.material_overlay = rimmed[mesh]
	rimmed.clear()

func _restore_low_mood() -> void:
	if sun_energy >= 0.0 and is_instance_valid(game) and game.scene_view.sun != null:
		game.scene_view.sun.light_energy = sun_energy
	if ambient_energy >= 0.0 and is_instance_valid(game) and game.scene_view.world != null:
		game.scene_view.world.environment.ambient_light_energy = ambient_energy
	sun_energy = -1.0
	ambient_energy = -1.0

func _clear_tint() -> void:
	if background_tint != null: background_tint.queue_free(); background_tint = null

func _clear_vignette() -> void:
	if vignette != null: vignette.queue_free(); vignette = null
