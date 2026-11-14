extends RefCounted
## Visual-only grammar. All tall set pieces are off-board; on-board marks are flat.
const Shot = preload("res://scripts/shot.gd")

static func cover(g, at: Vector3, kind: String, angle: float, family: int) -> void:
	var t: String = g.theme
	var full := kind == "#"
	var top := 1.75 if full else 0.75
	match t:
		"dock":
			# Ribbed freight modules; alternate cells read as a stacked cargo wall.
			for side in [-1,1]:
				g.put("box","trim",at+Vector3(side*0.39,top*0.55,0.31).rotated(Vector3.UP,angle),Vector3(0.065,top,0.05),angle)
			g.put("box","trim",at+Vector3(0,0.12,0.38).rotated(Vector3.UP,angle),Vector3(0.62,0.06,0.025),angle)
			if full and family == 2: g.put("box","metal",at+Vector3(0,1.88,0),Vector3(0.78,0.25,0.72),angle)
		"city":
			# Shopfront recess and luminous horizontal fascia.
			g.put("box","window",at+Vector3(0,top*0.68,0.37).rotated(Vector3.UP,angle),Vector3(0.58,0.22,0.025),angle)
			g.put("box","banner",at+Vector3(0,top+0.01,0.38).rotated(Vector3.UP,angle),Vector3(0.78,0.16,0.035),angle)
		"jungle":
			g.put("cylinder","bark",at+Vector3(-0.3,top*0.5,0),Vector3(0.25,top,0.25))
			g.put("rock","leaves",at+Vector3(0,top+0.08 if full else 0.68,0),Vector3(0.98,0.34 if full else 0.25,0.94))
			g.put("rock","dark",at+Vector3(0,0.03,0),Vector3(0.98,0.035,0.95)) # canopy shadow
		"plains":
			if not full:
				for side in [-1,1]: g.put("cylinder","dark",at+Vector3(side*0.43,0.43,0).rotated(Vector3.UP,angle),Vector3(0.10,0.86,0.10))
				g.put("box","dark",at+Vector3(0,0.52,0).rotated(Vector3.UP,angle),Vector3(0.92,0.10,0.09),angle)
			else: g.put("boulder","wall",at+Vector3(0.16,1.6,0),Vector3(0.48,0.45,0.7))
		"temple":
			for side in [-1,1]: g.put("cylinder","wall",at+Vector3(side*0.31,top*0.5,0).rotated(Vector3.UP,angle),Vector3(0.2,top,0.2))
			g.put("box","ledge",at+Vector3.UP*(top+0.05),Vector3(0.94,0.12,0.72),angle)
		"ruins":
			g.put("crag","wall",at+Vector3(0,top*0.8,0).rotated(Vector3.UP,angle),Vector3(0.82,0.42,0.34),angle)
			for side in [-1,1]: g.put("boulder","dark",at+Vector3(side*0.27,0.12,0.19).rotated(Vector3.UP,angle),Vector3(0.26,0.24,0.24))
		"snow":
			g.put("boulder","snow",at+Vector3(0,(top if full else 0.65)+0.10,0),Vector3(0.98,0.20,0.94))
			if full: g.put("cone","crystal",at+Vector3(0.32,top+0.27,0),Vector3(0.16,0.50,0.16))
		"caves":
			for side in [-1,1]: g.put("cone","wall",at+Vector3(side*0.3,top+0.32 if full else 0.62,0).rotated(Vector3.UP,angle),Vector3(0.30,0.65 if full else 0.32,0.30))
			g.put("cone","crystal",at+Vector3(0.05,0.24,0.28),Vector3(0.14,0.48,0.15))

