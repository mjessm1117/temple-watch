extends Node
## Presentation only. The renderer is selected by Godot before autoloads start.
signal changed
const TIERS := ["low", "medium", "high"]
const CONFIG := "user://graphics.cfg"
const OVERRIDE := "user://override.cfg"
const Resources = preload("res://scripts/graphics_resources.gd")
const BattleArt = preload("res://scripts/env_art.gd")
const Readability = preload("res://scripts/gfx_unit_readability.gd")
const Materials13 = preload("res://scripts/gfx13_materials.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var requested := "high"
var effective := "high"
var battle := false
var resources := Resources.new()

static func mobile_os(os_name: String = OS.get_name()) -> bool:
	return os_name in ["Android", "iOS"]

static func default_tier(os_name: String = OS.get_name(), web := OS.has_feature("web"), mobile := OS.has_feature("mobile"), touchscreen := DisplayServer.is_touchscreen_available()) -> String:
	return "low" if web or mobile or touchscreen or mobile_os(os_name) else "high"

static func phone_ui_scale(size: Vector2i) -> float:
	return 1.2 if Phone.narrow(size) else 1.0

func update_window_layout() -> void:
	if DisplayServer.window_get_size() == Vector2i.ZERO and get_tree().root.size.x < 486:
		get_tree().root.size = Vector2i(1366, 768)
	var physical := Phone.window_size()
	var base := Vector2i(Phone.logical_size(physical).round()) if Phone.narrow(physical) else Vector2i(1366, 768)
	if get_tree().root.content_scale_size != base: get_tree().root.content_scale_size = base
	var factor := phone_ui_scale(physical) if DisplayServer.window_get_size().x > 0 or Phone.narrow(physical) else 1.0
	if get_tree().root.content_scale_factor != factor: get_tree().root.content_scale_factor = factor

static func effective_tier(wanted: String, renderer: String) -> String:
	return "low" if renderer == "gl_compatibility" else wanted

func _ready() -> void:
	update_window_layout()
	get_tree().root.size_changed.connect(func():
		update_window_layout()
		apply_all.call_deferred())
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
	var report := node is Control and node.get_script() != null and str(node.get_script().resource_path).ends_with("sith_screen.gd")
	var story := node is Control and node.get_script() != null and str(node.get_script().resource_path).ends_with("story_screen.gd")
	if report or story or node is Button or node is Label or node is Viewport or node is WorldEnvironment or node is Light3D or node is GeometryInstance3D or node is GPUParticles3D or node is CPUParticles3D:
		apply_node.call_deferred(weakref(node))
		if report:
			node.child_entered_tree.connect(func(_child: Node) -> void: _ensure_phone_report_close.call_deferred(weakref(node)))
			node.child_entered_tree.connect(func(_child: Node) -> void: _adapt_phone_report.call_deferred(weakref(node)))
		if story:
			node.child_entered_tree.connect(func(_child: Node) -> void: _adapt_phone_story.call_deferred(weakref(node)))

func _ensure_phone_report_close(reference: WeakRef) -> void:
	var screen = reference.get_ref()
	if not is_instance_valid(screen) or not Phone.narrow(Phone.window_size()) or screen.has_node("PhoneClose"): return
	var safe := Phone.safe_margins(screen.get_viewport_rect().size)
	var close := Button.new(); close.name = "PhoneClose"; close.text = "CLOSE"
	close.anchor_left = 1.0; close.anchor_right = 1.0
	close.offset_left = -safe.z - 110; close.offset_right = -safe.z - 8; close.offset_top = safe.y + 8; close.offset_bottom = safe.y + 48
	close.pressed.connect(screen._close)
	screen.add_child(close)

func _adapt_phone_report(reference: WeakRef) -> void:
	var screen = reference.get_ref()
	if not is_instance_valid(screen) or not Phone.narrow(Phone.window_size()) or not is_instance_valid(screen.body): return
	var body: VBoxContainer = screen.body
	if body.get_child_count() < 5 or body.has_node("PhoneTabScroll"): return
	var margin: MarginContainer = body.get_parent()
	var safe := Phone.safe_margins(screen.get_viewport_rect().size)
	margin.add_theme_constant_override("margin_left", 8 + int(safe.x))
	margin.add_theme_constant_override("margin_right", 8 + int(safe.z))
	margin.add_theme_constant_override("margin_top", 6 + int(safe.y))
	margin.add_theme_constant_override("margin_bottom", 6 + int(safe.w))
	body.add_theme_constant_override("separation", 5)
	var heading: HBoxContainer = body.get_child(0)
	heading.get_child(1).hide()
	heading.get_child(2).hide()
	var title: VBoxContainer = heading.get_child(0)
	(title.get_child(1) as Label).add_theme_font_size_override("font_size", 23)
	var tabs: HBoxContainer = body.get_child(2)
	var tab_scroll := preload("res://scripts/touch_scroll.gd").new(); tab_scroll.name = "PhoneTabScroll"
	tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_scroll.custom_minimum_size.y = 40; body.add_child(tab_scroll); body.move_child(tab_scroll, 2)
	tabs.reparent(tab_scroll)
	tab_scroll.get_h_scroll_bar().modulate.a = 0.0
	var project_box: VBoxContainer = body.get_child(1).get_child(1)
	var project_row: HBoxContainer = project_box.get_child(0)
	if project_row.get_child_count() > 1:
		var date: Label = project_row.get_child(1)
		date.reparent(project_box)
		date.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(project_box.get_child(2) as Label).text = "Conduit -2 · Stronghold -1 · Final pursuit -2"
	var content: VBoxContainer = screen.page_content
	for child in content.get_children():
		if not child is HBoxContainer: continue
		var position := child.get_index()
		var stack := VBoxContainer.new(); stack.add_theme_constant_override("separation", 8)
		content.add_child(stack); content.move_child(stack, position)
		for column in child.get_children():
			column.reparent(stack)
			if column is Control: column.custom_minimum_size.x = 0
		child.queue_free()

func _adapt_phone_story(reference: WeakRef) -> void:
	var screen = reference.get_ref()
	if not is_instance_valid(screen) or not Phone.narrow(Phone.window_size()) or screen.mode == "codex": return
	if not is_instance_valid(screen.outer_frame) or not is_instance_valid(screen.body): return
	var outer: MarginContainer = screen.outer_frame
	var safe := Phone.safe_margins(screen.get_viewport_rect().size)
	outer.add_theme_constant_override("margin_left", 8 + int(safe.x))
	outer.add_theme_constant_override("margin_right", 8 + int(safe.z))
	outer.add_theme_constant_override("margin_top", 6 + int(safe.y))
	outer.add_theme_constant_override("margin_bottom", 6 + int(safe.w))
	var body: VBoxContainer = screen.body
	if body.get_child_count() < 4: return
	body.add_theme_constant_override("separation", 4)
	var row: HBoxContainer = body.get_child(2)
	if row.get_child_count() < 2: return
	row.get_child(0).hide()
	var frame: Control = row.get_child(1)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.get_child(3).hide()
	var content: VBoxContainer = screen.choices_box.get_parent()
	if not content.has_node("PhoneSpeaker"):
		var speaker := Label.new(); speaker.name = "PhoneSpeaker"
		speaker.text = "SPEAKER  " + str(screen.scene_data.get("name", "Jedi Council"))
		speaker.add_theme_font_size_override("font_size", 14)
		content.add_child(speaker); content.move_child(speaker, 0)

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
	RenderingServer.directional_soft_shadow_filter_set_quality((RenderingServer.SHADOW_QUALITY_SOFT_LOW if battle else int(ProjectSettings.get_setting(shadows+"soft_shadow_filter_quality"))) if high else RenderingServer.SHADOW_QUALITY_HARD if effective == "low" else RenderingServer.SHADOW_QUALITY_SOFT_LOW)
	if RenderingServer.get_current_rendering_method() == "gl_compatibility": return
	var ao := "rendering/environment/ssao/"
	RenderingServer.environment_set_ssao_quality(RenderingServer.ENV_SSAO_QUALITY_LOW if battle or not high else int(ProjectSettings.get_setting(ao+"quality")),true if battle or not high else bool(ProjectSettings.get_setting(ao+"half_size")),0.5 if battle or not high else float(ProjectSettings.get_setting(ao+"adaptive_target")),2 if battle or not high else int(ProjectSettings.get_setting(ao+"blur_passes")),40 if battle or not high else float(ProjectSettings.get_setting(ao+"fadeout_from")),80 if battle or not high else float(ProjectSettings.get_setting(ao+"fadeout_to")))

func apply_environment(env: Environment) -> void:
	for property in ["ssao_enabled","ssil_enabled","glow_enabled","volumetric_fog_enabled","adjustment_enabled"]:
		var baseline = original(env,property)
		env.set(property,baseline if (effective == "high" or property in ["glow_enabled","adjustment_enabled"] and effective == "medium") else false)
	for property in ["ssao_intensity","ssil_intensity","glow_intensity","volumetric_fog_density"]:
		env.set(property,float(original(env,property))*(0.65 if effective == "medium" else 1.0))
	for property in ["fog_enabled","fog_height_density"]:
		var baseline = original(env,property)
		env.set(property,(baseline if effective != "low" else false) if property == "fog_enabled" else float(baseline)*(1.0 if effective == "high" else 0.0))

func apply_node(reference: WeakRef) -> void:
	var node = reference.get_ref()
	if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion(): return
	if node is Control and node.get_script() != null and str(node.get_script().resource_path).ends_with("sith_screen.gd"):
		_ensure_phone_report_close(reference)
		_adapt_phone_report(reference)
		return
	if node is Control and node.get_script() != null and str(node.get_script().resource_path).ends_with("story_screen.gd"):
		_adapt_phone_story(reference)
		return
	if node is Button:
		var minimum := 38.0 if Phone.narrow(Phone.window_size()) else 72.0
		var scaled := DisplayServer.window_get_size().x > 0 or Phone.narrow(Phone.window_size())
		node.custom_minimum_size.y = maxf(float(original(node,"custom_minimum_size").y),minimum) if scaled and phone_ui_scale(Phone.window_size()) > 1.0 else original(node,"custom_minimum_size").y
		return
	if node is Label:
		if not node.has_meta("phone_font_size"): node.set_meta("phone_font_size", node.get_theme_font_size("font_size"))
		var base := int(node.get_meta("phone_font_size"))
		var inside_room := node.get_parent() is Button and str(node.get_parent().name).begins_with("Room_")
		node.add_theme_font_size_override("font_size", maxi(base, 12) if Phone.narrow(Phone.window_size()) and not inside_room else base)
		return
	var high := effective == "high"
	var low := effective == "low"
	if node is Viewport:
		for property in ["msaa_3d","screen_space_aa","mesh_lod_threshold","scaling_3d_scale"]: original(node,property)
		node.msaa_3d = original(node,"msaa_3d") if high else Viewport.MSAA_DISABLED
		node.screen_space_aa = original(node,"screen_space_aa") if high else (Viewport.SCREEN_SPACE_AA_DISABLED if RenderingServer.get_current_rendering_method() == "gl_compatibility" else Viewport.SCREEN_SPACE_AA_FXAA)
		node.mesh_lod_threshold = (4.0 if battle and node == get_tree().root else float(original(node,"mesh_lod_threshold")))*(3.0 if low else 1.5 if not high else 1.0)
		node.scaling_3d_scale = 0.75 if low and mobile_os() else original(node,"scaling_3d_scale")
	if node is WorldEnvironment and node.environment:
		var owner = node.get_parent()
		if owner != null and owner.has_method("_build_terrain") and owner.scene_view != null and owner.scene_view.sun != null:
			var art = BattleArt.new()
			art.apply_environment(node,owner.scene_view.sun,str(owner.mission.spec.get("theme","temple")))
			art.free()
			if owner.terrain.get_child_count() > 0: Materials13.apply(owner.terrain.get_child(0),low)
		apply_environment(node.environment)
	if node is Light3D:
		original(node,"shadow_enabled")
		if node is DirectionalLight3D: original(node,"light_angular_distance")
		node.shadow_enabled = original(node,"shadow_enabled") if not low else false
		if node is DirectionalLight3D: node.light_angular_distance = original(node,"light_angular_distance") if high else 0.0
	if node is GPUParticles3D or node is CPUParticles3D:
		node.amount = maxi(1,roundi(float(original(node,"amount"))*(0.2 if low else 0.5 if not high else 1.0)))
	if node is GeometryInstance3D:
		Readability.apply(node)
		if node.has_meta("graphics_lod"):
			for property in ["visible","visibility_range_begin","visibility_range_end"]: original(node,property)
			node.visible = original(node,"visible") if not low or int(node.get_meta("graphics_lod")) == 1 else false
			for property in ["visibility_range_begin","visibility_range_end"]:
				node.set(property,0.0 if low else float(original(node,property))*(0.6 if not high else 1.0))
		resources.apply(node,low)

func _process(_delta: float) -> void:
	# The existing action camera marks only ability/attack cinematic shots.
	for child in get_tree().root.get_children():
		if phone_ui_scale(Phone.window_size()) > 1.0 and child.has_method("_deploy") and child.has_method("_layout") and is_instance_valid(child.footer):
			# Keep the deployment controls between the stage and cards on short screens.
			child.stage_container.size.y = 130.0
			child.footer.position.y = 250.0
			child.footer.size.y = 72.0
		if not child.has_method("_build_terrain") or child.camera == null: continue
		Readability.update_selection(child)
		var enabled: bool = effective == "high" and bool(child.cinematic)
		if bool(child.camera.get_meta("gfx_dof",false)) == enabled: continue
		child.camera.set_meta("gfx_dof",enabled)
		if child.camera.attributes == null: child.camera.attributes = CameraAttributesPractical.new()
		child.camera.attributes.dof_blur_far_enabled = enabled
		child.camera.attributes.dof_blur_far_distance = 8.0
		child.camera.attributes.dof_blur_far_transition = 8.0
