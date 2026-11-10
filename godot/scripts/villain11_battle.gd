extends RefCounted
## Campaign story rivals use the normal enemy model and battle message log.

static func setup(m: RefCounted, pending: Dictionary) -> void:
	if not bool(pending.get("villain_present", false)): return
	m.objective_state.villain_name = str(pending.get("villain_name", "Sith Lord"))
	m.objective_state.villain_end_bark = str(pending.get("villain_end_bark", ""))
	m.objective_state.villain_intro_line = str(pending.get("villain_intro_line", pending.get("villain_start_bark", "%s enters the battle." % m.objective_state.villain_name))).replace("\n", " ").strip_edges()
	m.objective_state.villain_retreat_line = str(pending.get("villain_retreat_line", pending.get("villain_end_bark", "%s withdraws." % m.objective_state.villain_name))).replace("\n", " ").strip_edges()
	m.objective_state.villain_status = "arriving"
	var duel := str(m.spec.get("family", "")) == "sith_lord_duel"
	var villain: Dictionary = {}
	if duel:
		for enemy in m.living("enemy"):
			if bool(enemy.get("duel_boss", false)):
				villain = enemy
				break
	if villain.is_empty():
		var at := _spawn_tile(m)
		if at.x < 0: return
		m._spawn("lord11", at.x, at.y, -1)
		villain = m.units.back()
		if not duel:
			villain.hp = 24
			villain.max_hp = 24
			villain.damage = [2, 4]
			villain.aim = 70
			villain.duel_boss = false
			villain.boss = false
			villain.description = "A Sith rival who withdraws when badly wounded."
	villain.name = m.objective_state.villain_name
	villain.villain11 = true
	villain.no_capture = true
	villain.awake = true
	villain.spotted = true
	m.objective_state.villain_outcome = "present"
	m.message(str(pending.get("villain_start_bark", "")))

static func mark_present(m: RefCounted) -> void:
	if str(m.objective_state.get("villain_status", "")) == "arriving": m.objective_state.villain_status = "present"

static func on_damage(m: RefCounted, target: Dictionary) -> bool:
	if not bool(target.get("villain11", false)) or m.objective_state.get("villain_outcome", "absent") != "present": return false
	if str(m.spec.get("family", "")) != "sith_lord_duel" and int(target.hp) * 10 <= int(target.max_hp) * 3:
		m.objective_state.villain_outcome = "retreated"
		m.objective_state.villain_status = "retreating"
		target.status = "retreated"
		target.hp = maxi(1, int(target.hp))
		m.units.erase(target)
		if not str(m.objective_state.villain_end_bark).is_empty(): m.message(m.objective_state.villain_end_bark)
		return true
	if int(target.hp) <= 0:
		m.objective_state.villain_outcome = "defeated"
		m.objective_state.villain_status = "retreating"
		if not str(m.objective_state.villain_end_bark).is_empty(): m.message(m.objective_state.villain_end_bark)
	return false

static func outcome_text(name: String, outcome: String) -> String:
	match outcome:
		"defeated": return "%s was defeated in battle." % name
		"retreated": return "%s retreated from the battlefield." % name
		"present": return "%s remained on the battlefield." % name
	return ""

static func finish(m: RefCounted) -> void:
	if m.objective_state.get("villain_outcome", "absent") != "present": return
	m.objective_state.villain_outcome = "retreated"
	m.objective_state.villain_status = "retreating"
	for enemy in m.living("enemy"):
		if bool(enemy.get("villain11", false)):
			enemy.status = "retreated"
			m.units.erase(enemy)
			break
	if not str(m.objective_state.villain_end_bark).is_empty(): m.message(m.objective_state.villain_end_bark)

static func _spawn_tile(m: RefCounted) -> Vector2i:
	var players: Array[Dictionary] = m.living("player")
	var anchor := Vector2i(-1, -1)
	var best_distance := -1
	for group in m.spec.groups:
		for entry in group:
			var at := Vector2i(int(entry[1]), int(entry[2]))
			var distance := 999
			for player in players:
				distance = mini(distance, abs(at.x - int(player.x)) + abs(at.y - int(player.y)))
			if distance >= best_distance:
				best_distance = distance
				anchor = at
	if anchor.x < 0: return anchor
	for radius in range(1, 5):
		for offset in [Vector2i(radius,0), Vector2i(0,radius), Vector2i(0,-radius), Vector2i(-radius,0)]:
			var at: Vector2i = anchor + offset
			if m.passable(at) and not m.occupied(at): return at
	return Vector2i(-1, -1)