func build(g, m: RefCounted, width: int, height: int) -> void:
	var b = g.b
	var t: String = g.theme
	var objective: Array = m.spec.get("objective",{}).get("points",[])
	var focus := Vector2i(width/2,4)
	if not objective.is_empty(): focus = Vector2i(int(objective[0][0]),int(objective[0][1]))
	# A single amber practical anchors the objective even in Compatibility/Low.
	var mood: Dictionary = g.r.themes[t].get("w33c_mood",{})
	var focus_at := Vector3(focus.x,Shot.elevation(m,focus)*0.7+1.3,focus.y)
	var warmth := Color(str(mood.get("practical","#ffc27b")))
	var energy := float(mood.get("energy",1.35))
	if m.modern and not objective.is_empty() and str(m.spec.family) in ["defend","destroy_relay","sabotage","hack_terminal","operation"]:
		# Objective markers already create a lamp. Retint it after they build,
		# avoiding a second Compatibility light pass on the same geometry.
		var art_ref: WeakRef = weakref(g.r)
		g.r.get_tree().process_frame.connect(func():
			var art: Node3D = art_ref.get_ref() as Node3D
			if art == null: return
			var nearest: OmniLight3D = null
			var distance := INF
			for candidate in art.find_children("*","OmniLight3D",true,false):
				var lamp := candidate as OmniLight3D
				var d := lamp.global_position.distance_squared_to(focus_at)
				if d < distance: nearest = lamp; distance = d
			if nearest != null:
				nearest.light_color = warmth
				nearest.light_energy = energy
				nearest.omni_range = 3.2
		,Object.CONNECT_ONE_SHOT)
	else:
		g.r.light(focus_at+Vector3.UP*0.8,warmth,energy,3.2)
	# Extend the existing transparent surface-mark mesh: edge shade and decals
	# cost no new draw or Compatibility light pass.
	var marks := g.r.get_node_or_null("Map14SurfaceMarks") as MeshInstance3D
	var painter := SurfaceTool.new(); painter.begin(Mesh.PRIMITIVE_TRIANGLES)
	if marks != null and marks.mesh != null: painter.append_from(marks.mesh,0,Transform3D.IDENTITY)
	var shoulders: Array[AABB] = []
	for x in [-2.3,float(width)+1.3]:
		_mark(painter,Vector3(x,-0.235,(height-1)*0.5),Color(0.05,0.06,0.07,0.72),0.0,Vector2(2.2,height+10))
		shoulders.append(AABB(Vector3(x-1.1,-0.24,-5.5),Vector3(2.2,0.02,height+10)))
	for y in [-2.3,float(height)+1.3]:
		_mark(painter,Vector3((width-1)*0.5,-0.235,y),Color(0.05,0.06,0.07,0.72),0.0,Vector2(width+10,2.2))
		shoulders.append(AABB(Vector3(-5.5,-0.24,y-1.1),Vector3(width+10,0.02,2.2)))
	b.records.append({"role":"scenery","kind":"w33c edge vignette","non_blocking":true,"bounds":shoulders[0],"parts":shoulders})
	var accents := {"dock":Color("dfb461",0.7),"city":Color("e994bd",0.7),"jungle":Color("648752",0.65),"plains":Color("a49c68",0.62),"temple":Color("d7b270",0.68),"ruins":Color("a35b42",0.65),"snow":Color("a8d5e4",0.68),"caves":Color("a995ca",0.67)}
	for anchor in _anchors(m,focus):
		var tile := _open_near(m,anchor)
		if tile.x < 0: continue
		var h := Shot.elevation(m,tile)*0.7
		var at := Vector3(tile.x,h+0.012,tile.y)
		_mark(painter,at,Color("211e1b",0.55),0.0,Vector2(0.68,0.58))
		var accent: Color = accents[t]
		if t == "dock" and str(m.spec.get("family","")) == "rescue": accent = Color("9ed4dc",0.75)
		if t == "dock" and str(m.spec.get("family","")) == "sabotage":
			for offset in [-0.18,0.0,0.18]: _mark(painter,at+Vector3(offset,0.001,0),accent,PI/4,Vector2(0.05,0.58))
		else:
			_mark(painter,at+Vector3(0,0.001,0),accent,PI/4,Vector2(0.52,0.055))
			if t == "dock": _mark(painter,at+Vector3(0,0.002,0),accent,-PI/4,Vector2(0.52,0.055))
		var footprint := AABB(Vector3(tile.x-0.36,h,tile.y-0.36),Vector3(0.72,0.021,0.72))
		b.records.append({"role":"detail","kind":"w33c surface story","tile":tile,"non_blocking":true,"floor":h,"bounds":footprint,"parts":[footprint]})
	if marks != null: marks.mesh = painter.commit()
	# Mission context is built beside the northern approach and deployment edge.
	b.begin_record({"role":"scenery","kind":"w33c "+t+" story","non_blocking":true})
	var north := Vector3(focus.x,-0.20,-3.0)
	var south := Vector3(_squad_x(m,width),-0.20,height+0.8)
	match t:
		"dock":
			for side in [-1,1]:
				var x: float = north.x+side*3.0
				g.put("bevel","metal",Vector3(x,0.72,-1.8),Vector3(2.3,1.45,1.45))
				for j in 3: g.put("box","trim",Vector3(x-0.75+j*0.75,0.72,-1.06),Vector3(0.05,1.35,0.04))
				g.put("box","metal",Vector3(x,2.75,-1.8),Vector3(2.2,0.13,1.4))
			g.put("box","metal",north+Vector3(5,4.1,0),Vector3(0.24,8.4,0.24))
			g.put("box","metal",north+Vector3(2.2,8.1,0),Vector3(5.6,0.22,0.22))
			g.put("box","trim",north+Vector3(0,0.08,0),Vector3(3.2,0.03,0.28))
			if str(m.spec.family) == "sabotage":
				for side in [-1,1]: g.put("cylinder","metal",north+Vector3(side*1.0,0.4,-0.2),Vector3(0.6,0.8,0.6))
			else: g.put("box","window",north+Vector3(0,1.6,-0.3),Vector3(1.7,0.34,0.04))
		"city":
			for side in [-1,1]:
				g.put("box","wall",north+Vector3(side*3.2,2.5,0),Vector3(2.7,5.4,1.3))
				g.put("box","banner",north+Vector3(side*3.2,3.2,0.7),Vector3(1.7,0.58,0.04))
			g.r.prop("airtaxi",south+Vector3(3.2,1.0,0),2.8,1.2)
		"jungle":
			for side in [-1,1]: g.tree(north+Vector3(side*2.2,0,0),5.6,true)
			g.put("rock","leaves",north+Vector3(0,5.0,0),Vector3(5.1,1.2,1.5))
		"plains":
			for side in [-1,1]: g.rock(north+Vector3(side*2.4,0,0),Vector3(1.9,1.5,1.8))
			for x in range(-3,4): g.put("box","dark",north+Vector3(x*0.8,0.48,0),Vector3(0.08,0.95,0.08))
			g.put("box","dark",north+Vector3(0,0.7,0),Vector3(5.0,0.09,0.08))
		"temple":
			for side in [-1,1]:
				g.stone_guard(north+Vector3(side*2.6,0,0),1.2,3.0)
				g.put("cylinder","wall",north+Vector3(side*4.1,1.5,0),Vector3(0.68,3.0,0.68))
				g.put("cone","ledge",north+Vector3(side*4.1,3.3,0),Vector3(0.42,0.55,0.42))
		"ruins":
			for side in [-1,1]:
				g.put("crag","wall",north+Vector3(side*2.0,1.3,0),Vector3(2.0,2.6,0.7))
				for j in 3: g.put("boulder","dark",north+Vector3(side*2.0+(j-1)*0.44,0.22,0.65),Vector3(0.7,0.42,0.62))
			for j in 3: g.put("boulder","dark",south+Vector3(2+(j-1)*0.5,0.24,0),Vector3(0.8,0.5,0.7))
		"snow":
			for side in [-1,1]:
				g.rock(north+Vector3(side*2.0,0,0),Vector3(2.0,3.3,1.5))
				g.put("boulder","snow",north+Vector3(side*2.0,2.8,0),Vector3(1.9,1.0,1.4))
		"caves":
			for side in [-1,1]:
				g.put("cone","wall",north+Vector3(side*1.6,2.1,0),Vector3(1.5,4.2,1.2))
				g.crystal(north+Vector3(side*2.6,0,0),1.4)
	b.end_record()

func _anchors(m: RefCounted, focus: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = [focus]
	for row in m.spec.squad: result.append(Vector2i(int(row[1]),int(row[2])))
	return result

func _open_near(m: RefCounted, anchor: Vector2i) -> Vector2i:
	for delta in [Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1),Vector2i(2,0),Vector2i(-2,0)]:
		var tile: Vector2i = anchor+delta
		if m.passable(tile) and m.tile(tile) == ".": return tile
	return Vector2i(-1,-1)

func _squad_x(m: RefCounted, width: int) -> float:
	if m.spec.squad.is_empty(): return float(width-1)*0.5
	return float(m.spec.squad[0][1])

func _mark(tool: SurfaceTool, at: Vector3, tint: Color, angle: float, extent: Vector2) -> void:
	var corners := [Vector3(-extent.x*0.5,0,-extent.y*0.5),Vector3(extent.x*0.5,0,-extent.y*0.5),Vector3(extent.x*0.5,0,extent.y*0.5),Vector3(-extent.x*0.5,0,extent.y*0.5)]
	for index in [0,1,2,0,2,3]:
		tool.set_color(tint)
		tool.set_normal(Vector3.UP)
		tool.add_vertex(at+corners[index].rotated(Vector3.UP,angle))
