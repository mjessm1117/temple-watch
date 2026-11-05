extends Node3D
const Actor = preload("res://scripts/campaign/loadout_actor.gd")
var actors: Array = []
var camera: Camera3D
var focused := -1
var time := 0.0
var home := Vector3(0, 1.8, 4.9)
var gaze := Vector3(0, 1.06, 0)
var dust: MultiMeshInstance3D
var dust_points: Array[Vector3] = []

func _ready() -> void:
	var world := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color("0b171e")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9dbdc9"); env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true; env.glow_intensity = 0.7
	env.fog_enabled = true; env.fog_light_color = Color("355867"); env.fog_density = 0.012
	world.environment = env; add_child(world)
	camera = Camera3D.new(); camera.fov = 30; camera.position = home; add_child(camera); camera.look_at(gaze)
	var key := DirectionalLight3D.new(); key.rotation_degrees = Vector3(-38, -30, 0)
	key.light_color = Color("d3e6ee"); key.light_energy = 1.1; key.shadow_enabled = true; add_child(key)
	# Showroom lighting is limited to Forward+; Compatibility keeps its existing light count.
	if get_node("/root/Graphics").effective != "low":
		var warm := SpotLight3D.new(); warm.name = "ShowroomKey"
		warm.position = Vector3(-1.8, 3.9, 2.2); add_child(warm); warm.look_at(Vector3(0, 1.0, 0))
		warm.light_color = Color("f7dcad"); warm.light_energy = 3.2
		warm.spot_range = 7; warm.spot_angle = 38
		var rim := SpotLight3D.new(); rim.name = "ShowroomRim"
		rim.position = Vector3(1.7, 2.8, -2.0); add_child(rim); rim.look_at(Vector3(0, 1.1, 0))
		rim.light_color = Color("6ecce9"); rim.light_energy = 4.0
		rim.spot_range = 6; rim.spot_angle = 42
		var glow := MeshInstance3D.new(); glow.name = "ShowroomFloorGlow"
		var disc := CylinderMesh.new(); disc.top_radius = 1.05; disc.bottom_radius = 1.05
		disc.height = 0.012; disc.radial_segments = 32; glow.mesh = disc
		glow.position = Vector3(0, -0.008, 0)
		var glow_mat := StandardMaterial3D.new()
		glow_mat.albedo_color = Color(0.11, 0.51, 0.67, 0.24)
		glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow_mat.emission_enabled = true; glow_mat.emission = Color("58b7d5")
		glow_mat.emission_energy_multiplier = 1.0
		glow.material_override = glow_mat; add_child(glow)
	Actor.block(self, Vector3(0, -0.15, 0), Vector3(38, 0.25, 25), Color("18272e"))
	# Temple ribs, recessed hangar door and an illuminated clerestory.
	Actor.block(self, Vector3(0, 3.5, -4.7), Vector3(32, 8, 0.6), Color("111f29"))
	Actor.block(self, Vector3(0, 2.6, -4.33), Vector3(8, 4.8, 0.12), Color("09141c"))
	for side in [-1, 1]:
		for x in [4.3, 7.7, 11.1]:
			Actor.block(self, Vector3(side * x, 2.6, -3.8), Vector3(0.55, 5.5, 1.1), Color("24333e"))
			Actor.block(self, Vector3(side * (x - 0.3), 2.65, -3.2), Vector3(0.035, 4.5, 0.05), Color("75b7c9"), 2.0)
		Actor.block(self, Vector3(side * 4.0, 2.7, -4.1), Vector3(0.08, 5, 0.07), Color("93d5dc"), 3.0)
	Actor.block(self, Vector3(0, 5.0, -3.8), Vector3(8.5, 0.45, 1.1), Color("4b5f68"))
	for x in range(-9, 10, 3):
		Actor.block(self, Vector3(x, 0.005, -0.6), Vector3(0.025, 0.02, 9), Color("4c6d79"))
		Actor.block(self, Vector3(x, 4.2, -2), Vector3(1.2, 0.06, 0.2), Color("a8cde1"), 3.0)
		var lamp := SpotLight3D.new(); lamp.position = Vector3(x, 4.0, 1.2)
		lamp.rotation_degrees.x = -65; lamp.light_color = Color("9ed8f2"); lamp.light_energy = 1.5
		lamp.spot_range = 10; lamp.spot_angle = 28; add_child(lamp)
		# Subtle luminous shafts; particles travel through them.
		var shaft := Actor.block(self, Vector3(x, 2.2, -1.1), Vector3(0.7, 4.1, 0.035), Color("73bad4"))
		var mat := Actor.material(Color(0.4, 0.7, 0.9, 0.035), 0.3)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shaft.material_override = mat; shaft.rotation.z = -0.13
	for z in [-3.0, 1.0, 3.0]:
		Actor.block(self, Vector3(0, 0.012, z), Vector3(28, 0.02, 0.025), Color("3a5a67"))
	var emblem := Label3D.new(); emblem.text = "J E D I   T E M P L E\nH A N G A R   0 7"
	emblem.position = Vector3(0, 2.75, -4.15); emblem.font_size = 54; emblem.pixel_size = 0.006
	emblem.modulate = Color("73939e"); add_child(emblem)
	_make_dust()

