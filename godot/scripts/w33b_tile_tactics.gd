extends RefCounted

const Shot = preload("res://scripts/shot.gd")

static func read(m: RefCounted, tile: Vector2i) -> Dictionary:
	var directions := {"north": Vector2i.UP, "east": Vector2i.RIGHT, "south": Vector2i.DOWN, "west": Vector2i.LEFT}
	var cover := {}
	for name in directions:
		var value: int = Shot.cover(m, tile, tile + directions[name] * 2)
		cover[name] = "full" if value >= 40 else "half" if value >= 20 else "none"
	var occupants: Array[Dictionary] = []
	for unit in m.units:
		if int(unit.get("hp", 0)) > 0 and Shot.pos(unit) == tile: occupants.append(unit)
	var flanked_by := 0
	var overwatch_threat := false
	for occupant in occupants:
		for enemy in m.living("enemy" if str(occupant.side) == "player" else "player"):
			var info: Dictionary = Shot.calculate(m, enemy, occupant)
			if bool(info.los) and bool(info.range_ok) and bool(info.flanked): flanked_by += 1
			if bool(enemy.get("overwatch", false)) and bool(info.los) and bool(info.range_ok): overwatch_threat = true
	# An empty preview tile is evaluated against enemy Overwatch for the player lane.
	if occupants.is_empty():
		for enemy in m.living("enemy"):
			if Shot.distance(Shot.pos(enemy), tile) > float(enemy.range) or not Shot.los(m, Shot.pos(enemy), tile): continue
			if Shot.in_cover(m, tile) and Shot.cover(m, tile, Shot.pos(enemy)) == 0: flanked_by += 1
			if bool(enemy.get("overwatch", false)): overwatch_threat = true
	return {"cover": cover, "height_tier": Shot.elevation(m, tile), "flanked_by": flanked_by, "overwatch_threat": overwatch_threat, "destructible": m._destructible(tile)}
