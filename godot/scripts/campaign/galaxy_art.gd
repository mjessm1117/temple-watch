extends RefCounted
## Procedural 3D art. Geography remains in galaxy.json; this is only appearance.
static var cloud_noise: NoiseTexture2D
const ROOT = "res://assets/galaxy/"
const LOOK = "res://assets/ui/galaxy15/"
const BIOMES = {
	"Coruscant": ["Ecumenopolis", "172631", "637e86", 3.0],
	"Alderaan": ["Temperate oceans", "174b78", "78a582", 0.0],
	"Balmorra": ["Industrial badlands", "41392b", "b0a16b", 3.0],
	"Inner Rim": ["Ocean frontier", "193d68", "3b9eac", 0.0],
	"Ord Mantell": ["Salvage world", "443d3a", "a37453", 3.0],
	"Mid Rim": ["Gas giant", "4c325d", "c58db5", 2.0],
	"Hydian Way": ["Trade nexus", "1c4b53", "7ab2b7", 3.0],
	"Ruusan": ["Forested valleys", "234d4d", "81a95b", 0.0],
	"Dantooine": ["Grasslands", "274953", "a2b66c", 0.0],
	"Taris": ["Ruined city", "2a333e", "789591", 3.0],
	"Sith frontier": ["Volcanic wastes", "291f29", "be6246", 1.0],
	"Nar Shaddaa": ["Neon city moon", "322a46", "9c7799", 3.0],
	"Ossus": ["Ancient desert", "775237", "d8b17a", 1.0],
	"Ilum": ["Kyber ice", "397b9e", "c4e7ee", 0.0]
}

static func material(file: String) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load((LOOK if file in ["nebula", "planet", "haze", "route"] else ROOT) + file + ".gdshader")
	if file in ["nebula","planet","haze"]:
		if cloud_noise == null:
			cloud_noise = NoiseTexture2D.new(); cloud_noise.width = 512; cloud_noise.height = 512
			cloud_noise.seamless = true
			var noise := FastNoiseLite.new(); noise.seed = 617; noise.frequency = 0.018
			noise.fractal_octaves = 5; cloud_noise.noise = noise
		mat.set_shader_parameter("cloud_noise",cloud_noise)
	if file in ["nebula", "planet"]:
		mat.set_shader_parameter("low_mode", RenderingServer.get_current_rendering_method() == "gl_compatibility")
	return mat

static func mesh(parent: Node3D, shape: Mesh, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new(); node.mesh = shape; node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; parent.add_child(node)
	return node

static func planet(parent: Node3D, title: String, index: int) -> Node3D:
	var root := Node3D.new(); root.name = title; parent.add_child(root)
	var appearance: Array = BIOMES.get(title, ["Uncharted", "285366", "88b0a7", 0.0])
	root.set_meta("biome", appearance[0])
	var surface := material("planet"); surface.set_shader_parameter("ocean", Color(appearance[1]))
	surface.set_shader_parameter("land", Color(appearance[2])); surface.set_shader_parameter("seed", float(index) * 3.71)
	surface.set_shader_parameter("biome", appearance[3])
	var sphere := SphereMesh.new(); sphere.radius = 0.83; sphere.height = 1.66
	# Small Low-tier planets do not need the desktop tessellation in either map view.
	var low := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	sphere.radial_segments = 32 if low else 48; sphere.rings = 16 if low else 24
	var body := mesh(root, sphere, surface); body.name = "Surface"; body.rotation.z = 0.2
	var halo := material("atmosphere"); halo.set_shader_parameter("tint", Color(appearance[2]).lightened(0.22))
	var shell := mesh(root, sphere, halo); shell.name = "Atmosphere"; shell.scale = Vector3.ONE * 1.13
	return root

static func space(parent: Node3D) -> void:
	var env := WorldEnvironment.new(); var settings := Environment.new(); env.environment = settings
	settings.background_mode = Environment.BG_COLOR; settings.background_color = Color("060e15")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; settings.ambient_light_color = Color("79a6be")
	settings.ambient_light_energy = 0.45; settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	settings.glow_enabled = true; settings.glow_intensity = 0.28; parent.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, -40, 0)
	sun.light_color = Color("d4ecff"); sun.light_energy = 1.65; parent.add_child(sun)
	var plane := PlaneMesh.new(); plane.size = Vector2(76, 76)
	var disk := mesh(parent, plane, material("nebula")); disk.position.y = -2.5; disk.name = "SpiralNebula"
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		var dust := mesh(parent, plane, material("nebula")); dust.name = "FarDust"
		dust.position = Vector3(0,-4.5,0); dust.scale = Vector3(1.35,1,1.35)
		dust.material_override.set_shader_parameter("layer_alpha",0.22)
	var stars := MultiMeshInstance3D.new(); stars.name = "Starfield"
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true
	var quad := QuadMesh.new(); quad.size = Vector2(0.22, 0.22); mm.mesh = quad; mm.instance_count = 3400
	var rng := RandomNumberGenerator.new(); rng.seed = 61823
	for i in mm.instance_count:
		var p := Vector3(rng.randf_range(-65,65), rng.randf_range(-15,8), rng.randf_range(-55,55))
		if i < 2300:
			var r := rng.randf_range(2,35); var a := float(i % 4) * PI / 2 + r * 0.19 + rng.randfn(0,0.14)
			p = Vector3(cos(a)*r,rng.randfn(-2,0.9),sin(a)*r)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
		mm.set_instance_color(i, Color(0.45+rng.randf()*0.4,0.6+rng.randf()*0.35,1.0,rng.randf()))
	stars.multimesh = mm; stars.material_override = material("stars"); parent.add_child(stars)

static func ring(parent: Node3D, radius: float) -> MeshInstance3D:
	var line := ImmediateMesh.new(); var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_color = Color("22434d")
	line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 161:
		var a := float(i)/160.0*TAU; line.surface_add_vertex(Vector3(cos(a)*radius,-1.6,sin(a)*radius))
	line.surface_end()
	return mesh(parent, line, mat)

static func travel_lines(parent: Node3D, planets: Dictionary) -> void:
	var routes := [["Coruscant", "Alderaan"], ["Coruscant", "Balmorra"], ["Alderaan", "Dantooine"], ["Balmorra", "Taris"], ["Dantooine", "Ilum"], ["Taris", "Sith frontier"], ["Coruscant", "Nar Shaddaa"]]
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for route in routes:
		if not planets.has(route[0]) or not planets.has(route[1]): continue
		var a: Vector3 = planets[route[0]].position + Vector3(0, -0.65, 0)
		var b: Vector3 = planets[route[1]].position + Vector3(0, -0.65, 0)
		var bend := Vector3(0,0.0,1.0 if a.x < b.x else -1.0)
		for segment in 20:
			var t0 := float(segment)/20.0; var t1 := float(segment+1)/20.0
			lines.surface_add_vertex(a.lerp(b,t0)+bend*sin(t0*PI))
			lines.surface_add_vertex(a.lerp(b,t1)+bend*sin(t1*PI))
	lines.surface_end()
	var node := mesh(parent, lines, material("route")); node.name = "TravelLines"
	node.set_meta("route_count",routes.size())
