extends RefCounted
## Off-board silhouettes leave sightlines to the landscape, never a perimeter fence.
var g
var b
var theme: String

func _init(geometry) -> void:
	g = geometry; b = g.b; theme = g.theme

func put(shape: String, mat: String, at: Vector3, size: Vector3, angle := 0.0) -> void:
	g.put(shape,mat,at,size,angle)

func build(width: int, height: int) -> void:
	# The landing pad has a genuine visual drop; other biomes blend into earth.
	var ground_y := -3.0 if theme == "dock" else -0.45
	put("box","ground",Vector3((width-1)*0.5,ground_y,(height-1)*0.5),Vector3(width+90,0.4,height+90))
	if theme == "dock":
		b.begin_record({"role":"scenery","kind":"hangar apron"})
		put("box","metal",Vector3((width-1)*0.5,-0.4,-8),Vector3(width+24,0.3,15))
		b.end_record()
	if theme in ["temple","ruins"]: g.arcade(width)
	if theme in ["dock","city"]: g.industrial(width,height)
	# Rear landmarks give the sampled shrine, grove and gate different skylines.
	b.begin_record({"role":"scenery","kind":theme+" landmark"})
	var centre := float(width-1)*0.5
	if theme == "plains":
		for side in [-1,1]:
			var cairn := Vector3(centre+side*4.2,-0.18,-5.4)
			for layer in 3:
				put("boulder","wall",cairn+Vector3.UP*(0.22+layer*0.52),Vector3(1.55-layer*0.25,0.55,1.35-layer*0.17))
			put("cone","leaves",cairn+Vector3(side*1.0,0.48,0),Vector3(0.45,0.95,0.46))
	elif theme == "jungle":
		for side in [-1,1]:
			var root := Vector3(centre+side*3.1,0,-5.3)
			put("boulder","bark",root+Vector3.UP*1.0,Vector3(1.6,2.1,1.3))
			put("rock","leaves",root+Vector3.UP*2.3,Vector3(2.6,1.3,2.3))
		put("boulder","bark",Vector3(centre,2.0,-5.3),Vector3(5.2,0.78,1.2))
	elif theme in ["dock","city"]:
		for side in [-1,1]:
			var pylon := Vector3(centre+side*3.2,1.8,-5.2)
			put("bevel","metal",pylon,Vector3(0.95,3.6,0.95))
			put("box","glow",pylon+Vector3(0,0.7,0.50),Vector3(0.18,0.85,0.03))
		put("box","dark",Vector3(centre,3.55,-5.2),Vector3(7.3,0.42,1.0))
	b.end_record()
	for side in 4:
		var count := width if side < 2 else height
		for i in range(1,count,4):
			# Offset every second group; broad openings replace the old continuous ring.
			if (i/4+side)%4 == 2: continue
			var depth := 3.6+float(posmod(i*7+side,3))*0.45
			var at := Vector3(i,-0.25,-depth if side == 0 else height-1+depth)
			if side >= 2: at = Vector3(-depth if side == 2 else width-1+depth,-0.25,i)
			var angle := PI/2 if side >= 2 else 0.0
			var h := 2.2+float(posmod(i*17+side*31,7))*0.43
			if side == 1: h *= 0.35
			b.begin_record({"role":"scenery","kind":theme+" edge"})
			match theme:
				"dock":
					if side == 0 or (side == 2 and i < count/2):
						put("box","metal",at+Vector3.UP*h*0.5,Vector3(3.7,h,0.6),angle)
						put("box","dark",at+Vector3.UP*(h+0.1),Vector3(3.9,0.2,1.0),angle)
						for dx in [-1.5,1.5]:
							put("box","trim",at+Vector3(dx,h*0.5,0.35).rotated(Vector3.UP,angle),Vector3(0.16,h,0.18),angle)
					else:
						put("box","dark",at+Vector3.DOWN*0.9,Vector3(2.6,1.8,1.4),angle)
						put("box","glow",at+Vector3.UP*0.03,Vector3(1.2,0.05,0.12),angle)
				"city":
					if side != 1:
						put("box","wall",at+Vector3.UP*h*0.6,Vector3(2.8,h*1.2,2.0),angle)
						put("box","metal",at+Vector3.UP*(h*1.2+0.1),Vector3(3.1,0.2,2.3),angle)
						for row in range(1,int(h)):
							put("box","window",at+Vector3(0,row,1.01).rotated(Vector3.UP,angle),Vector3(1.8,0.36,0.025),angle)
					else: put("box","dark",at+Vector3.UP*0.24,Vector3(2.2,0.48,0.9),angle)
				"jungle":
					g.tree(at,h+2,true)
					g.tree(at+Vector3(1.25,0,-0.4).rotated(Vector3.UP,angle),h+0.7,true)
					for j in 3:
						put("boulder","bark",at+Vector3((j-1)*0.5,0.16,0.45).rotated(Vector3.UP,angle),Vector3(0.9,0.34,0.8),angle)
				"snow":
					g.rock(at,Vector3(3.6,h,2.5))
					put("boulder","snow",at+Vector3.UP*h*0.77,Vector3(3.5,h*0.5,2.3),angle)
					if side == 0: g.tree(at+Vector3(0,0,-1.8),h+2,false)
				"temple":
					put("box","wall",at+Vector3.UP*0.2,Vector3(3.4,0.4,1.9),angle)
					if side != 1:
						for dx in [-1.2,1.2]: g.r.prop("pillar",at+Vector3(dx,0.4,0).rotated(Vector3.UP,angle),0.9,h)
						put("box","ledge",at+Vector3.UP*(h+0.5),Vector3(3.3,0.2,1.2),angle)
				"ruins":
					put("box","wall",at+Vector3.UP*h*0.3,Vector3(2.0,h*0.6,0.8),angle)
					put("boulder","dark",at+Vector3(0.9,0.38,0),Vector3(1.4,0.76,1.4))
					if side != 1: put("cylinder","wall",at+Vector3(-0.8,h*0.5,0),Vector3(1.1,h,1.1))
				"plains":
					put("rock","ground",at+Vector3.DOWN*0.3,Vector3(4.2,h*0.55,3.6))
					g.rock(at,Vector3(1.7,h*0.48,1.4))
					if side == 0 and i%3 == 0: g.tree(at,h+1,false)
				"caves":
					g.rock(at,Vector3(3.5,h+1,2.5))
					for j in 3:
						put("cone","wall",at+Vector3((j-1)*0.65,h*0.5,0.5),Vector3(0.65,h,0.7))
					if side != 1 and i%3 == 0: g.crystal(at+Vector3(0,0,0.8),0.8)
			b.end_record()
	b.begin_record({"role":"scenery","kind":"distant landscape"})
	for i in range(-12,width+16,6):
		var at := Vector3(i,-0.5,-10.0-float(posmod(i*7,5)))
		var h := 4.0+float(posmod(i*17,7))*0.6
		if theme == "jungle": g.tree(at,h+3,true)
		elif theme in ["snow","caves","ruins"]: g.rock(at,Vector3(7,h,5))
		elif theme == "plains": put("rock","ground",at,Vector3(11,h,8))
	b.end_record()
