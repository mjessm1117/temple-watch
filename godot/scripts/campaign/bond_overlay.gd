extends Control
## Battle line and concise bond labels for strategy screens.

var game: Node

static func summary(s: Dictionary, id: String) -> String:
	var out: Array[String] = []
	for pair in s.get("bonds",{}):
		var bond: Dictionary = s.bonds[pair]
		var ids: PackedStringArray = str(pair).split("|")
		if ids.size() != 2 or id not in ids or int(bond.get("lvl",0)) < 1: continue
		var other := ids[1] if ids[0] == id else ids[0]
		var name := other
		for r in s.get("roster",[]):
			if str(r.get("id","")) == other: name = str(r.get("n",other)); break
		out.append("%s · bond %d/8 (%d cohesion)" % [name,int(bond.lvl),int(bond.get("n",0))])
	return "  |  ".join(out) if not out.is_empty() else "No bond yet"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if game != null and is_instance_valid(game): queue_redraw()

func _draw() -> void:
	if game == null or not is_instance_valid(game) or game.mission == null or game.camera == null: return
	var camera: Camera3D = game.camera
	var bonds: Dictionary = game.mission.bond_pairs if game.mission.get("bond_pairs") != null else {}
	for pair in bonds:
		var bond: Dictionary = game.mission.bond_pairs[pair]
		if int(bond.get("lvl",0)) < 1: continue
		var ids: PackedStringArray = str(pair).split("|")
		if ids.size() != 2: continue
		var points: Array[Vector2] = []
		for rid in ids:
			for u in game.mission.living("player"):
				if str(u.get("rid","")) != rid: continue
				var at := Vector3(float(u.x),game.Shot.elevation(game.mission,game.Shot.pos(u))*0.7+1.4,float(u.y))
				if not camera.is_position_behind(at): points.append(camera.unproject_position(at))
		if points.size() != 2: continue
		draw_line(points[0],points[1],Color(0.35,0.9,1.0,0.72),2.0,true)
		for p in points: draw_circle(p,4.0,Color(0.67,0.96,1.0))
