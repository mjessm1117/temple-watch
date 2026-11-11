extends RefCounted
## Seeded, non-colliding dressing. Placement never reads or changes rule state.
const Shot = preload("res://scripts/shot.gd")

static func hash_tile(tile: Vector2i, seed: int) -> int:
	var value := (tile.x*73856093) ^ (tile.y*19349663) ^ seed
	return posmod(value,2147483647)

static func safe(m: RefCounted, tile: Vector2i) -> bool:
	if not m.passable(tile): return false
	for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		if not m.passable(tile+d): return false
	for unit in m.units:
		if Vector2i(int(unit.x),int(unit.y)).distance_squared_to(tile) <= 2: return false
	return true

static func color_for(theme: String) -> Color:
	match theme:
		"jungle": return Color("354c31",0.42)
		"snow": return Color("93b6bc",0.35)
		"plains": return Color("624b2f",0.34)
		"caves": return Color("426485",0.43)
		"dock","city": return Color("17252b",0.42)
		_: return Color("443b32",0.40)

static func build(art: Node3D, m: RefCounted) -> void:
	var seed := int(hash(m.spec))
	var painter := SurfaceTool.new(); painter.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 0
	for y in int(m.spec.height):
		for x in int(m.spec.width):
			var tile := Vector2i(x,y)
			if not safe(m,tile): continue
			var h := hash_tile(tile,seed)
			if h%17 != 0 or count >= 54: continue
			count += 1
			var floor := Shot.elevation(m,tile)*0.7
			var at := Vector3(x,floor,y)
			var angle := float(h%628)/100.0
			var tint := color_for(art.theme)
			# Four vertex colours break the flat stamp without another tile material.
			var corners := [Vector3(-0.34,0.009,-0.23),Vector3(0.30,0.009,-0.19),Vector3(0.23,0.009,0.28),Vector3(-0.28,0.009,0.24)]
			for k in [0,1,2,0,2,3]:
				painter.set_color(tint.lerp(Color(tint.r,tint.g,tint.b,0.07),float((k+h)%4)*0.23))
				painter.add_vertex(at+corners[k].rotated(Vector3.UP,angle))
			if h%3 == 0: continue
			art.batch.begin_record({"tile":tile,"floor":floor,"kind":"map14 clutter","role":"detail"})
			var small := Vector3(0.15,0.14,0.12)
			var offset := Vector3(0.29,0,0.27)
			match art.theme:
				"jungle":
					art.batch.put("cone",art.palette.leaves,at+offset+Vector3.UP*0.07,small,angle)
					art.batch.put("cone",art.palette.leaves,at+Vector3(-0.18,0.09,-0.15),Vector3(0.09,0.18,0.08),angle+0.7)
					art.batch.put("boulder",art.palette.bark,at+Vector3(0.04,0.025,-0.03),Vector3(0.22,0.05,0.17),angle)
				"snow":
					art.batch.put("rock",art.palette.snow,at+offset+Vector3.UP*0.035,Vector3(0.22,0.07,0.15),angle)
				"caves":
					art.batch.put("cone",art.palette.crystal,at+offset+Vector3.UP*0.085,Vector3(0.11,0.17,0.11),angle)
				"plains":
					art.batch.put("boulder",art.palette.wall,at+offset+Vector3.UP*0.055,Vector3(0.18,0.11,0.15),angle)
					for blade in 2:
						art.batch.put("cone",art.palette.leaves,at+Vector3(-0.20+blade*0.10,0.07,-0.18),Vector3(0.06,0.14,0.06),angle)
				"dock","city":
					art.batch.put("box",art.palette.metal,at+offset+Vector3.UP*0.035,Vector3(0.18,0.07,0.13),angle)
					art.batch.put("box",art.palette.dark,at+Vector3(-0.16,0.015,-0.12),Vector3(0.26,0.03,0.07),angle+0.35)
				_:
					art.batch.put("boulder",art.palette.wall,at+offset+Vector3.UP*0.04,Vector3(0.16,0.08,0.13),angle)
			art.batch.end_record()
	if count > 0:
		painter.generate_normals()
		var mesh := painter.commit()
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		var marks := MeshInstance3D.new(); marks.name = "Map14SurfaceMarks"
		marks.mesh = mesh; marks.material_override = material
		marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		art.add_child(marks)
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		accent(art,m,seed)

static func accent(art: Node3D, m: RefCounted, seed: int) -> void:
	var center := Vector2i(int(m.spec.width)/2,int(m.spec.height)/2)
	var tile := center
	for radius in 8:
		for dx in range(-radius,radius+1):
			var p := center+Vector2i(dx,radius)
			if safe(m,p) and hash_tile(p,seed)%3 == 0: tile = p; break
		if tile != center: break
	if not safe(m,tile): return
	var tint := Color("eea35b") if art.theme in ["temple","ruins","dock","city","plains"] else Color("78bad8")
	var light := OmniLight3D.new(); light.name = "Map14Accent"
	light.position = Vector3(tile.x,Shot.elevation(m,tile)*0.7+1.7,tile.y)
	light.light_color = tint; light.light_energy = 0.72; light.omni_range = 4.0
	light.shadow_enabled = false; art.add_child(light)
	var picture := Image.create(32,32,false,Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var uv := Vector2(x-16,y-16)/16.0
			var ripple := sin(uv.x*11.0+uv.y*7.0)*0.13
			var alpha := clampf((1.0-uv.length()+ripple)*0.28,0.0,0.28)
			picture.set_pixel(x,y,Color(tint.r*0.25,tint.g*0.23,tint.b*0.2,alpha))
	var decal := Decal.new(); decal.name = "Map14WearDecal"
	decal.texture_albedo = ImageTexture.create_from_image(picture)
	decal.position = Vector3(tile.x,Shot.elevation(m,tile)*0.7+0.05,tile.y)
	decal.size = Vector3(1.8,0.26,1.8)
	decal.normal_fade = 0.0; art.add_child(decal)
