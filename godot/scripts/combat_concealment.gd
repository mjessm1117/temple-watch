extends RefCounted
const Shot = preload("res://scripts/shot.gd")

static func detection_tiles(m: RefCounted) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not m.squad_concealed: return out
	for e in m.living("enemy"):
		if not bool(e.get("spotted", false)): continue
		var radius := int(e.get("detection", 3))
		for y in range(int(e.y) - radius, int(e.y) + radius + 1):
			for x in range(int(e.x) - radius, int(e.x) + radius + 1):
				var p := Vector2i(x, y)
				if m.passable(p) and Shot.distance(Shot.pos(e), p) <= radius and Shot.los(m, Shot.pos(e), p) and p not in out: out.append(p)
	return out

static func observe(m: RefCounted) -> void:
	for e in m.living("enemy"):
		for p in m.living("player"):
			if Shot.distance(Shot.pos(e), Shot.pos(p)) <= (11 if "sense" in p.get("passives", []) else 8) and Shot.los(m, Shot.pos(p), Shot.pos(e)): e.spotted = true

static func detect_path(m: RefCounted, u: Dictionary) -> void:
	for q in u.get("combat_route", [Shot.pos(u)]):
		for e in m.living("enemy"):
			if Shot.distance(Shot.pos(e), q) <= float(e.get("detection", 3)) and Shot.los(m, Shot.pos(e), q):
				break_squad(m, u)
				return

static func break_squad(m: RefCounted, actor: Dictionary) -> void:
	var was_squad: bool = m.squad_concealed
	var concealed: bool = was_squad or bool(actor.get("concealed", false))
	actor.concealed = false
	if not concealed: return
	m.squad_concealed = false
	if was_squad:
		for p in m.living("player"): p.concealed = false
	m.message("CONCEALMENT BROKEN — ambush overwatch!")
	var previous_defer: bool = m.defer_resolution
	if m.presentation_active: m.defer_resolution = true
	m._wake_groups()
	# Watchers keep their prepared shot until an exposed foe can be hit.
	for e in m.living("enemy"):
		if bool(e.awake): m._reaction_fire(e)
	m.defer_resolution = previous_defer
