extends Node3D

const Audio = preload("res://scripts/audio.gd")
var unit_id: int
var model: Node3D
var animation: AnimationPlayer
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
	model = scene.instantiate()
	model.scale = Vector3.ONE * 1.2
	add_child(model)
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
	var blade_mesh := CylinderMesh.new()
	blade_mesh.top_radius = 0.014; blade_mesh.bottom_radius = 0.022; blade_mesh.height = 1.02
	blade.mesh = blade_mesh; blade.position.y = 0.62
	var color := Color(str(u.get("col", "#79d3e2")))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = color; glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.emission_enabled = true; glow.emission = color; glow.emission_energy_multiplier = 2.0
	blade.material_override = glow; grip.add_child(blade)

func play(clip: String) -> void:
	if animation == null: return
	animation.speed_scale = float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed")) * (RescueSettings.enemy_speed() if enemy_side else 1.0)
	var name := clip if animation.has_animation(clip) else base_clip if animation.has_animation(base_clip) else "idle"
	if animation.has_animation(name) and animation.current_animation != name:
		animation.play(name, 0.14 if clip == "run" else 0.1)

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

func set_status(u: Dictionary) -> void:
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
