extends RefCounted
## Original procedural architecture. No collision, navigation or rules live here.
const Shot = preload("res://scripts/shot.gd")
var r
var b
var p: Dictionary
var theme: String

func _init(renderer) -> void:
	r = renderer; b = r.batch; p = r.palette; theme = r.theme

func put(shape: String, mat: String, at: Vector3, size: Vector3, angle := 0.0) -> AABB:
	return b.put(shape,p[mat],at,size,angle)

func floor_tile(m: RefCounted, tile: Vector2i) -> void:
	var level := Shot.elevation(m,tile)*0.7
	var at := Vector3(tile.x,0,tile.y)
	var size := Vector3(1,level+0.24,1)
	var center := at+Vector3(0,level/2.0-0.12,0)
	var access := Vector2i.ZERO
	if level > 0:
		for d in [Vector2i.DOWN,Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP]:
			if m.in_bounds(tile+d) and m.passable(tile+d) and Shot.elevation(m,tile+d) < Shot.elevation(m,tile):
				access = d; break
	var mat := "water" if m.tile(tile) == "w" else "floor"
	if access != Vector2i.ZERO:
		var direction := Vector3(access.x,0,access.y)
		var angle := atan2(direction.x,direction.z)
		var lower := Shot.elevation(m,tile+access)*0.7
		var bounds := put("box",mat,center-direction*0.16,Vector3(1,size.y,0.68),angle)
		if theme in ["dock","city"] and (tile.x+tile.y)%2 == 0:
			var foot := at+direction*0.34+Vector3.UP*lower
			bounds = bounds.merge(put("ramp",mat,foot,Vector3(1,level-lower,0.32),angle))
			put("box","dark",foot-Vector3.UP*(lower+0.24)/2,Vector3(1,lower+0.24,0.32),angle)
		else:
			# Treads stay inside the tile; its centre is at the exact rule height.
			for i in 4:
				var top := lerpf(lower,level,float(i+1)/4.0)
				var c := at+direction*(0.46-float(i)*0.08)+Vector3(0,(top-0.24)/2,0)
				bounds = bounds.merge(put("box",mat,c,Vector3(1,top+0.24,0.08),angle))
				put("box","trim",at+direction*(0.49-float(i)*0.08)+Vector3.UP*(top-0.015),Vector3(0.85,0.026,0.018),angle)
		r.floor_bounds[tile] = bounds
	else: r.floor_bounds[tile] = put("box",mat,center,size)
	if m.tile(tile) == "." and posmod(tile.x*37+tile.y*61,19) < 3:
		b.begin_record({"tile":tile,"kind":"surface detail","floor":level,"role":"detail"})
		if theme in ["jungle","plains"]:
			for j in 4:
				var h := 0.08+float(j%3)*0.035
				put("cone","leaves",at+Vector3(-0.35+j*0.07,h*0.5,0.32),Vector3(0.06,h,0.06))
		elif theme in ["ruins","caves","temple"]:
			put("rock","wall",at+Vector3(0.32,0.025,0.32),Vector3(0.13,0.05,0.12))
		elif theme in ["dock","city"]:
			for j in 3: put("box","trim",at+Vector3(0.20+j*0.08,0.002,-0.32),Vector3(0.035,0.004,0.16))
		b.end_record()
	if level <= 0: return
	for d in Shot.DIRS:
		if Shot.elevation(m,tile+d) >= Shot.elevation(m,tile) or d == access: continue
		var dir := Vector3(d.x,0,d.y); var angle := atan2(dir.x,dir.z)
		put("box","ledge",at+dir*0.478+Vector3.UP*(level-0.08),Vector3(0.98,0.12,0.04),angle)
		put("box","dark",at+dir*0.48+Vector3.UP*0.18,Vector3(0.98,0.10,0.035),angle)
		for offset in [-0.34,0.34]:
			put("box","wall",at+Vector3(offset,level*0.5,0.46).rotated(Vector3.UP,angle),Vector3(0.10,level,0.06),angle)

