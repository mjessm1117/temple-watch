extends Node3D

const Audio = preload("res://scripts/audio.gd")
const W17_ROOT := "res://assets/units/w17/"
const W17_KINDS := ["sniper", "heavy", "tech", "droid", "officer"]
var unit_id: int
var model: Node3D
var animation: AnimationPlayer
var lod_animation: AnimationPlayer
var lod2_animation: AnimationPlayer
var base_clip := "idle"
var motion: Tween
var turn_motion: Tween
var pose_motion: Tween
var alive := true
var ring: MeshInstance3D
var foot: AudioStreamPlayer
var hum: AudioStreamPlayer
var saber_blade: MeshInstance3D
var saber_halo: MeshInstance3D
var saber_active := false
var saber_halo_enabled := true
static var _saber_mesh: ArrayMesh
static var _saber_shader: Shader
var _step_stream: AudioStreamWAV
var _action_serial := 0
var _cover_level := 0
var downed := false
var enemy_side := false
var aim_ready := false
var footfalls := 0
static var _corpses: Array[Node3D] = []
static var _active_feet24: Array[AudioStreamPlayer] = []
const CORPSE_CAP := 6
const CORPSE_LIFETIME := 9.0
const FALL_SECONDS := 0.78

func setup(u: Dictionary, scene: PackedScene, at: Vector3) -> void:
	unit_id = int(u.id)
	enemy_side = str(u.side) == "enemy"
	position = at
	var kind := w17_kind(u)
	var selected := battle_model_scene(u, scene)
	model = selected.instantiate()
	model.scale = Vector3.ONE * 1.2
	add_child(model)
	if kind in W17_KINDS:
		var low_scene := load(W17_ROOT + kind + "_lod1.glb") as PackedScene
		if low_scene != null:
			var low := low_scene.instantiate() as Node3D
			model.add_child(low)
			_set_lod_range(model, 0.0, 26.0, low)
			var far_scene := load(W17_ROOT + kind + "_lod2.glb") as PackedScene
			if far_scene != null:
				_set_lod_range(low, 26.0, 42.0)
				var far := far_scene.instantiate() as Node3D
				low.add_child(far)
				_set_lod_range(far, 42.0, 0.0)
				lod2_animation = _find_animation(far)
			else:
				_set_lod_range(low, 26.0, 0.0)
			lod_animation = _find_animation(low)
	ring = MeshInstance3D.new()
	var disc := CylinderMesh.new(); disc.top_radius = 0.48; disc.bottom_radius = 0.48; disc.height = 0.035
	ring.mesh = disc; ring.position.y = 0.025; add_child(ring)
	set_selected(false, str(u.side) == "enemy")
	animation = _find_animation(model)
	base_clip = "saberIdle" if str(u.class_name) in ["Guardian", "Consular"] else "gunIdle"
	if base_clip == "saberIdle" and str(u.get("model", "")) == "jedi": _attach_saber(u)
	play(base_clip)
	foot = AudioStreamPlayer.new()
	foot.volume_db = -22.0
	var synth := Audio.new()
	_step_stream = synth._synthesize("step")
	var hum_stream := synth._synthesize("hum") if saber_blade != null else null
	synth.free()
	foot.stream = _step_stream
	add_child(foot)
	if saber_blade != null:
		hum = AudioStreamPlayer.new()
		hum.stream = hum_stream
		add_child(hum)
		set_saber_active(true)

func _process(_delta: float) -> void:
	if hum == null: return
	var game := get_parent().get_parent() if get_parent() != null else null
	var sound: Node = game.get("sound") if game != null else null
	hum.volume_linear = 0.0 if sound == null or bool(sound.get("muted")) else float(sound.get("volume")) * 0.055

func set_saber_active(value: bool) -> void:
	saber_active = value and alive and not downed and saber_blade != null
	if saber_blade != null: saber_blade.visible = saber_active
	if hum != null:
		if saber_active and not hum.playing: hum.play()
		elif not saber_active: hum.stop()

func set_saber_halo(enabled: bool) -> void:
	saber_halo_enabled = enabled
	if saber_blade != null:
		(saber_blade.material_override as ShaderMaterial).set_shader_parameter("halo_alpha", 0.23 if enabled else 0.0)

static func battle_model_path(u: Dictionary) -> String:
	var kind := w17_kind(u)
	return W17_ROOT + kind + ".glb" if kind in W17_KINDS else "res://assets/models/units/%s.glb" % str(u.get("model", "trooper"))

