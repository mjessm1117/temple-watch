extends RefCounted
## Original procedural architecture. No collision, navigation or rules live here.
const Meshy = preload("res://scripts/meshy_theme_models.gd")
const Shot = preload("res://scripts/shot.gd")
var r
var b
var p: Dictionary
var theme: String

func _init(renderer) -> void:
	r = renderer; b = r.batch; p = r.palette; theme = r.theme

func put(shape: String, mat: String, at: Vector3, size: Vector3, angle := 0.0) -> AABB:
	return b.put("bevel" if shape == "box" and (b.current.get("role", "") == "cover") else shape,p[mat],at,size,angle)

func floor_tile(m: RefCounted, tile: Vector2i) -> void:
	var level := Shot.elevation(m,tile)*0.7
	var at := Vector3(tile.x,0,tile.y)
	var size := Vector3(1,level+0.24,1)
	var center := at+Vector3(0,level/2.0-0.12,0)
	var access: Array[Vector2i] = []
	for lower: Vector2i in r.access_tiles.get(tile,[]): access.append(lower-tile)
	var mat := "water" if m.tile(tile) == "w" else "floor"
	if access.size() == 1:
		var direction := Vector3(access[0].x,0,access[0].y); var angle := atan2(direction.x,direction.z)
		var lower := Shot.elevation(m,tile+access[0])*0.7
		var bounds := put("box",mat,center-direction*0.16,Vector3(1,size.y,0.68),angle)
		if theme in ["dock","city"]:
			bounds = bounds.merge(put("ramp",mat,at+direction*0.34+Vector3.UP*lower,Vector3(1,level-lower,0.32),angle))
			put("box","dark",at+direction*0.34+Vector3.UP*(lower-0.24)/2,Vector3(1,lower+0.24,0.32),angle)
		else:
			for i in 4:
				var top := lerpf(lower,level,float(i+1)/4.0)
				bounds = bounds.merge(put("box",mat,at+direction*(0.46-i*0.08)+Vector3.UP*(top-0.24)/2,Vector3(1,top+0.24,0.08),angle))
		r.floor_bounds[tile] = bounds
	elif access.size() > 1:
		# Four independent stair strips keep pockets and every adjacent route connected.
		# A level centre and corner piers stay at the exact existing rule height.
		var bounds := put("box",mat,center,Vector3(0.6,size.y,0.6))
		for dx in [-0.4,0.4]:
			for dz in [-0.4,0.4]: bounds = bounds.merge(put("box",mat,center+Vector3(dx,0,dz),Vector3(0.2,size.y,0.2)))
		for d in Shot.DIRS:
			var direction := Vector3(d.x,0,d.y); var angle := atan2(direction.x,direction.z)
			if d not in access:
				bounds = bounds.merge(put("box",mat,center+direction*0.4,Vector3(0.6,size.y,0.2),angle)); continue
			var lower := Shot.elevation(m,tile+d)*0.7
			if theme in ["dock","city"]:
				bounds = bounds.merge(put("ramp",mat,at+direction*0.4+Vector3.UP*lower,Vector3(0.6,level-lower,0.2),angle))
				put("box","dark",at+direction*0.4+Vector3.UP*(lower-0.24)/2,Vector3(0.6,lower+0.24,0.2),angle)
			else:
				for i in 4:
					var top := lerpf(lower,level,float(i+1)/4.0)
					var c := at+direction*(0.475-float(i)*0.05)+Vector3(0,(top-0.24)/2,0)
					bounds = bounds.merge(put("box",mat,c,Vector3(0.6,top+0.24,0.05),angle))
			r.floor_bounds[tile] = bounds
	else: r.floor_bounds[tile] = put("box",mat,center,size)
	if m.passable(tile) and posmod(tile.x*37+tile.y*61,19) < 3:
		at.y = level
		b.begin_record({"tile":tile,"kind":"surface detail","floor":level,"role":"detail"})
		if theme in ["jungle","plains"]:
			for j in 4:
				var h := 0.08+float(j%3)*0.035
				put("cone","leaves",at+Vector3(-0.35+j*0.07,h*0.5,0.32),Vector3(0.06,h,0.06))
		elif theme in ["ruins","caves","temple"]:
			put("rock","wall",at+Vector3(0.32,0.025,0.32),Vector3(0.13,0.05,0.12))
		elif theme == "snow":
			put("rock","snow",at+Vector3(0.18,0.035,0.18),Vector3(0.5,0.07,0.5))
		elif theme in ["dock","city"]:
			for j in 3: put("box","trim",at+Vector3(0.20+j*0.08,0.002,-0.32),Vector3(0.035,0.004,0.16))
		b.end_record()
		at.y = 0
	if level <= 0: return
	for d in Shot.DIRS:
		if Shot.elevation(m,tile+d) >= Shot.elevation(m,tile) or d in access: continue
		var dir := Vector3(d.x,0,d.y); var angle := atan2(dir.x,dir.z)
		var lower := Shot.elevation(m,tile+d)*0.7
		put("box","ledge",at+dir*0.478+Vector3.UP*(level-0.04),Vector3(0.98,0.08,0.04),angle)
		put("box","dark",at+dir*0.48+Vector3.UP*(level+lower-0.08)*0.5,Vector3(0.98,level-lower-0.08,0.035),angle)