func cover(m: RefCounted, tile: Vector2i) -> void:
	var c: String = m.tile(tile)
	if c not in ["#","c","h","k","r","x"]: return
	var at := Vector3(tile.x,Shot.elevation(m,tile)*0.7,tile.y)
	var horizontal: bool = m.tile(tile+Vector2i.LEFT) == c or m.tile(tile+Vector2i.RIGHT) == c
	var vertical: bool = m.tile(tile+Vector2i.UP) == c or m.tile(tile+Vector2i.DOWN) == c
	var angle := PI/2 if vertical and not horizontal else 0.0
	b.begin_record({"tile":tile,"kind":c,"floor":at.y,"role":"cover"})
	if c == "#":
		# The same tall silhouette applies to the boundary and interior: both block LOS.
		var kind := "wall_"+str(r.props.wall_of.get(theme,theme))
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
		else:
			r.prop("pillar" if theme in ["temple","ruins"] else kind,at,0.92,1.92,angle)
			put("box","dark",at+Vector3.UP*0.10,Vector3(0.96,0.20,0.96))
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
		r.prop(kind,at,0.86,0.82,angle)
	b.end_record()

func backdrop(width: int, height: int) -> void:
	# Dressing remains at least one full tile beyond all four boundaries.
	put("box","ground",Vector3((width-1)*0.5,-0.45,(height-1)*0.5),Vector3(width+90,0.4,height+90))
	if theme in ["temple","ruins"]: arcade(width)
	if theme in ["dock","city"]: industrial(width,height)
	for side in 4:
		var count := width if side < 2 else height
		for i in range(-3,count+4,3):
			var at := Vector3(i,-0.25,-2.7 if side == 0 else height+1.7)
			if side >= 2: at = Vector3(-2.7 if side == 2 else width+1.7,-0.25,i)
			var h := 1.5+float(posmod(i*17+side*31,7))*0.31
			# Keep the foreground low for the tactical camera.
			if side == 1: h *= 0.45
			b.begin_record({"role":"scenery","kind":theme})
			match theme:
				"jungle", "plains":
					rock(at,Vector3(2.2,h*0.35,1.8))
					if side != 1 or i%2 == 0: tree(at+Vector3(0,0.1,-0.2),h+2,theme == "jungle")
				"snow":
					rock(at,Vector3(3,h,2.4)); put("rock","snow",at+Vector3.UP*h*0.70,Vector3(2.85,h*0.38,2.2))
					if side == 0 and i%2 == 0: tree(at+Vector3(0,0,-1.4),h+2,false)
				"caves":
					rock(at,Vector3(3.4,h+1.2,2.5))
					put("cone","wall",at+Vector3.UP*(h+0.4),Vector3(1.2,h+1.5,1.2))
					if i%2 == 0: crystal(at+Vector3(0,0,0.8),0.8)
				"ruins", "temple":
					if side != 0:
						r.prop("pillar",at,1.25,h+0.5)
						r.prop("rubble",at+Vector3(0.5,0,0.4),1.8,0.32)
				"dock", "city":
					put("box","dark",at+Vector3.UP*0.18,Vector3(2.9,0.36,1.3))
					if side != 1 and i%3 == 0 and i%2 == 0: r.prop("container" if theme == "dock" else "wall_metal",at,1.9,h)
			b.end_record()
	if theme in ["jungle","plains","snow","caves","ruins"]:
		b.begin_record({"role":"scenery","kind":"distant ridge"})
		for i in range(-12,width+16,4):
			var at := Vector3(i,-0.25,-8.0-float(posmod(i*7,5)))
			var h := 3.0+float(posmod(i*17,7))*0.6
			if theme in ["jungle","plains"]: tree(at,h,theme == "jungle")
			else: rock(at,Vector3(6.5,h,4.5))
		b.end_record()
	for i in range(2,width,6):
		var at := Vector3(i,-0.25,-1.7)
		b.begin_record({"role":"scenery","kind":"lamp"})
		if theme in ["temple","ruins","caves"]:
			r.prop("brazier",at,0.7,1.15)
			put("cone","fire",at+Vector3.UP*1.3,Vector3(0.27,0.6,0.27))
			r.light(at+Vector3.UP*1.4,Color("ffaa60"),1.5,4)
		else:
			put("box","metal",at+Vector3.UP*1.3,Vector3(0.10,2.6,0.10))
			put("box","glow",at+Vector3.UP*2.6,Vector3(0.44,0.14,0.3))
			r.light(at+Vector3.UP*2.5,Color("a9dfef"),1.3,4)
		b.end_record()

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
