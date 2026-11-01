extends RefCounted
## Shared synchronous/headed turn boundaries. Enemy decisions run between these.

static func begin(m: RefCounted) -> void:
	if m.result != "" or m.phase != "player": return
	m.action_events.clear()
	if bool(m.prisoner.freed): m._civilian_advance()
	m._check_win()
	if m.result != "": return
	m.phase = "enemy"
	m._wake_groups()
	for u in m.living("enemy"): u.ap = 3; u.overwatch = false

static func finish(m: RefCounted) -> void:
	m._check_lose()
	if m.result != "": return
	m.turn += 1
	if m.turn > int(m.spec.turn_limit):
		m.result = "loss"
		m.message("The evacuation window closes. Mission failed.")
		return
	m.phase = "player"
	for p in m.living("player"):
		p.ap = 3; p.overwatch = false; p.hunkered = false
		if int(p.get("buff_until", 0)) <= m.turn: p.erase("buff_defense"); p.erase("buff_aim")
		if int(p.get("guard_until", 0)) <= m.turn: p.erase("guard")
	for e in m.living("enemy"):
		if int(e.get("debuff_until", 0)) <= m.turn: e.erase("debuff_aim")
		if int(e.get("stunned_until", 0)) < m.turn: e.erase("stunned")
		if int(e.get("marked_until", 0)) <= m.turn: e.erase("marked_aim"); e.erase("marked")
		if int(e.get("suppressed_until", 0)) <= m.turn: e.erase("suppressed_by"); e.erase("suppressed")
	if m.turn == int(m.spec.reinforcement.announce_turn) and int(m.difficulty.get("reinforcement_size", 2)) > 0:
		m.reinforcement_announced = true
		m.reinforcement_marker = Vector2i(int(m.spec.reinforcement.units[0][1]), int(m.spec.reinforcement.units[0][2]))
		m.message("INBOUND: Sith reinforcements at (%d,%d) next turn!" % [m.reinforcement_marker.x, m.reinforcement_marker.y])
	if m.turn == int(m.spec.reinforcement.drop_turn) and int(m.difficulty.get("reinforcement_size", 2)) > 0:
		m.reinforcement_dropped = true
		m.reinforcement_marker = Vector2i(-1, -1)
		for i in range(int(m.difficulty.get("reinforcement_size", 2))):
			var entry: Array = m.spec.reinforcement.units[i % m.spec.reinforcement.units.size()]
			m._spawn_near(str(entry[0]), Vector2i(int(entry[1]), int(entry[2])), 99)
			m.units.back().spotted = true
		m.message("Sith reinforcements land on the eastern road.")
	m._wake_groups()

	m.tick_combat_status()