func cover(m: RefCounted, tile: Vector2i) -> void:
	var c: String = m.tile(tile)
	# Plots without interior full cover (the temple fixture) use sparse rear/side piers
	# on existing blocked boundary tiles. Leave the foreground open for unit readability.
	if tile.x == 0 or tile.y == 0 or tile.x == int(m.spec.width)-1 or tile.y == int(m.spec.height)-1:
		if r.interior_full_cover or Meshy.cover_path(r.props,theme,"full_cover").is_empty(): return
		if not ((tile.x == 0 and tile.y > 0 and tile.y%8 == 0) or (tile.y == 0 and tile.x > 0 and tile.x%8 == 0)): return
	if c not in ["#","c","h","k","r","x"]: return
	var at := Vector3(tile.x,Shot.elevation(m,tile)*0.7,tile.y)
	var horizontal: bool = m.tile(tile+Vector2i.LEFT) == c or m.tile(tile+Vector2i.RIGHT) == c
	var vertical: bool = m.tile(tile+Vector2i.UP) == c or m.tile(tile+Vector2i.DOWN) == c
	var angle := PI/2 if vertical and not horizontal else 0.0
	b.begin_record({"tile":tile,"kind":c,"floor":at.y,"role":"cover"})
	var mesh_angle := Meshy.cover_angle(m,tile,horizontal,vertical)
	var cover_kind := "full_cover" if c == "#" else "half_cover" if c in ["c","h"] else ""
	# Explicit barrel/console/rubble art remains intact.
	var mapped := Meshy.cover_path(r.props,theme,cover_kind) if not m.spec.get("prop_overrides",{}).has(tile) else ""
	if not mapped.is_empty() and b.pair(mapped,at,0.98,1.9 if c == "#" else 0.8,mesh_angle):
		pass
	elif c == "#":
		# The same tall silhouette applies to the boundary and interior: both block LOS.
		if theme in ["snow","caves","plains"]:
			put("boulder","wall",at+Vector3.UP*0.96,Vector3(0.98,1.92,0.98))
			put("boulder","dark",at+Vector3(0.15,0.42,0.1),Vector3(0.64,0.84,0.68))
			if theme == "snow": put("rock","snow",at+Vector3.UP*1.78,Vector3(0.90,0.30,0.90))
		elif horizontal or vertical:
			put("box","dark",at+Vector3.UP*0.10,Vector3(0.98,0.20,0.86),angle)
			put("box","wall",at+Vector3.UP*0.95,Vector3(0.97,1.70,0.68),angle)
			put("box","ledge",at+Vector3.UP*1.88,Vector3(0.98,0.08,0.86),angle)
			if theme in ["dock","city"]:
				for dx in [-0.36,0.36]:
					put("box","metal",at+Vector3(dx,0.95,0.37).rotated(Vector3.UP,angle),Vector3(0.07,1.68,0.09),angle)
				put("box","trim",at+Vector3(0,1.65,0.35).rotated(Vector3.UP,angle),Vector3(0.65,0.035,0.02),angle)
			else:
				for h in [0.60,1.22]: put("box","dark",at+Vector3(0,h,0.345).rotated(Vector3.UP,angle),Vector3(0.96,0.025,0.015),angle)
		elif theme == "jungle":
			put("cylinder","bark",at+Vector3.UP*1.15,Vector3(0.88,2.3,0.88))
			put("boulder","bark",at+Vector3.UP*0.22,Vector3(0.98,0.44,0.98))
		elif theme in ["temple","ruins"]:
			put("box","dark",at+Vector3.UP*0.12,Vector3(0.98,0.24,0.98))
			put("cylinder","wall",at+Vector3.UP*1.1,Vector3(0.78,1.96,0.78))
			put("box","ledge",at+Vector3.UP*2.12,Vector3(0.96,0.16,0.96))
		else:
			put("box","metal",at+Vector3.UP*0.96,Vector3(0.96,1.92,0.90),angle)
			for h in [0.15,1.75]: put("box","dark",at+Vector3.UP*h,Vector3(0.99,0.18,0.98),angle)
			put("box","glow",at+Vector3(0,1.35,0.456),Vector3(0.50,0.06,0.012))
	elif c == "r":
		r.prop("rubble",at,0.87,0.22,angle)
	elif c == "k":
		r.prop("console",at,0.85,0.79,angle)
	elif c == "h" or (theme in ["temple","ruins","caves"] and c == "c"):
		put("box","dark",at+Vector3.UP*0.08,Vector3(0.94,0.16,0.58),angle)
		for row in 3:
			for col in 3:
				var q := at+Vector3((col-1)*0.30,0.15+row*0.20,0).rotated(Vector3.UP,angle)
				put("box","wall",q,Vector3(0.285,0.19,0.51),angle)
		put("box","ledge",at+Vector3.UP*0.77,Vector3(0.96,0.08,0.62),angle)
	elif theme in ["jungle","plains","snow"] and not m.spec.get("prop_overrides",{}).has(tile):
		for row in 3:
			for col in 3:
				put("rock","bags",at+Vector3((col-1)*0.29,0.13+row*0.23,0).rotated(Vector3.UP,angle),Vector3(0.34,0.26,0.61),angle)
	else:
		var kind := str(m.spec.get("prop_overrides",{}).get(tile,"barrel" if c == "x" else "crate"))
		if kind == "barrel": r.prop(kind,at,0.94,0.82,angle)
		else:
			put("box","metal",at+Vector3.UP*0.39,Vector3(0.98,0.78,0.88),angle)
			put("box","dark",at+Vector3.UP*0.80,Vector3(0.99,0.04,0.96),angle)
			for dx in [-0.33,0.33]: put("box","trim",at+Vector3(dx,0.4,0.445).rotated(Vector3.UP,angle),Vector3(0.07,0.7,0.02),angle)
	b.end_record()

