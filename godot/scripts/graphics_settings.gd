extends Node
## Presentation only. The renderer is selected by Godot before autoloads start.
signal changed
const TIERS := ["low", "medium", "high"]
const CONFIG := "user://graphics.cfg"
const OVERRIDE := "user://override.cfg"
const Resources = preload("res://scripts/graphics_resources.gd")
var requested := "high"
var effective := "high"
var battle := false
var resources := Resources.new()

static func mobile_os(os_name: String = OS.get_name()) -> bool:
	return os_name in ["Android", "iOS"]

static func default_tier(os_name: String = OS.get_name()) -> String:
	return "low" if mobile_os(os_name) else "high"

static func effective_tier(wanted: String, renderer: String) -> String:
	return "low" if renderer == "gl_compatibility" else wanted

func _ready() -> void:
	requested = read_tier()
	# Automated fixtures can select quality without modifying a player's preferences.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--graphics=") and arg.get_slice("=",1) in TIERS:
			requested = arg.get_slice("=",1)
	effective = effective_tier(requested,RenderingServer.get_current_rendering_method())
	get_tree().node_added.connect(_added)
	apply_node(weakref(get_tree().root))
	apply_all.call_deferred()

func read_tier(path: String = CONFIG) -> String:
	var config := ConfigFile.new()
	if config.load(path) != OK: return default_tier()
	var value := str(config.get_value("graphics","tier",default_tier()))
	return value if value in TIERS else default_tier()

func select_tier(value: String, persist := true) -> Error:
	if value not in TIERS: return ERR_INVALID_PARAMETER
	if persist:
		var error := save_tier(value)
		if error != OK: return error
	requested = value
	effective = effective_tier(requested,RenderingServer.get_current_rendering_method())
	apply_all()
	changed.emit()
	return OK

func save_tier(value: String, config_path: String = CONFIG, override_path: String = OVERRIDE) -> Error:
	# Preserve unrelated overrides. Include .mobile so an explicit High choice wins there.
	var overrides := ConfigFile.new()
	if FileAccess.file_exists(override_path) and overrides.load(override_path) != OK: return ERR_FILE_CORRUPT
	var method := "gl_compatibility" if value == "low" else "forward_plus"
	overrides.set_value("rendering","renderer/rendering_method",method)
	overrides.set_value("rendering","renderer/rendering_method.mobile",method)
	overrides.set_value("rendering","rendering_device/fallback_to_opengl3",true)
	var error := overrides.save(override_path)
	if error != OK: return error
	var config := ConfigFile.new()
	config.set_value("graphics","tier",value)
	return config.save(config_path)

func needs_restart() -> bool:
	var desired := "gl_compatibility" if requested == "low" else "forward_plus"
	return RenderingServer.get_current_rendering_method() != desired

func status_text() -> String:
	if needs_restart():
		return "Renderer change applies on restart. Active: %s." % effective.capitalize()
	return "Active: %s. Changes saved." % effective.capitalize()

func _added(node: Node) -> void:
	if node is Viewport or node is WorldEnvironment or node is Light3D or node is GeometryInstance3D or node is GPUParticles3D or node is CPUParticles3D:
		apply_node.call_deferred(weakref(node))

func original(object: Object, property: String) -> Variant:
	var key := "graphics_"+property
	if not object.has_meta(key): object.set_meta(key,object.get(property))
	return object.get_meta(key)

func apply_all() -> void:
	apply_globals()
	walk(get_tree().root)

func walk(node: Node) -> void:
	apply_node(weakref(node))
	for child in node.get_children(): walk(child)

func apply_globals() -> void:
	var high := effective == "high"
	var shadows := "rendering/lights_and_shadows/directional_shadow/"
	RenderingServer.directional_shadow_atlas_set_size((2048 if battle else int(ProjectSettings.get_setting(shadows+"size"))) if high else 1024,true if battle or not high else bool(ProjectSettings.get_setting(shadows+"16_bits")))
	RenderingServer.directional_soft_shadow_filter_set_quality((RenderingServer.SHADOW_QUALITY_SOFT_LOW if battle else int(ProjectSettings.get_setting(shadows+"soft_shadow_filter_quality"))) if high else RenderingServer.SHADOW_QUALITY_HARD)
	if RenderingServer.get_current_rendering_method() == "gl_compatibility": return
	var ao := "rendering/environment/ssao/"
	RenderingServer.environment_set_ssao_quality(RenderingServer.ENV_SSAO_QUALITY_LOW if battle or not high else int(ProjectSettings.get_setting(ao+"quality")),true if battle or not high else bool(ProjectSettings.get_setting(ao+"half_size")),0.5 if battle or not high else float(ProjectSettings.get_setting(ao+"adaptive_target")),2 if battle or not high else int(ProjectSettings.get_setting(ao+"blur_passes")),40 if battle or not high else float(ProjectSettings.get_setting(ao+"fadeout_from")),80 if battle or not high else float(ProjectSettings.get_setting(ao+"fadeout_to")))

func apply_environment(env: Environment) -> void:
	for property in ["ssao_enabled","ssil_enabled","glow_enabled","volumetric_fog_enabled"]:
		var baseline = original(env,property)
		env.set(property,baseline if effective != "low" else false)
	for property in ["ssao_intensity","ssil_intensity","glow_intensity","volumetric_fog_density"]:
		env.set(property,float(original(env,property))*(0.6 if effective == "medium" else 1.0))

func apply_node(reference: WeakRef) -> void:
	var node = reference.get_ref()
	if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion(): return
	var high := effective == "high"
	var low := effective == "low"
	if node is Viewport:
		for property in ["msaa_3d","screen_space_aa","mesh_lod_threshold","scaling_3d_scale"]: original(node,property)
		node.msaa_3d = original(node,"msaa_3d") if high else Viewport.MSAA_DISABLED
		node.screen_space_aa = original(node,"screen_space_aa") if high else (Viewport.SCREEN_SPACE_AA_DISABLED if RenderingServer.get_current_rendering_method() == "gl_compatibility" else Viewport.SCREEN_SPACE_AA_FXAA)
		node.mesh_lod_threshold = (4.0 if battle and node == get_tree().root else float(original(node,"mesh_lod_threshold")))*(3.0 if low else 1.5 if not high else 1.0)
		node.scaling_3d_scale = 0.75 if low and mobile_os() else original(node,"scaling_3d_scale")
	if node is WorldEnvironment and node.environment: apply_environment(node.environment)
	if node is Light3D:
		original(node,"shadow_enabled")
		if node is DirectionalLight3D: original(node,"light_angular_distance")
		node.shadow_enabled = original(node,"shadow_enabled") if not low else false
		if node is DirectionalLight3D: node.light_angular_distance = original(node,"light_angular_distance") if high else 0.0
	if node is GPUParticles3D or node is CPUParticles3D:
		node.amount = maxi(1,roundi(float(original(node,"amount"))*(0.2 if low else 0.5 if not high else 1.0)))
	if node is GeometryInstance3D:
		if node.has_meta("graphics_lod"):
			for property in ["visible","visibility_range_begin","visibility_range_end"]: original(node,property)
			node.visible = original(node,"visible") if not low or int(node.get_meta("graphics_lod")) == 1 else false
			for property in ["visibility_range_begin","visibility_range_end"]:
				node.set(property,0.0 if low else float(original(node,property))*(0.6 if not high else 1.0))
		resources.apply(node,low)
