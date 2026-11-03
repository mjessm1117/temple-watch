extends Node3D

const Audio = preload("res://scripts/audio.gd")
var view_camera: Camera3D
var overlay: Control
var _scorches: Array[Node3D] = []
var float_anchors: Array[Dictionary] = []
var _hit_stop_serial := 0
var _time_scale_before := 1.0

func hit_stop(seconds := 0.055) -> void:
	if _hit_stop_serial == 0: _time_scale_before = Engine.time_scale
	_hit_stop_serial += 1
	var serial := _hit_stop_serial
	Engine.time_scale = 0.12
	get_tree().create_timer(minf(seconds, 0.08), true, false, true).timeout.connect(func() -> void:
		if serial == _hit_stop_serial:
			Engine.time_scale = _time_scale_before
			_hit_stop_serial = 0)

func _exit_tree() -> void:
	if _hit_stop_serial != 0: Engine.time_scale = _time_scale_before

func _cue(kind: String) -> void:
	var synth := Audio.new()
	var stream := synth._synthesize(kind)
	synth.free()
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	voice.volume_db = -20.0
	add_child(voice)
	voice.play()
	voice.finished.connect(voice.queue_free)

func setup(cam: Camera3D, ui: Control) -> void:
	view_camera = cam
	overlay = ui

func _tier() -> String:
	var graphics := get_node_or_null("/root/Graphics")
	return str(graphics.effective) if graphics else "high"

func _material(color: Color, glow := true) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.4
	return material

func _sphere(at: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius; mesh.height = radius * 2
	var node := MeshInstance3D.new()
	node.mesh = mesh; node.material_override = _material(color)
	node.position = at; add_child(node)
	return node

func _flash(at: Vector3, color: Color, energy: float, duration: float) -> void:
	if _tier() == "low": return
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 2.5
	light.shadow_enabled = false
	light.position = at
	add_child(light)
	var tween := _paced_tween()
	tween.tween_property(light, "light_energy", 0.0, duration)
	tween.tween_callback(light.queue_free)

func burst(at: Vector3, color: Color, count := 8) -> void:
	count = mini(count,4 if _tier() == "low" else 8 if _tier() == "medium" else count)
	var rng := RandomNumberGenerator.new(); rng.randomize()
	for i in range(count):
		var spark := _sphere(at, 0.025 if i % 3 else 0.04, color)
		var vector := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.15, 1.1), rng.randf_range(-1, 1))
		var tween := _paced_tween().set_parallel(true)
		tween.tween_property(spark, "position", at + vector * 0.65, 0.24)
		tween.tween_property(spark, "scale", Vector3.ZERO, 0.24)
		tween.chain().tween_callback(spark.queue_free)

func _scorch(at: Vector3) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.19; mesh.bottom_radius = 0.19; mesh.height = 0.007
	var decal := MeshInstance3D.new()
	decal.mesh = mesh
	decal.material_override = _material(Color("25201e"), false)
	decal.position = Vector3(at.x, maxf(0.018, at.y - 1.08), at.z)
	decal.set_meta("born_turn",_battle_turn())
	add_child(decal)
	_scorches.append(decal)
	if _scorches.size() > (12 if _tier() == "low" else 24):
		_scorches.pop_front().queue_free()

func _battle_turn() -> int:
	var game := get_parent()
	return int(game.mission.turn) if game != null and game.has_method("_build_terrain") and game.mission != null else 0

func bolt(from: Vector3, to: Vector3, enemy: bool, miss: bool) -> void:
	var color := Color("ff5364") if enemy else Color("70dfff")
	var direction := (to - from).normalized()
	var end := to + direction * 1.4 if miss else to
	if miss: _cue("whiz")
	_flash(from, color, 2.0, 0.09)
	burst(from, color, 4)
	var core := _sphere(from, 0.075, Color.WHITE)
	core.scale = Vector3(0.8, 0.8, 4.5)
	core.look_at(end, Vector3.UP)
	var glow := _sphere(from, 0.15, color)
	glow.scale = Vector3(0.6, 0.6, 3.0)
	glow.look_at(end, Vector3.UP)
	var beam_mesh := CylinderMesh.new(); beam_mesh.top_radius = 0.018; beam_mesh.bottom_radius = 0.018; beam_mesh.height = from.distance_to(end)
	var beam := MeshInstance3D.new(); beam.mesh = beam_mesh; beam.material_override = _material(color)
	beam.position = (from + end) * 0.5
	beam.quaternion = Quaternion(Vector3.UP, direction)
	add_child(beam)
	var beam_fade := _paced_tween()
	beam_fade.tween_interval(0.08)
	beam_fade.tween_property(beam, "scale", Vector3.ZERO, 0.13)
	beam_fade.tween_callback(beam.queue_free)
	if overlay != null and view_camera != null:
		var streak := Line2D.new()
		streak.points = PackedVector2Array([view_camera.unproject_position(from), view_camera.unproject_position(end)])
		streak.width = 3.0; streak.default_color = color
		overlay.add_child(streak)
		var fade := _paced_tween()
		fade.tween_property(streak, "modulate:a", 0.0, 0.18).set_delay(0.04)
		fade.tween_callback(streak.queue_free)
	var duration := clampf(from.distance_to(end) / 38.0, 0.11, 0.31)
	var tween := _paced_tween().set_parallel(true)
	tween.tween_property(core, "position", end, duration)
	tween.tween_property(glow, "position", end, duration)
	tween.chain().tween_callback(func() -> void:
		_flash(end, Color("ffd7a4"), 0.9, 0.1)
		burst(end, Color("e8c896") if miss else color, 10)
		_scorch(end)
		core.queue_free(); glow.queue_free())