func show_squad(roster: Array) -> void:
	for actor in actors: remove_child(actor); actor.queue_free()
	actors.clear()
	for r in roster:
		var actor := Actor.new(); add_child(actor); actor.setup(r); actors.append(actor)
	_layout_actors()

func _layout_actors() -> void:
	if camera == null: return
	var viewport_size := get_viewport().get_visible_rect().size
	var span := 2.0 * home.z * tan(deg_to_rad(camera.fov * 0.5)) * viewport_size.x / maxf(1, viewport_size.y)
	for i in actors.size():
		actors[i].visible = focused < 0 or i == focused
		actors[i].position.x = 0.0 if focused >= 0 else (float(i) - (actors.size() - 1) * 0.5) * span / maxf(1, actors.size())

func focus_slot(index: int) -> void:
	focused = index
	_layout_actors()
	for i in actors.size(): actors[i].highlighted = i == focused

func highlight(index: int) -> void:
	for i in actors.size(): actors[i].highlighted = i == index or i == focused

func _make_dust() -> void:
	dust = MultiMeshInstance3D.new(); var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = SphereMesh.new()
	mm.mesh.radius = 0.008; mm.mesh.height = 0.016; mm.mesh.radial_segments = 4; mm.mesh.rings = 2
	mm.instance_count = 120; dust.multimesh = mm; dust.material_override = Actor.material(Color("98b6bf"), 0.7); add_child(dust)
	var rng := RandomNumberGenerator.new(); rng.seed = 71
	for i in mm.instance_count: dust_points.append(Vector3(rng.randf_range(-10, 10), rng.randf_range(0, 5), rng.randf_range(-3, 3)))

func _process(delta: float) -> void:
	if preload("res://scripts/campaign/strat_preferences.gd").get_value("motion"): delta = 0.0
	time += delta
	_layout_actors()
	var target := home
	var look := gaze
	if focused >= 0 and focused < actors.size():
		look = Vector3(0, 1.2, 0)
		target = look + Vector3(0.0, 0.25, 5.5 if get_viewport().get_visible_rect().size.x < 250.0 else 3.1)
	target += Vector3(sin(time * 0.18) * 0.06, sin(time * 0.23) * 0.025, cos(time * 0.16) * 0.04)
	camera.position = camera.position.lerp(target, 1.0 - exp(-delta * 4.0))
	gaze = gaze.lerp(look if focused >= 0 else Vector3(0, 1.06, 0), 1.0 - exp(-delta * 4.0))
	camera.look_at(gaze)
	for i in dust_points.size():
		var p := dust_points[i]; p.y = fmod(p.y + time * 0.045, 5.0); p.x += sin(time * 0.3 + i) * 0.12
		dust.multimesh.set_instance_transform(i, Transform3D(Basis(), p))
