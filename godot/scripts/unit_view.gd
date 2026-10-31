extends Node3D

var unit_id: int
var model: Node3D
var animation: AnimationPlayer
var base_clip := "idle"
var motion: Tween
var alive := true
var ring: MeshInstance3D

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

func _find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := _find_animation(child)
		if found != null: return found
	return null

func play(clip: String) -> void:
	if animation == null: return
	var name := clip
	if not animation.has_animation(name):
		name = "idle"
	if animation.current_animation != name: animation.play(name, 0.12)

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

func act(clip: String) -> void:
	play(clip)
	if animation != null:
		var duration := animation.current_animation_length
		get_tree().create_timer(maxf(0.15, duration - 0.08)).timeout.connect(func() -> void:
			if is_instance_valid(self) and alive and animation.current_animation == clip: play(base_clip))

func face(point: Vector3) -> void:
	var direction := point - position
	direction.y = 0
	if direction.length_squared() > 0.01: rotation.y = atan2(direction.x, direction.z)

func travel(route: Array) -> void:
	if motion != null and motion.is_running(): motion.kill()
	if route.is_empty(): return
	motion = create_tween()
	play("run")
	var previous := position
	for item in route:
		var point: Vector3 = item
		var flat: Vector3 = point - previous
		if flat.length_squared() < 0.001: continue
		motion.tween_callback(func() -> void: face(point))
		motion.tween_property(self, "position", point, maxf(0.08, flat.length() / 4.0))
		previous = point
	motion.tween_callback(func() -> void: if alive: play(base_clip))

func fall() -> void:
	alive = false
	if motion != null and motion.is_running(): motion.kill()
	play("death")
	var tween := create_tween()
	tween.tween_interval(0.85)
	tween.tween_property(self, "scale", Vector3(0.7, 0.08, 0.7), 0.5)
	tween.tween_callback(queue_free)
