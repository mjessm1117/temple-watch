extends Node3D

const Audio = preload("res://scripts/audio.gd")
const W17_ROOT := "res://assets/units/w17/"
const W17_KINDS := ["sniper", "heavy", "tech", "droid", "officer"]
var unit_id: int
var model: Node3D
var animation: AnimationPlayer
var lod_animation: AnimationPlayer
var base_clip := "idle"
var motion: Tween
var turn_motion: Tween
var pose_motion: Tween
var alive := true
var ring: MeshInstance3D
var foot: AudioStreamPlayer
var _step_stream: AudioStreamWAV
var _action_serial := 0
var _cover_level := 0
var downed := false
var enemy_side := false
var aim_ready := false

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
	synth.free()
	foot.stream = _step_stream
	add_child(foot)

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
	# Imported armature carries a 0.01 scale; restore world-sized equipment.
	grip.scale = Vector3.ONE * 80.0
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
	var blade_mesh := CapsuleMesh.new()
	blade_mesh.radius = 0.038; blade_mesh.height = 1.06; blade_mesh.radial_segments = 8; blade_mesh.rings = 4
	blade.mesh = blade_mesh; blade.position.y = 0.62
	var color := Color(str(u.get("col", "#79d3e2")))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = color; glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.emission_enabled = true; glow.emission = color; glow.emission_energy_multiplier = 2.6
	blade.material_override = glow; grip.add_child(blade)

func play(clip: String) -> void:
	if animation == null: return
	animation.speed_scale = float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed")) * (RescueSettings.enemy_speed() if enemy_side else 1.0)
	if lod_animation != null: lod_animation.speed_scale = animation.speed_scale
	var name := clip if animation.has_animation(clip) else base_clip if animation.has_animation(base_clip) else "idle"
	if animation.has_animation(name) and animation.current_animation != name:
		animation.play(name, 0.14 if clip == "run" else 0.1)
	if lod_animation != null and lod_animation.has_animation(name) and lod_animation.current_animation != name:
		lod_animation.play(name, 0.14 if clip == "run" else 0.1)

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
		pose_motion.tween_property(model, "rotation:z", 0.16, 0.07)
		pose_motion.tween_property(model, "rotation:z", 0.0, 0.22).set_trans(Tween.TRANS_BACK)
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
	if motion != null and motion.is_running(): motion.kill()
	if route.is_empty() or not alive or downed: return
	_action_serial += 1
	motion = _paced_tween()
	play("run")
	var previous := position
	for item in route:
		var point: Vector3 = item
		var flat: Vector3 = point - previous
		if flat.length_squared() < 0.001: continue
		motion.tween_callback(func() -> void: face(point))
		motion.tween_property(self, "position", point, maxf(0.08, flat.length() / 4.0)).set_trans(Tween.TRANS_SINE)
		motion.parallel().tween_callback(func() -> void:
			if foot != null and not foot.playing: foot.play()).set_delay(0.07)
		previous = point
	motion.tween_callback(func() -> void: if alive: play(base_clip))

func fall() -> void:
	if not alive: return
	alive = false
	_action_serial += 1
	if motion != null and motion.is_running(): motion.kill()
	if turn_motion != null and turn_motion.is_running(): turn_motion.kill()
	if pose_motion != null and pose_motion.is_running(): pose_motion.kill()
	play("death")
	var tween := _paced_tween().set_parallel(true)
	tween.tween_property(model, "rotation:z", 1.35, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(model, "position:y", -0.48, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.chain().tween_interval(0.45)
	tween.chain().tween_property(self, "scale", Vector3.ZERO, 0.22)
	tween.chain().tween_callback(queue_free)

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
