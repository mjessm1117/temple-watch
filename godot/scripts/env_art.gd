extends "res://scripts/map_presentation.gd"
## Compatibility entry point: the rescue fixture uses the shared biome renderer.
const Presets = preload("res://scripts/gfx_theme_presets.gd")

func apply_environment(world: WorldEnvironment, key: DirectionalLight3D, theme_name: String) -> void:
	var preset: Dictionary = Presets.get_preset(theme_name)
	var t: Dictionary = themes.get(theme_name,themes.temple)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = color(int(t.sky[0])).darkened(0.18)
	sky_material.sky_horizon_color = Color(preset.fog).lerp(color(int(t.sky[1])),0.35)
	sky_material.ground_bottom_color = color(int(t.ground))
	sky_material.ground_horizon_color = Color(preset.fog)
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(preset.ambient)
	env.ambient_light_energy = maxf(0.58, float(preset.ambient_power))
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = float(preset.exposure)
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 0.91
	env.ssao_enabled = true
	env.ssao_intensity = 0.82
	env.ssao_radius = 0.85
	env.glow_enabled = true
	env.glow_intensity = float(preset.glow)
	env.fog_enabled = true
	env.fog_light_color = Color(preset.fog)
	env.fog_density = float(preset.fog_density)
	env.fog_height_density = float(preset.height)
	env.fog_aerial_perspective = 0.28
	if graphics_low(key):
		var grade: Dictionary = Presets.low_grade(theme_name)
		env.ambient_light_color = grade.ambient
		env.adjustment_contrast = grade.contrast
		env.adjustment_saturation = grade.saturation
		env.fog_density = grade.density
		env.fog_height_density = grade.height
	world.environment = env
	key.light_color = Color(preset.sun)
	key.light_energy = float(preset.sun_power) * 1.13
	key.rotation_degrees = preset.sun_angle
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 60
	key.light_angular_distance = 1.7
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	var graphics := key.get_node_or_null("/root/Graphics")
	if graphics != null and str(graphics.effective) != "low":
		var warm: bool = theme_name in ["temple", "ruins", "plains"]
		var cold: bool = theme_name == "snow"
		key.light_energy = 2.25 if warm else 2.05 if cold else 1.85
		env.ambient_light_color = Color("504959") if warm else Color("45617d") if cold else Color("284d62")
		env.ambient_light_energy = 0.38 if warm else 0.34 if cold else 0.40
		env.adjustment_contrast = 1.20
	_apply_mood(key, theme_name, preset)

func graphics_low(key: DirectionalLight3D) -> bool:
	var graphics := key.get_node_or_null("/root/Graphics")
	return graphics != null and str(graphics.effective) == "low"

func _apply_mood(key: DirectionalLight3D, theme_name: String, preset: Dictionary) -> void:
	var game := key.get_parent() as Node3D
	if game == null or game.get("mission") == null: return
	var graphics := game.get_node_or_null("/root/Graphics")
	var low: bool = graphics != null and str(graphics.effective) == "low"
	var old := game.get_node_or_null("Cine15PropPools")
	if old != null: game.remove_child(old); old.queue_free()
	var pools := Node3D.new(); pools.name = "Cine15PropPools"; game.add_child(pools)
	var tint := Color("36b1ce") if theme_name in ["city", "dock", "caves"] else Color("d18d76") if theme_name in ["temple", "ruins", "plains"] else Color("5d93ce") if theme_name == "snow" else Color("92c078")
	if not low:
		var fill := DirectionalLight3D.new(); fill.name = "Cine15ColorFill"
		fill.light_color = tint; fill.light_energy = 0.72 if theme_name == "snow" else 0.58
		fill.rotation_degrees = Vector3(-34, 125, 0); fill.shadow_enabled = false
		pools.add_child(fill)
	var squad: Array[Dictionary] = game.mission.living("player")
	var anchor := Vector2(float(squad[0].x), float(squad[0].y)) if not squad.is_empty() else Vector2(float(game.mission.spec.width) * 0.5, float(game.mission.spec.height) * 0.5)
	var anchor_tile := Vector2i(roundi(anchor.x), roundi(anchor.y))
	var ambient = preload("res://scripts/w23_lightfx_ambient.gd").new()
	ambient.configure(theme_name, Vector2(minf(float(game.mission.spec.width), 12.0), minf(float(game.mission.spec.height), 12.0)), low,
		Vector3(anchor.x, Shot.elevation(game.mission, anchor_tile) * 0.7, anchor.y))
	pools.add_child(ambient)
	var contact_pool: MultiMeshInstance3D
	if low:
		contact_pool = MultiMeshInstance3D.new(); contact_pool.name = "LightfxContactDarkening"
		var plane := PlaneMesh.new(); plane.size = Vector2(1.35, 1.35)
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color("101018", 0.30)
		mat.albedo_texture = _pool_texture(); mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		plane.material = mat
		var instances := MultiMesh.new(); instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.instance_count = 12; instances.mesh = plane
		contact_pool.multimesh = instances; contact_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pools.add_child(contact_pool)
		for i in 12:
			contact_pool.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.0001), Vector3.ZERO))
		var contact_index := 0
		for unit in game.mission.units:
			if contact_index >= 12: break
			if int(unit.hp) <= 0 or str(unit.side) == "enemy" and not bool(unit.awake) and not bool(unit.get("spotted", false)): continue
			var tile := Vector2i(int(unit.x), int(unit.y))
			var at := Vector3(float(tile.x), Shot.elevation(game.mission, tile) * 0.7 + 0.035, float(tile.y))
			contact_pool.multimesh.set_instance_transform(contact_index, Transform3D(Basis.IDENTITY, at))
			contact_index += 1
	var offsets := [Vector2(-2.0, -2.0), Vector2(3.0, 1.0)]
	for index in offsets.size():
		var offset: Vector2 = offsets[index]
		var tile := Vector2i(clampi(roundi(anchor.x + offset.x), 1, int(game.mission.spec.width) - 2), clampi(roundi(anchor.y + offset.y), 1, int(game.mission.spec.height) - 2))
		var at := Vector3(float(tile.x), Shot.elevation(game.mission, tile) * 0.7 + 0.16, float(tile.y))
		if not low:
			var lamp := OmniLight3D.new(); lamp.name = "Cine15PropLamp"
			lamp.position = at + Vector3.UP * 2.1; lamp.light_color = tint
			lamp.light_energy = 1.05; lamp.omni_range = 4.2; lamp.shadow_enabled = false
			pools.add_child(lamp)

func _pool_texture() -> ImageTexture:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var radius := Vector2((float(x) - 15.5) / 15.5, (float(y) - 15.5) / 15.5).length()
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, 1.0 - smoothstep(0.1, 1.0, radius)))
	return ImageTexture.create_from_image(image)
