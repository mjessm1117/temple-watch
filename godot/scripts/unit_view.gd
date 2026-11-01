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

func setup(u: Dictionary, scene: PackedScene, at: Vector3) -> void:
	unit_id = int(u.id)
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

func play(clip: String) -> void:
	if animation == null: return
	var name := clip if animation.has_animation(clip) else base_clip if animation.has_animation(base_clip) else "idle"
	if animation.has_animation(name) and animation.current_animation != name:
		animation.play(name, 0.14 if clip == "run" else 0.1)

func set_selected(value: bool, enemy: bool) -> void:
	if ring == null: return
	var color := Color("f7d381") if value else Color("f17065") if enemy else Color("5cc9e8")
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
	var tween := create_tween()
	tween.tween_property(model, "position:y", target_y, 0.16)

func set_downed(value: bool) -> void:
	if value == downed or not alive or model == null: return
	downed = value
	if pose_motion != null and pose_motion.is_running(): pose_motion.kill()
	pose_motion = create_tween().set_parallel(true)
	pose_motion.tween_property(model, "rotation:z", 1.35 if value else 0.0, 0.35)
	pose_motion.tween_property(model, "position:y", -0.48 if value else 0.0, 0.35)
	if value: play("death")
	else: play(base_clip)

func stagger_to(point: Vector3) -> void:
	if not alive: return
	act("hit")
	if motion != null and motion.is_running(): motion.kill()
	motion = create_tween()
	motion.tween_property(self, "position", point, 0.27).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func act(clip: String) -> void:
	if not alive or downed: return
	_action_serial += 1
	var serial := _action_serial
	if pose_motion != null and pose_motion.is_running(): pose_motion.kill()
	if clip == "hit":
		play("hit")
		pose_motion = create_tween()
		pose_motion.tween_property(model, "rotation:z", 0.16, 0.07)
		pose_motion.tween_property(model, "rotation:z", 0.0, 0.22).set_trans(Tween.TRANS_BACK)
	else:
		var delay := 0.12 if turn_motion != null and turn_motion.is_running() else 0.0
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if not is_instance_valid(self) or not alive or serial != _action_serial: return
			play(clip)
			pose_motion = create_tween()
			pose_motion.tween_property(model, "rotation:x", -0.11 if clip == "shoot" else -0.2, 0.09)
			pose_motion.tween_property(model, "rotation:x", 0.0, 0.24))
	get_tree().create_timer(0.52).timeout.connect(func() -> void:
		if is_instance_valid(self) and alive and serial == _action_serial: play(base_clip))

func face(point: Vector3) -> void:
	var direction := point - global_position
	direction.y = 0
	if direction.length_squared() < 0.01: return
	var goal := atan2(direction.x, direction.z)
	if turn_motion != null and turn_motion.is_running(): turn_motion.kill()
	turn_motion = create_tween()
	turn_motion.tween_property(self, "rotation:y", rotation.y + wrapf(goal - rotation.y, -PI, PI), 0.12).set_trans(Tween.TRANS_SINE)

func travel(route: Array) -> void:
	if motion != null and motion.is_running(): motion.kill()
	if route.is_empty() or not alive or downed: return
	_action_serial += 1
	motion = create_tween()
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
	var tween := create_tween().set_parallel(true)
	tween.tween_property(model, "rotation:z", 1.35, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(model, "position:y", -0.48, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.chain().tween_interval(0.45)
	tween.chain().tween_property(self, "scale", Vector3.ZERO, 0.22)
	tween.chain().tween_callback(queue_free)

var status_label: Label3D

func set_status(u: Dictionary) -> void:
	if status_label == null:
		status_label = Label3D.new(); status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		status_label.position.y = 2.0; status_label.font_size = 18; status_label.pixel_size = 0.0012; status_label.fixed_size = true
		status_label.outline_size = 4; add_child(status_label)
	var badges: Array[String] = []
	for pair in [["concealed", "HIDDEN"], ["overwatch", "WATCH"], ["hunkered", "HUNKER"], ["stunned", "STUN"], ["disarmed", "DISARM"], ["rooted", "BOUND"], ["suppressed", "PINNED"], ["marked", "MARKED"], ["tricked", "TRICKED"]]:
		if bool(u.get(pair[0], false)): badges.append(pair[1])
	status_label.text = "%s\n%s%s  %s" % [str(u.name), "●".repeat(clampi(int(u.hp), 0, 10)) + (" %d/%d" % [int(u.hp), int(u.max_hp)] if int(u.max_hp) > 10 else ""), "  ⬟%d" % int(u.get("armor", 0)) if int(u.get("armor", 0)) > 0 else "", " · ".join(badges)]
	status_label.modulate = Color("ffb09e") if str(u.side) == "enemy" else Color("b8edff")
