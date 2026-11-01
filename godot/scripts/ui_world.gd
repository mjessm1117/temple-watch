extends SubViewportContainer
## Living miniature stages. All scenery is native geometry; portraits reuse the unit asset.
var stage := "temple"
var planet_key := "coruscant"
var facing := 1.0
var unit_kind := "jedi"
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var moving: Array[Node3D] = []
var globe: Node3D
var actor: Node3D
var time := 0.0
var base_camera := Vector3.ZERO

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	stretch = true
	viewport = SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0a151c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("96bdca")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	environment.environment = env
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35,-35,0)
	sun.light_color = Color("ffcd9b")
	sun.light_energy = 1.8
	world.add_child(sun)
	camera = Camera3D.new()
	camera.current = true
	world.add_child(camera)
	match stage:
		"portrait": _portrait()
		"holo": _holo()
		"archive": _archive()
		_: _temple(env)
	_batch_boxes()
	base_camera = camera.position

func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.75
	if glow > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m

func box(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	return shape(parent,mesh,at,material(color,glow))

func shape(parent: Node3D, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = at
	parent.add_child(instance)
	return instance

func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.08
	mesh.height = height
	shape(parent,mesh,at,material(color))

func ring(parent: Node3D, at: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.025
	mesh.outer_radius = radius + 0.025
	return shape(parent,mesh,at,material(color,2.0))

func _temple(env: Environment) -> void:
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("101d37")
	sky_mat.sky_horizon_color = Color("a36770")
	sky_mat.ground_horizon_color = Color("a36770")
	sky_mat.ground_bottom_color = Color("101b24")
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	camera.position = Vector3(23,17,31)
	camera.look_at(Vector3(5,5,0))
	camera.fov = 48
	box(world,Vector3(0,-1,0),Vector3(200,1,200),Color("16252f"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 611
	for i in 110:
		var x := rng.randf_range(-65,65)
		var z := rng.randf_range(-65,25)
		if absf(x) < 13 and absf(z) < 13: continue
		var h := rng.randf_range(2,11)
		box(world,Vector3(x,h/2-1,z),Vector3(2.5,h,2.5),Color("293344"))
		for y in range(1,int(h),2):
			box(world,Vector3(x,y,z+1.27),Vector3(1.7,0.08,0.03),Color("d3ac79"),1.4)
	for tier in 5:
		box(world,Vector3(0,tier*0.7,0),Vector3(20-tier*1.8,0.7,15-tier*1.5),Color("777d87"))
	box(world,Vector3(0,4,0),Vector3(12,3,9),Color("8a8c97"))
	for x in [-5.0,5.0]:
		for z in [-3.5,3.5]: _spire(Vector3(x,5,z),7)
	_spire(Vector3(0,5,0),12)
	for x in range(-5,6):
		box(world,Vector3(x,4,4.55),Vector3(0.13,2.7,0.15),Color("dfbc84"),0.6)
	var noise := FastNoiseLite.new()
	noise.frequency = 0.015
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 128
	texture.noise = noise
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.albedo_texture = texture
	cloud_mat.albedo_color = Color(0.65,0.5,0.6,0.16)
	cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cloud_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 7:
		var cloud_mesh := SphereMesh.new()
		cloud_mesh.radius = 1
		cloud_mesh.height = 2
		var cloud := shape(world,cloud_mesh,Vector3(-35+i*12,19+i%3*2,-28-i%2*8),cloud_mat)
		cloud.scale = Vector3(14,0.9,4)
		moving.append(cloud)
	for i in 5:
		var ship: Node3D = load("res://assets/ui/airtaxi.glb").instantiate()
		world.add_child(ship)
		ship.position = Vector3(-30+i*14,8+i%3*3,10-i*8)
		ship.scale = Vector3.ONE * 0.38
		ship.rotation.y = PI/2
		ship.set_meta("ship",true)
		moving.append(ship)

func _spire(at: Vector3, height: float) -> void:
	box(world,at+Vector3(0,height/2,0),Vector3(1.7,height,1.7),Color("9997a1"))
	box(world,at+Vector3(0,height*0.55,0.87),Vector3(0.24,height*0.75,0.05),Color("e0bd78"),1.4)
	var cap := CylinderMesh.new()
	cap.top_radius = 0.08
	cap.bottom_radius = 1.2
	cap.height = 2
	shape(world,cap,at+Vector3(0,height+1,0),material(Color("b8a6a0")))

func _holo() -> void:
	camera.position = Vector3(0,5,10)
	camera.look_at(Vector3(0,2.4,0))
	camera.fov = 35
	cylinder(world,Vector3(0,0.2,0),3,0.4,Color("273b43"))
	ring(world,Vector3(0,0.45,0),2.7,Color("79d3e2"))
	globe = Node3D.new()
	globe.position.y = 3
	world.add_child(globe)
	var sphere := SphereMesh.new()
	sphere.radius = 1.8
	sphere.height = 3.6
	var colors := [Color("265c6d"),Color("416653"),Color("70634a"),Color("424e74")]
	var terrain := ShaderMaterial.new()
	terrain.shader = preload("res://assets/ui/planet.gdshader")
	terrain.set_shader_parameter("seed",float(absi(planet_key.hash())%100))
	terrain.set_shader_parameter("land",colors[absi(planet_key.hash())%4].lightened(0.25))
	if "Ilum" in planet_key: terrain.set_shader_parameter("land",Color("9ac2d5"))
	shape(globe,sphere,Vector3.ZERO,terrain)
	for i in range(-3,4):
		var y := float(i)*0.46
		ring(globe,Vector3(0,y,0),sqrt(3.28-y*y),Color("47858d"))
	for i in 6:
		var meridian := ring(globe,Vector3.ZERO,1.82,Color("47858d"))
		meridian.rotation = Vector3(PI/2,float(i)*PI/6,0)
	var orbit := ring(world,Vector3(0,3,0),2.5,Color("e0bd78"))
	orbit.rotation.x = 0.28
	for i in 4:
		var a := float(i)*TAU/4
		box(world,Vector3(cos(a)*2.2,0.7,sin(a)*2.2),Vector3(0.18,0.5,0.18),Color("79d3e2"),2)

func _archive() -> void:
	camera.position = Vector3(0,6,15)
	camera.look_at(Vector3(0,4,-7))
	box(world,Vector3(0,-0.3,-8),Vector3(40,0.5,50),Color("15252c"))
	for x in [-12,-8,-4,4,8,12]:
		box(world,Vector3(x,5,-10),Vector3(0.3,12,1),Color("5c6567"))
		for y in [1,3,5,7,9]:
			box(world,Vector3(x+1.5,y,-10),Vector3(3,0.18,1.4),Color("677474"))
			for j in 8:
				box(world,Vector3(x+0.2+j*0.36,y+0.65,-10),Vector3(0.18,1.0,0.6),Color("3c8292"),1.2)
	for i in 8:
		var holocron := box(world,Vector3(-10+i*3,3+i%3,-5),Vector3.ONE*0.55,Color("79d3e2"),1.6)
		holocron.rotation = Vector3(0.5,0.5,0.5)
		moving.append(holocron)

func _portrait() -> void:
	viewport.transparent_bg = false
	actor = load("res://assets/ui/%s.glb" % unit_kind).instantiate()
	world.add_child(actor)
	actor.rotation.y = facing * 0.3
	var bounds := _bounds(actor)
	var height := maxf(bounds.size.y,0.1)
	actor.scale *= 2.0/height
	actor.position.y = 0.0 # Skinned unit origins are already at their feet.
	var animation := _animation(actor)
	if animation != null:
		for clip in ["idle","saberIdle"]:
			if animation.has_animation(clip):
				animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
				animation.play(clip)
				break
	camera.position = Vector3(0,1.22,2.0)
	camera.look_at(Vector3(0,1.14,0))
	camera.fov = 30
	var rim := OmniLight3D.new()
	rim.position = Vector3(-facing*2,2,0)
	rim.light_color = Color("79d3e2")
	rim.light_energy = 3
	world.add_child(rim)

func _bounds(node: Node3D) -> AABB:
	var result := AABB()
	if node is MeshInstance3D: result = node.global_transform * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var b := _bounds(child)
			if b.size != Vector3.ZERO: result = b if result.size == Vector3.ZERO else result.merge(b)
	return result

func _animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := _animation(child)
		if found != null: return found
	return null

func _process(delta: float) -> void:
	time += delta
	if camera == null: return
	camera.position.x = base_camera.x + sin(time*0.15)* (0.025 if stage == "portrait" else 0.25)
	if globe != null: globe.rotation.y += delta*0.07
	if actor != null: actor.rotation.y = facing*0.3 + sin(time*0.6)*0.025
	for item in moving:
		if stage == "archive":
			item.rotation.y += delta*0.18
		else:
			item.position.x += delta * (2.0 if item.has_meta("ship") else 0.18)
			if item.position.x > 50: item.position.x = -50

func _batch_boxes() -> void:
	var groups := {}
	for child in world.get_children():
		if not child is MeshInstance3D or not child.mesh is BoxMesh or child in moving: continue
		var mat: StandardMaterial3D = child.material_override
		var key := str(mat.albedo_color) + str(mat.emission_energy_multiplier)
		if not groups.has(key): groups[key] = []
		groups[key].append(child)
	for group in groups.values():
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE
		multi.mesh = cube
		multi.instance_count = group.size()
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = multi
		batch.material_override = group[0].material_override
		world.add_child(batch)
		for i in group.size():
			var original: MeshInstance3D = group[i]
			multi.set_instance_transform(i,original.transform.scaled_local(original.mesh.size))
			world.remove_child(original)
			original.queue_free()
