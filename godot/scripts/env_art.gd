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
	env.ambient_light_energy = float(preset.ambient_power)
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
	world.environment = env
	key.light_color = Color(preset.sun)
	key.light_energy = float(preset.sun_power)
	key.rotation_degrees = preset.sun_angle
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 60
	key.light_angular_distance = 1.7
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