func shockwave(from: Vector3, to: Vector3) -> void:
	var wave := _sphere(from, 0.22, Color("8beafa"))
	wave.scale = Vector3(1.0, 0.25, 1.0)
	_flash(from, Color("8beafa"), 1.1, 0.16)
	var tween := _paced_tween().set_parallel(true)
	tween.tween_property(wave, "position", to, 0.28)
	tween.tween_property(wave, "scale", Vector3(6, 0.12, 6), 0.36)
	tween.chain().tween_callback(func() -> void:
		burst(to, Color("9cefff"), 12)
		ring(to - Vector3.UP * 0.8, Color("a1eeff"), 1.6)
		if _tier() == "high": ring(to - Vector3.UP * 0.78, Color("c7f6ff"), 2.4)
		cover_chunks(to)
		wave.queue_free())

func saber(from: Vector3, to: Vector3) -> void:
	_cue("ignite")
	var mid := (from + to) * 0.5 + Vector3.UP * 0.45
	var ribbon := _saber_ribbon(from,to)
	var trail := _sphere(mid, 0.13, Color("80eaff"))
	trail.scale = Vector3(0.8, 0.8, 4.5)
	trail.look_at(to, Vector3.UP)
	_flash(mid, Color("80eaff"), 1.0, 0.18)
	var tween := _paced_tween()
	tween.tween_property(trail, "position", to, 0.15)
	tween.tween_property(trail, "scale", Vector3.ZERO, 0.1)
	tween.tween_callback(trail.queue_free)
	var ribbon_fade := _paced_tween()
	ribbon_fade.tween_property(ribbon,"transparency",1.0,0.24)
	ribbon_fade.tween_callback(ribbon.queue_free)
	burst(to, Color("f1fbff"), 12)
	get_tree().create_timer(0.14/float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed"))).timeout.connect(func() -> void:
		if is_instance_valid(self): _cue("clash"))

func _saber_ribbon(from: Vector3, to: Vector3) -> MeshInstance3D:
	var steps := 4 if _tier() == "low" else 10
	var across := (to-from).cross(Vector3.UP).normalized()
	if across.length_squared() < 0.01: across = Vector3.RIGHT
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in steps:
		var a := float(i)/steps
		var b := float(i+1)/steps
		var pa := from.lerp(to,a)+Vector3.UP*(sin(a*PI)*0.7)
		var pb := from.lerp(to,b)+Vector3.UP*(sin(b*PI)*0.7)
		var wa := 0.26*(1.0-a)+0.03
		var wb := 0.26*(1.0-b)+0.03
		for point in [pa-across*wa,pa+across*wa,pb+across*wb,pa-across*wa,pb+across*wb,pb-across*wb]: surface.add_vertex(point)
	var ribbon := MeshInstance3D.new()
	ribbon.mesh = surface.commit()
	var mat := _material(Color("6deaff"))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ribbon.material_override = mat
	add_child(ribbon)
	return ribbon

func cover_chunks(at: Vector3) -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	for i in (3 if _tier() == "low" else 5 if _tier() == "medium" else 8):
		var mesh := BoxMesh.new(); mesh.size = Vector3(0.14, 0.1, 0.14)
		var chunk := MeshInstance3D.new(); chunk.mesh = mesh
		chunk.material_override = _material(Color("9a9d98"), false)
		chunk.position = at; add_child(chunk)
		var offset := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.2, 1), rng.randf_range(-1, 1))
		var tween := _paced_tween().set_parallel(true)
		tween.tween_property(chunk, "position", at + offset, 0.36)
		tween.tween_property(chunk, "scale", Vector3.ZERO, 0.36).set_delay(0.1)
		tween.chain().tween_callback(chunk.queue_free)

