extends RefCounted

static func walkable(rows: Array, p: Vector2i) -> bool:
	return p.y >= 0 and p.y < rows.size() and p.x >= 0 and p.x < str(rows[p.y]).length() and str(rows[p.y])[p.x] not in ["#","c","h","k","w"]

static func transform(data: Dictionary, seed_value: int, parcels: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new(); rng.seed = seed_value
	var placements: Array = data.plot.placements
	var swaps: Array = []
	for placement in placements: swaps.append(str(placement.parcel))
	if swaps.size() >= 2:
		var a := rng.randi_range(0,swaps.size()-1)
		var b := posmod(a+rng.randi_range(1,swaps.size()-1),swaps.size())
		var old: String = swaps[a]; swaps[a] = swaps[b]; swaps[b] = old
	for i in placements.size():
		placements[i].parcel = swaps[i]
		placements[i].rotate = rng.randi_range(0,3)
		placements[i].mirror = bool(rng.randi_range(0,1))
		assert(parcels.has(placements[i].parcel))
	var lane_shift := rng.randi_range(-2,2)
	if lane_shift == 0: lane_shift = 1
	var occupied := {}
	for unit in data.squad: occupied[Vector2i(int(unit[1]),int(unit[2]))] = true
	for group in data.groups:
		for unit in group: occupied[Vector2i(int(unit[1]),int(unit[2]))] = true
	for group in data.groups:
		for unit in group:
			var old := Vector2i(int(unit[1]),int(unit[2]))
			occupied.erase(old)
			var next := Vector2i(clampi(old.x+lane_shift,2,int(data.plot.width)-3),old.y)
			if occupied.has(next): next = old
			unit[1] = next.x; occupied[next] = true
	for entry in data.entries:
		if int(entry[0]) <= 2 or int(entry[0]) >= int(data.plot.width)-3:
			entry[1] = clampi(int(entry[1])+lane_shift,2,int(data.plot.height)-3)
		else:
			entry[0] = clampi(int(entry[0])+lane_shift,2,int(data.plot.width)-3)
	data.layout29 = {"seed":seed_value,"lane_shift":lane_shift,"swaps":swaps}
	return data

static func mirror(chunk: Array) -> Array:
	var out := []
	for row in chunk:
		var line := ""
		for x in range(str(row).length()-1,-1,-1): line += str(row)[x]
		out.append(line)
	return out

static func ensure_start_cover(rows: Array[String], data: Dictionary) -> void:
	if data.squad.is_empty(): return
	var start := Vector2i(int(data.squad[0][1]),int(data.squad[0][2]))
	for y in range(start.y-5,start.y+6):
		for x in range(start.x-5,start.x+6):
			var p := Vector2i(x,y)
			if p.y > 0 and p.y < rows.size()-1 and p.x > 0 and p.x < rows[p.y].length()-1 and rows[p.y][p.x] in ["#","c","h","k"] and start.distance_to(p) <= 5.0: return
	var occupied := {}
	for u in data.squad: occupied[Vector2i(int(u[1]),int(u[2]))] = true
	for offset in [Vector2i(0,-2),Vector2i(0,2),Vector2i(-2,0),Vector2i(2,0)]:
		var p: Vector2i = start+offset
		if p.y > 1 and p.y < rows.size()-2 and p.x > 1 and p.x < rows[p.y].length()-2 and rows[p.y][p.x] == "." and not occupied.has(p):
			rows[p.y] = rows[p.y].substr(0,p.x)+"c"+rows[p.y].substr(p.x+1)
			return

static func validate(data: Dictionary) -> Dictionary:
	var rows: Array = data.rows
	if data.squad.is_empty(): return {"ok":false,"errors":["no squad"]}
	var start := Vector2i(int(data.squad[0][1]),int(data.squad[0][2]))
	var queue: Array[Vector2i] = [start]
	var seen := {start:true}; var index := 0
	while index < queue.size():
		var p: Vector2i = queue[index]; index += 1
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var q: Vector2i = p+d
			if not seen.has(q) and walkable(rows,q): seen[q] = true; queue.append(q)
	var anchors: Array = data.objective.points + data.entries + data.evac
	for u in data.squad: anchors.append([u[1],u[2]])
	for group in data.groups:
		for u in group: anchors.append([u[1],u[2]])
	if data.family == "retaliation": anchors.append_array(data.objective.civilians)
	var errors: Array[String] = []
	for at in anchors:
		if not seen.has(Vector2i(int(at[0]),int(at[1]))): errors.append("unreachable %s" % str(at))
	var near_cover := false
	for p in seen:
		if start.distance_to(p) > 6.0: continue
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var q: Vector2i = p+d
			if q.y >= 0 and q.y < rows.size() and q.x >= 0 and q.x < str(rows[q.y]).length() and str(rows[q.y])[q.x] in ["#","c","h","k"]: near_cover = true
	if not near_cover: errors.append("no start cover within six steps")
	return {"ok":errors.is_empty(),"errors":errors,"reachable":seen.size(),"cover_near_start":near_cover}
