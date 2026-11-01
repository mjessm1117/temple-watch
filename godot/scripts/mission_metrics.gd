extends RefCounted
const Shot = preload("res://scripts/shot.gd")

static func setup(m: RefCounted) -> void:
	m.metrics = {"contact_turn":0,"objective_turn":0,"evac_turn":0,"visited":{},"peak_threats":0,"flank_opportunities":0,"samples":{}}
	sample(m)

static func contact(m: RefCounted) -> void:
	if int(m.metrics.contact_turn) == 0: m.metrics.contact_turn = m.turn

static func sample(m: RefCounted) -> void:
	if m.metrics.is_empty(): return
	var active := 0
	for e in m.living("enemy"):
		if bool(e.awake): active += 1
	m.metrics.peak_threats = maxi(int(m.metrics.peak_threats),active)
	for u in m.living("player"):
		var p := Shot.pos(u); m.metrics.visited[p] = true
		var key := "%d:%d:%s" % [m.turn,int(u.id),p]
		if m.metrics.samples.has(key): continue
		m.metrics.samples[key] = true
		for e in m.living("enemy"):
			if not bool(e.awake): continue
			var info: Dictionary = Shot.calculate(m,u,e)
			if bool(info.los) and bool(info.range_ok) and bool(info.flanked): m.metrics.flank_opportunities += 1

static func report(m: RefCounted) -> Dictionary:
	if m.metrics.is_empty(): return {}
	var floor_count := 0
	for y in int(m.spec.height):
		for x in int(m.spec.width):
			if m.passable(Vector2i(x,y)): floor_count += 1
	return {"contact_turn":m.metrics.contact_turn,"objective_turn":m.metrics.objective_turn,"evac_turn":m.metrics.evac_turn,
		"visited_tiles":m.metrics.visited.size(),"unused_area":1.0-float(m.metrics.visited.size())/maxi(1,floor_count),
		"flank_opportunities":m.metrics.flank_opportunities,"peak_threats":m.metrics.peak_threats}

static func travel(m: RefCounted, u: Dictionary, dest: Vector2i, previous: Dictionary) -> void:
	if u.side != "player": return
	var p := dest
	m.metrics.visited[p] = true
	while previous.has(p):
		p = previous[p]; m.metrics.visited[p] = true
