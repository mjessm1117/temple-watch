extends RefCounted
## Broad stair runs on terrace edges; graph completion also opens small enclosed pockets.
const Shot = preload("res://scripts/shot.gd")

static func prepare(m) -> Dictionary:
	var links := {}; var start := Vector2i(-1,-1); var total := 0
	for y in int(m.spec.height):
		for x in int(m.spec.width):
			var tile := Vector2i(x,y)
			if not m.passable(tile): continue
			total += 1; start = tile
			for d in [Vector2i.DOWN,Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP]:
				var along := x if d.y != 0 else y
				if posmod(along,8) >= 3: continue
				if m.passable(tile+d) and Shot.elevation(m,tile+d)<Shot.elevation(m,tile):
					links[tile] = [tile+d]; break
	if start.x < 0: return links
	for attempt in total:
		var seen := flood(m,links,start)
		if seen.size() == total: break
		var added := false
		for p: Vector2i in seen:
			for d in Shot.DIRS:
				var q: Vector2i = p+d
				if seen.has(q) or not m.passable(q): continue
				var high := p if Shot.elevation(m,p)>Shot.elevation(m,q) else q
				var low := q if high == p else p
				if not links.has(high): links[high] = []
				if low not in links[high]: links[high].append(low)
				added = true; break
			if added: break
		if not added: break
	return links

static func flood(m, links: Dictionary, start: Vector2i) -> Dictionary:
	var seen := {start:true}; var queue: Array[Vector2i] = [start]; var index := 0
	while index < queue.size():
		var p := queue[index]; index += 1
		for d in Shot.DIRS:
			var q: Vector2i = p+d
			if seen.has(q) or not m.passable(q): continue
			if Shot.elevation(m,p) != Shot.elevation(m,q) and q not in links.get(p,[]) and p not in links.get(q,[]): continue
			seen[q] = true; queue.append(q)
	return seen