func backdrop(width: int, height: int) -> void:
	var seed := float(posmod(hash(r.mission.spec),10000))
	r.palette.floor.set_shader_parameter("map_seed",seed)
	r.palette.ground.set_shader_parameter("map_seed",seed)
	preload("res://scripts/map14_detail.gd").build(r,r.mission)
	preload("res://scripts/map_art_edges.gd").new(self).build(width,height)

func rock(at: Vector3, size: Vector3) -> void:
	put("boulder","wall",at+Vector3.UP*size.y*0.5,size,at.x*0.3)
	put("boulder","dark",at+Vector3(size.x*0.28,size.y*0.2,0),size*0.6,0.7)

func tree(at: Vector3, height: float, broad: bool) -> void:
	put("cylinder","bark",at+Vector3.UP*height*0.46,Vector3(0.23,height*0.92,0.23))
	for j in 3:
		var size := Vector3(2.0-j*0.35,height*0.50,2.0-j*0.35)
		put("rock" if broad else "cone","leaves",at+Vector3(0,height*(0.52+j*0.16),0),size,float(j)*0.9)

func crystal(at: Vector3, height: float) -> void:
	for j in 3:
		put("cone","crystal",at+Vector3((j-1)*0.19,height*(0.5-j*0.08),0),Vector3(0.22,height*(1-j*0.16),0.25))
	r.light(at+Vector3.UP*height,Color("88b6ff"),0.65,2.5)

func arcade(width: int) -> void:
	b.begin_record({"role":"scenery","kind":"arcade"})
	for x in range(0,width,4):
		var at := Vector3(x,-0.25,-4)
		r.prop("pillar",at,1.6,3.6)
		if x+4 >= width: continue
		for j in 11:
			var a := PI*float(j)/10.0
			put("box","wall",Vector3(x+2+cos(a)*1.75,3.15+sin(a)*1.25,-4),Vector3(0.47,0.4,0.8))
		put("box","ledge",Vector3(x+2,4.55,-4),Vector3(4.0,0.16,1.0))
		if theme == "temple":
			put("box","banner",Vector3(x+2,3.3,-3.65),Vector3(0.65,1.9,0.03))
			put("box","trim",Vector3(x+2,3.45,-3.62),Vector3(0.045,1.1,0.025))
	var mid := float(width-1)*0.5
	for side in [-1,1]:
		var at := Vector3(mid+side*5,-0.25,-8)
		r.prop("statue",at,2.1,5.8)
		put("box","wall",Vector3(mid+side*3.6,3.2,-10),Vector3(1.8,6.9,1.9))
		put("cone","wall",Vector3(mid+side*3.6,7.4,-10),Vector3(1.7,2.1,1.7))
	put("box","ledge",Vector3(mid,6.5,-10),Vector3(9.2,0.6,2.2))
	b.end_record()

func industrial(width: int, height: int) -> void:
	b.begin_record({"role":"scenery","kind":"skyline"})
	for i in range(-12,width+18,4):
		var h := 6.0+posmod(i*13,9)
		var at := Vector3(i,-0.25,-12-posmod(i,3)*2)
		put("box","dark",at+Vector3.UP*h*0.5,Vector3(3,h,3))
		put("box","metal",at+Vector3.UP*(h+0.1),Vector3(3.3,0.2,3.3))
		for row in int(h):
			for col in 3:
				if (row+col+i)%3: put("box","window",at+Vector3((col-1)*0.75,row+0.4,1.51),Vector3(0.3,0.10,0.02))
	if theme == "dock":
		r.prop("shuttle",Vector3(width*0.5,-0.25,-6),7.5,3.2)
		for x in [1,width-2]:
			r.prop("gantry",Vector3(x,-0.25,-5),2.5,6.4)
	else: r.prop("airtaxi",Vector3(width+5,-0.25,height*0.5),4.0,1.8)
	b.end_record()
