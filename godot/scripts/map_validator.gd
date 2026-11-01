extends RefCounted
const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const Shot = preload("res://scripts/shot.gd")

static func walkable(rows: Array, p: Vector2i) -> bool:
	return p.y >= 0 and p.y < rows.size() and p.x >= 0 and p.x < str(rows[p.y]).length() and str(rows[p.y])[p.x] not in ["#", "c", "h", "k", "w"]

## Iterative Tarjan: verifies all floor, including optional side rooms, has no cut vertex.
static func topology(rows: Array) -> Dictionary:
	var seen := {}; var low := {}; var parent := {}; var children := {}; var cuts := {}; var components := 0; var isolated: Array = []
	var clock := 0
	for y in rows.size():
		for x in str(rows[y]).length():
			var root := Vector2i(x,y)
			if not walkable(rows, root) or seen.has(root): continue
			components += 1
			var members: Array = []
			clock += 1; seen[root] = clock; low[root] = clock; children[root] = 0
			var stack: Array = [[root, 0]]
			while not stack.is_empty():
				var p: Vector2i = stack[-1][0]
				var i: int = stack[-1][1]
				if i == 4:
					stack.pop_back(); members.append(p)
					if parent.has(p):
						var up: Vector2i = parent[p]
						low[up] = mini(low[up], low[p])
						if parent.has(up) and int(low[p]) >= int(seen[up]): cuts[up] = true
					elif int(children[p]) > 1: cuts[p] = true
					continue
				stack[-1][1] = i+1
				var q: Vector2i = p + DIRS[i]
				if not walkable(rows,q): continue
				if not seen.has(q):
					parent[q] = p; children[p] = int(children[p])+1; children[q] = 0
					clock += 1; seen[q] = clock; low[q] = clock; stack.append([q,0])
				elif q != parent.get(p,Vector2i(-1,-1)): low[p] = mini(low[p],seen[q])
			if components > 1: isolated.append_array(members)
	return {"cuts":cuts.keys(),"components":components,"isolated":isolated,"floor":seen.size()}

static func wide(rows: Array, p: Vector2i) -> bool:
	for y in range(p.y-1,p.y+2):
		for x in range(p.x-1,p.x+2):
			if not walkable(rows,Vector2i(x,y)): return false
	return true

static func path(rows: Array, start: Vector2i, goal: Vector2i, width: int = 1) -> Array[Vector2i]:
	if not walkable(rows,start) or not walkable(rows,goal) or (width == 3 and (not wide(rows,start) or not wide(rows,goal))): return []
	var todo: Array[Vector2i] = [start]; var prev := {start:start}; var index := 0
	while index < todo.size():
		var p: Vector2i = todo[index]; index += 1
		if p == goal: break
		for d in DIRS:
			var q: Vector2i = p+d
			if prev.has(q) or not walkable(rows,q) or (width == 3 and not wide(rows,q)): continue
			prev[q] = p; todo.append(q)
	if not prev.has(goal): return []
	var out: Array[Vector2i] = [goal]; var p := goal
	while p != start: p = prev[p]; out.push_front(p)
	return out

static func validate(m: RefCounted) -> Dictionary:
	var errors: Array[String] = []; var rows: Array = m.board
	if rows.size() != int(m.spec.height): errors.append("height mismatch")
	for row in rows:
		if str(row).length() != int(m.spec.width): errors.append("ragged row")
	var graph := topology(rows)
	if graph.components != 1: errors.append("disconnected floor")
	if not graph.cuts.is_empty(): errors.append("chokepoints: %d" % graph.cuts.size())
	var contract: Dictionary = m.spec.route_validation
	var start := Vector2i(int(contract.start[0]),int(contract.start[1]))
	var goal := Vector2i(int(contract.goal[0]),int(contract.goal[1]))
	var routes := 0; var lanes := {}
	for via in contract.via:
		var p := Vector2i(int(via[0]),int(via[1]))
		if lanes.has(p.x): continue
		lanes[p.x] = true
		var lane_clear := true
		for y in range(mini(start.y,goal.y),maxi(start.y,goal.y)+1):
			if not wide(rows,Vector2i(p.x,y)): lane_clear = false
		if lane_clear and not path(rows,start,p,3).is_empty() and not path(rows,p,goal,3).is_empty(): routes += 1
	if routes < 2: errors.append("fewer than two wide approaches")
	var cover := [0,0,0,0]; var high := 0; var long_sight := 0; var blocked_sight := 0
	for y in rows.size():
		for x in str(rows[y]).length():
			var p := Vector2i(x,y)
			if x > 0 and y > 0 and x < int(m.spec.width)-1 and y < int(m.spec.height)-1 and m.tile(p) in ["#","c","h","k"]:
				cover[(1 if x >= int(m.spec.width)/2 else 0)+(2 if y >= int(m.spec.height)/2 else 0)] += 1
			if m.tile(p) in ["^","M"]: high += 1
			if not m.passable(p): continue
			var q := p + Vector2i(8,0)
			if m.passable(q):
				if Shot.los(m,p,q): long_sight += 1
				else: blocked_sight += 1
	if cover.min() < 1: errors.append("cover absent in a quadrant")
	if high < 2: errors.append("no elevated flank")
	if long_sight < 5 or blocked_sight < 1: errors.append("insufficient sightline spread")
	var anchors: Array = m.spec.objective.points + m.spec.entries + m.spec.evac
	for at in anchors:
		var p := Vector2i(int(at[0]),int(at[1]))
		if path(rows,start,p).is_empty(): errors.append("unreachable objective/entry/evac %s" % p)
	return {"ok":errors.is_empty(),"errors":errors,"routes":routes,"floor":graph.floor,"cover":cover,"high":high,"long_sight":long_sight,"blocked_sight":blocked_sight,"distance":path(rows,start,goal).size()-1}