static func battle_model_scene(u: Dictionary, fallback: PackedScene) -> PackedScene:
	var kind := w17_kind(u)
	if kind not in W17_KINDS: return fallback
	return load(battle_model_path(u)) as PackedScene

static func w17_kind(u: Dictionary) -> String:
	var cls := str(u.get("class_name", "")).to_lower()
	return cls if cls in W17_KINDS else str(u.get("kind", "")).to_lower()

func _set_lod_range(node: Node, begin: float, end: float, skip: Node = null) -> void:
	if node == skip: return
	if node is GeometryInstance3D:
		node.visibility_range_begin = begin
		node.visibility_range_end = end
		node.visibility_range_begin_margin = 1.5 if begin > 0.0 else 0.0
		node.visibility_range_end_margin = 1.5 if end > 0.0 else 0.0
		node.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	for child in node.get_children(): _set_lod_range(child, begin, end, skip)

func _find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := _find_animation(child)
		if found != null: return found
	return null

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null: return found
	return null

func _attach_saber(u: Dictionary) -> void:
	var skeleton := _find_skeleton(model)
	if skeleton == null or skeleton.find_bone("hand_r") < 0: return
	var hand := BoneAttachment3D.new()
	hand.bone_name = "hand_r"
	skeleton.add_child(hand)
	var grip := Node3D.new()
	# BoneAttachment3D is already in model units; keep the blade beside the hand.
	grip.scale = Vector3.ONE
	grip.rotation.x = PI
	grip.position.y = 0.07
	hand.add_child(grip)
	var hilt := MeshInstance3D.new()
	var hilt_mesh := CylinderMesh.new()
	hilt_mesh.top_radius = 0.045; hilt_mesh.bottom_radius = 0.045; hilt_mesh.height = 0.24
	hilt.mesh = hilt_mesh; grip.add_child(hilt)
	var steel := StandardMaterial3D.new(); steel.albedo_color = Color("a8b7bc")
	hilt.material_override = steel
	var blade := MeshInstance3D.new()
	blade.mesh = _blade_mesh(); blade.position.y = 0.62
	var color := Color(str(u.get("col", "#79d3e2")))
	var glow := ShaderMaterial.new()
	glow.shader = _blade_shader()
	glow.set_shader_parameter("blade_color", color)
	blade.material_override = glow; grip.add_child(blade)
	saber_blade = blade
	saber_halo = blade
	set_saber_halo(saber_halo_enabled)

static func _blade_mesh() -> ArrayMesh:
	if _saber_mesh != null: return _saber_mesh
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for spec in [[0.038, 1.06, 8, 4, 1.0], [0.105, 1.08, 6, 1, 0.2]]:
		var capsule := CapsuleMesh.new()
		capsule.radius = spec[0]; capsule.height = spec[1]
		capsule.radial_segments = spec[2]; capsule.rings = spec[3]
		var faces := capsule.get_faces()
		for i in range(0, faces.size(), 3):
			var normal := (faces[i + 1] - faces[i]).cross(faces[i + 2] - faces[i]).normalized()
			for j in 3:
				surface.set_normal(normal)
				surface.set_color(Color(1.0, 1.0, 1.0, spec[4]))
				surface.add_vertex(faces[i + j])
	_saber_mesh = surface.commit()
	return _saber_mesh

static func _blade_shader() -> Shader:
	if _saber_shader != null: return _saber_shader
	_saber_shader = Shader.new()
	_saber_shader.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 blade_color : source_color = vec4(0.48, 0.83, 0.89, 1.0);