func float_text(at: Vector3, value: String, color: Color, large := false) -> void:
	if overlay == null or view_camera == null: return
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 31 if large else 23)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	overlay.add_child(label)
	label.position = view_camera.unproject_position(at) - Vector2(35, 18)
	var tween := _paced_tween().set_parallel(true)
	float_anchors.append({"label":label, "at":at, "age":0.0})
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)

func heal(at: Vector3, amount: int) -> void:
	var color := Color("60ed97")
	_flash(at, color, 1.8, 0.42)
	burst(at, color, 14)
	float_text(at + Vector3.UP * 0.7, "+%d HP" % amount if amount > 0 else "PROTECTED", color, true)

func ring(at: Vector3, color: Color, radius: float = 1.0) -> void:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new(); mesh.inner_radius = 0.88; mesh.outer_radius = 1.0
	node.mesh = mesh; node.material_override = _material(color); node.position = at
	node.scale = Vector3.ONE * 0.12; add_child(node)
	var tween := _paced_tween().set_parallel(true)
	tween.tween_property(node, "scale", Vector3(radius, 0.15, radius), 0.5)
	tween.tween_property(node, "transparency", 1.0, 0.5)
	tween.chain().tween_callback(node.queue_free)

func ability(id: String, from: Vector3, to: Vector3) -> void:
	# The web's blue telekinesis / gold mind / green life / violet stasis vocabulary.
	if id == "pull": shockwave(to, from)
	elif id in ["push", "forceWave"]: shockwave(from, to); ring(from - Vector3.UP * 0.8, Color("9fe7ff"), 2.8)
	elif id in ["stun", "mindTrick", "beastCalm"]:
		ring(to + Vector3.UP * 0.5, Color("e0bd78"), 0.65); burst(to, Color("ffe7a0"), 18)
	elif id in ["forceHeal", "massHeal", "medBeacon", "forceRevive", "heal", "medpac", "revive", "reviveStim"]:
		for i in range(3): ring(to + Vector3.UP * (i * 0.35 - 0.7), Color("7fd99a"), 0.7 + i * 0.2)
		_flash(to, Color("7fd99a"), 2.0, 0.5)
	elif id in ["stasisField", "choke", "shadowStep", "root"]:
		for i in range(4): ring(to + Vector3.UP * (i * 0.4 - 0.7), Color("b294f5"), 0.6)
		burst(to, Color("b294f5"), 22)
	elif id in ["barrier", "shieldDrone", "shieldWall", "guard"]:
		var dome := _sphere(to, 0.85, Color("7fd99a")); dome.transparency = 0.65
		var tween := _paced_tween(); tween.tween_property(dome, "transparency", 1.0, 0.85); tween.tween_callback(dome.queue_free)
	elif id in ["grenade", "ionNade", "barrage", "moStrike", "tremor", "collapse"]:
		burst(to, Color("b294f5") if id == "ionNade" else Color("ffb050"), 32)
		ring(to - Vector3.UP * 0.8, Color("ffb050"), 1.8)
		if id != "ionNade": cover_chunks(to); _scorch(to)
	elif id in ["breach", "saberThrow", "flurry", "mightyBlow", "precisionStrike", "sweep"]: saber(from, to)
	elif id in ["battleMed", "meditate", "bondAid", "bondStrike", "handoff", "moRally", "moSurge"]:
		ring(from - Vector3.UP * 0.8, Color("79d3e2"), 2.2); ring(to - Vector3.UP * 0.8, Color("79d3e2"), 1.0)
	elif id in ["rapidFire", "deadeye", "chainShot", "snipe", "fanFire", "coverFire", "suppress", "backup"]: bolt(from, to, false, false)
	else: ring(to, Color("79d3e2"), 0.7)

func _process(delta: float) -> void:
	var current_turn := _battle_turn()
	for i in range(_scorches.size()-1,-1,-1):
		var mark := _scorches[i]
		if not is_instance_valid(mark): _scorches.remove_at(i); continue
		var age := current_turn-int(mark.get_meta("born_turn",current_turn))
		if age >= 3:
			mark.queue_free(); _scorches.remove_at(i)
		else:
			mark.transparency = clampf(float(age)/3.0,0.0,0.9)
	for i in range(float_anchors.size()-1,-1,-1):
		var entry: Dictionary = float_anchors[i]
		if not is_instance_valid(entry.label): float_anchors.remove_at(i); continue
		if view_camera == null: continue
		entry.age = float(entry.age) + delta
		entry.label.visible = not view_camera.is_position_behind(entry.at)
		entry.label.position = view_camera.unproject_position(entry.at) - Vector2(35,18 + float(entry.age)*70)

func _paced_tween() -> Tween:
	return create_tween().set_speed_scale(float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed")))
