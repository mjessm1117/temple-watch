extends RefCounted

const ACTIONS_PER_TURN := 2
const Shot = preload("res://scripts/shot.gd")
const Maps = preload("res://scripts/map_catalog.gd")

static func cost(def: Dictionary, unit: Dictionary) -> int:
	var value: Variant = def.get("cost", def.get("ap", 1))
	return int(unit.get("ap", 0)) if str(value) == "remaining" else int(value)

static func spend(unit: Dictionary, def: Dictionary) -> void:
	unit.ap = maxi(0, mini(ACTIONS_PER_TURN, int(unit.ap)) - cost(def, unit))
	if bool(def.get("ends_turn", false)): unit.ap = 0

static func spend_move(unit: Dictionary, actions: int) -> void:
	unit.ap = maxi(0, mini(ACTIONS_PER_TURN, int(unit.ap)) - actions)

static func reach(mission: RefCounted, unit: Dictionary, actions: int) -> Dictionary:
	return mission.paths(unit, int(unit.get("mob", 0)) * clampi(actions, 0, ACTIONS_PER_TURN))

static func defense_turn(mission: RefCounted, unit: Dictionary) -> bool:
	if mission.spec.family != "defend" or mission.objective_state.phase != "primary": return false
	if bool(unit.get("stunned", false)) or bool(unit.get("skip_turn", false)): return false
	var target: Vector2i = Maps.point(mission.spec.objective.points[0])
	if Shot.distance(Shot.pos(unit), target) > 5.0 or not Shot.los(mission, Shot.pos(unit), target):
		var tiles: Dictionary = reach(mission, unit, 1)
		var best: Vector2i = Shot.pos(unit)
		for tile in tiles.costs:
			if Shot.distance(tile, target) < Shot.distance(best, target): best = tile
		if best != Shot.pos(unit): mission.move(int(unit.id), best)
	if int(unit.hp) > 0 and int(unit.ap) > 0 and Shot.distance(Shot.pos(unit), target) <= 5.0 and Shot.los(mission, Shot.pos(unit), target):
		unit.ap = 0
		mission.damage_objective(2)
		mission.action_events.append({"kind":"objective_attack", "actor":unit.id, "from":Shot.pos(unit), "to":target, "damage":2})
	return true