uniform float halo_alpha = 0.23;
void fragment() {
	float shell = step(COLOR.a, 0.5);
	ALBEDO = blade_color.rgb;
	EMISSION = blade_color.rgb * mix(2.4, 1.2, shell);
	ALPHA = mix(1.0, halo_alpha, shell);
}"""
	return _saber_shader

func play(clip: String) -> void:
	if animation == null: return
	animation.speed_scale = float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed")) * (RescueSettings.enemy_speed() if enemy_side else 1.0)
	if lod_animation != null: lod_animation.speed_scale = animation.speed_scale
	if lod2_animation != null: lod2_animation.speed_scale = animation.speed_scale
	var name := clip if animation.has_animation(clip) else base_clip if animation.has_animation(base_clip) else "idle"
	var blend := 0.12 if name == "run" else 0.18 if animation.current_animation == "run" else 0.08 if name == "shoot" else 0.1
	if animation.has_animation(name) and animation.current_animation != name:
		animation.play(name, blend)
	if lod_animation != null and lod_animation.has_animation(name) and lod_animation.current_animation != name:
		lod_animation.play(name, blend)
	if lod2_animation != null and lod2_animation.has_animation(name) and lod2_animation.current_animation != name:
		lod2_animation.play(name, blend)

func set_selected(value: bool, enemy: bool) -> void:
	if ring == null: return
	var color := Color("f7d381") if value else Color("f17065") if enemy else Color("5cc9e8")
	if preload("res://scripts/campaign/strat_preferences.gd").get_value("cb") and not value: color = Color("ffb454") if enemy else Color("47c8ff")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.55 if value else 0.24)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true; material.emission = color
	ring.material_override = material
	ring.scale = Vector3.ONE * (1.15 if value else 1.0)

func set_cover(level: int) -> void:
	if downed: return
	level = clampi(level, 0, 2)
	if level == _cover_level: return
	_cover_level = level
	if model == null or not alive: return
	var target_y := -0.24 if _cover_level == 2 else -0.12 if _cover_level == 1 else 0.0
	var tween := _paced_tween()
	tween.tween_property(model, "position:y", target_y, 0.16)

func set_downed(value: bool) -> void:
	if value == downed or not alive or model == null: return
	downed = value
	if saber_blade != null: set_saber_active(not value)
	if pose_motion != null and pose_motion.is_running(): pose_motion.kill()
	pose_motion = _paced_tween().set_parallel(true)
	pose_motion.tween_property(model, "rotation:z", 1.35 if value else 0.0, 0.35)
	pose_motion.tween_property(model, "position:y", -0.48 if value else 0.0, 0.35)
	if value: play("death")
	else: play(base_clip)

func stagger_to(point: Vector3) -> void:
	if not alive: return
	act("hit")
	if motion != null and motion.is_running(): motion.kill()
	motion = _paced_tween()
	motion.tween_property(self, "position", point, 0.27).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func act(clip: String) -> void:
	if not alive or downed: return
	_action_serial += 1
	var serial := _action_serial
	if pose_motion != null and pose_motion.is_running(): pose_motion.kill()
	if clip == "hit":
		play("hit")
		pose_motion = _paced_tween()
		pose_motion.tween_property(model, "rotation:z", 0.32, 0.09)
		pose_motion.parallel().tween_property(model, "position:x", -0.16, 0.09)
		pose_motion.tween_property(model, "rotation:z", 0.0, 0.30).set_trans(Tween.TRANS_BACK)
		pose_motion.parallel().tween_property(model, "position:x", 0.0, 0.30)
	else:
		var delay := 0.12 if turn_motion != null and turn_motion.is_running() else 0.0
		get_tree().create_timer(delay/(float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed")) * (RescueSettings.enemy_speed() if enemy_side else 1.0))).timeout.connect(func() -> void:
			if not is_instance_valid(self) or not alive or serial != _action_serial: return
			play(clip)
			pose_motion = _paced_tween()
			pose_motion.tween_property(model, "rotation:x", -0.11 if clip == "shoot" else -0.2, 0.09)
			pose_motion.tween_property(model, "rotation:x", 0.0, 0.24))
	get_tree().create_timer(0.52/(float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed")) * (RescueSettings.enemy_speed() if enemy_side else 1.0))).timeout.connect(func() -> void:
		if is_instance_valid(self) and alive and serial == _action_serial: play(base_clip))

func flinch24() -> void:
	if not alive or downed or model == null: return
	if pose_motion != null and pose_motion.is_running(): pose_motion.kill()
	pose_motion = _paced_tween()
	pose_motion.tween_property(model, "rotation:z", -0.18, 0.09)
	pose_motion.tween_property(model, "rotation:z", 0.0, 0.18).set_trans(Tween.TRANS_BACK)

func face(point: Vector3) -> void:
	var direction := point - global_position
	direction.y = 0
	if direction.length_squared() < 0.01: return
	var goal := atan2(direction.x, direction.z)
	if turn_motion != null and turn_motion.is_running(): turn_motion.kill()
	turn_motion = _paced_tween()
	turn_motion.tween_property(self, "rotation:y", rotation.y + wrapf(goal - rotation.y, -PI, PI), 0.12).set_trans(Tween.TRANS_SINE)

func set_aim_ready(value: bool, point: Vector3) -> void:
	if model == null or not alive or downed: return
	if value: face(point)
	if aim_ready == value: return
	aim_ready = value
	if pose_motion != null and pose_motion.is_running(): pose_motion.kill()
	pose_motion = _paced_tween().set_parallel(true)
	pose_motion.tween_property(model, "rotation:x", -0.16 if value else 0.0, 0.17)
	pose_motion.tween_property(model, "rotation:z", -0.08 if value and base_clip == "saberIdle" else 0.0, 0.17)

func travel(route: Array) -> void:
	travel24(route, false)

static func travel_speed24(dash: bool) -> float:
	return 5.6 if dash else 4.0

func travel24(path: Array, dash: bool, segments: Array = []) -> void:
	if motion != null and motion.is_running(): motion.kill()
	if path.is_empty() or not alive or downed: return
	_action_serial += 1
	motion = _paced_tween()
	play("run")
	var previous := position
	var step_index := 0
	for item in path:
		var point: Vector3 = item
		var flat: Vector3 = point - previous
		if flat.length_squared() < 0.001:
			step_index += 1
			continue
		var kind := "walk"
		if step_index < segments.size():
			var segment: Variant = segments[step_index]
			kind = str(segment.get("kind", segment.get("type", "walk"))) if segment is Dictionary else str(segment)
		var duration := maxf(0.08, flat.length() / travel_speed24(dash))
		motion.tween_callback(func() -> void: face(point))
		motion.tween_callback(func() -> void:
			if model != null: model.rotation.z = -0.16 if dash else 0.0)
		if kind in ["vault", "climb", "door"]:
			var rise := 0.55 if kind == "vault" else 0.38 if kind == "climb" else 0.16
			var middle := previous.lerp(point, 0.5) + Vector3.UP * rise
			motion.tween_property(self, "position", middle, duration * 0.5).set_trans(Tween.TRANS_SINE)
			motion.parallel().tween_callback(_footstep).set_delay(duration * 0.18)
			motion.tween_property(self, "position", point, duration * 0.5).set_trans(Tween.TRANS_SINE)
			motion.parallel().tween_callback(_footstep).set_delay(duration * 0.35)
		else:
			motion.tween_property(self, "position", point, duration).set_trans(Tween.TRANS_LINEAR)
			motion.parallel().tween_callback(_footstep).set_delay(duration * 0.22)
			if duration >= 0.17: motion.parallel().tween_callback(_footstep).set_delay(duration * 0.76)
		previous = point
		step_index += 1
	motion.tween_callback(func() -> void:
		if model != null: model.rotation.z = 0.0
		if alive: play(base_clip))

func fall() -> void:
	fall24(0, Vector3.ZERO)

static func choose_fall24(dir: Vector3) -> int:
	if absf(dir.x) > absf(dir.z) * 1.3: return 2
	return 1 if dir.z > 0.25 else 0

func fall24(variant: int, dir: Vector3) -> void:
	if not alive: return
	if variant < -1 or variant > 2: return
	if variant < 0: variant = choose_fall24(dir)
	alive = false
	set_saber_active(false)
	if ring != null: ring.hide()
	var selection_ring := get_node_or_null("GfxSelectionRing")
	if selection_ring != null: selection_ring.hide()
	if status_label != null: status_label.hide()
	if watch_eye != null: watch_eye.hide()
	_corpses.append(self)
	while _corpses.size() > CORPSE_CAP:
		var oldest: Node3D = _corpses.pop_front()
		if is_instance_valid(oldest): oldest.queue_free()
	_action_serial += 1
	if motion != null and motion.is_running(): motion.kill()
	if turn_motion != null and turn_motion.is_running(): turn_motion.kill()
	if pose_motion != null and pose_motion.is_running(): pose_motion.kill()
	play("death")
	var tween := _paced_tween().set_parallel(true)
	match variant:
		0: # Stumble backward, then hold the body.
			tween.tween_property(model, "rotation:z", 1.5, FALL_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.tween_property(model, "position:y", -0.28, FALL_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.tween_property(model, "position:x", -0.24, FALL_SECONDS * 0.55)
		1: # Drop to a knee before tipping forward.
			tween.tween_property(model, "rotation:x", -1.15, FALL_SECONDS).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(model, "rotation:z", 0.4, FALL_SECONDS)
			tween.tween_property(model, "position:y", -0.53, FALL_SECONDS * 0.7)
		2: # Side impact spins the torso into the fall.
			tween.tween_property(model, "rotation:y", PI * (-1.0 if dir.x < 0.0 else 1.0), FALL_SECONDS)
			tween.tween_property(model, "rotation:z", 1.45, FALL_SECONDS).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(model, "position:y", -0.3, FALL_SECONDS)
	tween.chain().tween_interval(CORPSE_LIFETIME)
	tween.chain().tween_callback(queue_free)
	var game := get_parent().get_parent() if get_parent() != null else null
	if game != null and game.get("fx") is Node3D and get_parent() == game.get("figures"):
		reparent(game.fx, true)

func _dust() -> void:
	footfalls += 1
	var puff := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.22; mesh.bottom_radius = 0.3; mesh.height = 0.025
	puff.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.65, 0.61, 0.53, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff.material_override = mat
	puff.position = Vector3(0, 0.04, 0)
	add_child(puff)
	var tween := _paced_tween().set_parallel(true)
	tween.tween_property(puff, "scale", Vector3(2.0, 1.0, 2.0), 0.28)
	tween.tween_property(puff, "transparency", 1.0, 0.28)
	tween.chain().tween_callback(puff.queue_free)

func _footstep() -> void:
	if foot != null:
		var game := get_parent().get_parent() if get_parent() != null else null
		var sound: Node = game.get("sound") if game != null else null
		if sound != null:
			foot.volume_linear = 0.0 if bool(sound.get("muted")) else float(sound.get("volume")) * 0.11
		for i in range(_active_feet24.size() - 1, -1, -1):
			if not is_instance_valid(_active_feet24[i]) or not _active_feet24[i].playing: _active_feet24.remove_at(i)
		if _active_feet24.size() < 2:
			foot.stop()
			foot.play()
			if not _active_feet24.has(foot): _active_feet24.append(foot)
	_dust()

var status_label: Label3D
var watch_eye: Sprite3D
static var watch_eye_texture: Texture2D

static func eye_texture() -> Texture2D:
	if watch_eye_texture != null: return watch_eye_texture
	var image := Image.create(32,20,false,Image.FORMAT_RGBA8)
	for y in 20:
		for x in 32:
			var dx := absf((float(x)-15.5)/15.5)
			var dy := absf((float(y)-9.5)/9.5)
			var outline := absf(dy - (1.0-dx*dx)*0.7) < 0.13
			var pupil := Vector2(float(x)-15.5,float(y)-9.5).length() < 3.8
			if outline or pupil: image.set_pixel(x,y,Color("9beaff"))
	watch_eye_texture = ImageTexture.create_from_image(image)
	return watch_eye_texture

func set_status(u: Dictionary) -> void:
	if watch_eye == null:
		watch_eye = Sprite3D.new(); watch_eye.texture = eye_texture(); watch_eye.pixel_size = 0.025
		watch_eye.billboard = BaseMaterial3D.BILLBOARD_ENABLED; watch_eye.no_depth_test = true
		watch_eye.position.y = 2.35; add_child(watch_eye)
	watch_eye.visible = bool(u.get("overwatch",false))
	if status_label == null:
		status_label = Label3D.new(); status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		status_label.position.y = 2.0; status_label.font_size = 15; status_label.pixel_size = 0.0012; status_label.fixed_size = true
		status_label.outline_size = 4; add_child(status_label)
	var badges: Array[String] = []
	for pair in [["concealed", "HIDDEN"], ["overwatch", "WATCH"], ["hunkered", "HUNKER"], ["stunned", "STUN"], ["disarmed", "DISARM"], ["rooted", "BOUND"], ["suppressed", "PINNED"], ["marked", "MARKED"], ["tricked", "TRICKED"]]:
		if bool(u.get(pair[0], false)): badges.append(pair[1])
	status_label.text = "%s\nHP %d/%d  %s" % [u.name,u.hp,u.max_hp," · ".join(badges)]
	if preload("res://scripts/campaign/strat_preferences.gd").get_value("numbers"): status_label.text += "  AP %d · ARM %d" % [u.ap,u.get("armor",0)]
	status_label.modulate = (Color("f9bf60") if str(u.side) == "enemy" else Color("73d8ff")) if preload("res://scripts/campaign/strat_preferences.gd").get_value("cb") else (Color("ffb09e") if str(u.side) == "enemy" else Color("b8edff"))

func _paced_tween() -> Tween:
	return create_tween().set_speed_scale(float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed")) * (RescueSettings.enemy_speed() if enemy_side else 1.0))
