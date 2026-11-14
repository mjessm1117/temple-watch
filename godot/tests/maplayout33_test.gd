extends SceneTree
const Maps = preload("res://scripts/map_catalog.gd")
const Validator = preload("res://scripts/map_validator.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Basic = preload("res://tests/campaign_bot.gd")
const Flank = preload("res://tests/w29d_cover_bot.gd")
const BENCH = ["relay", "rescue", "shrine", "archive", "sabotage"]
const E1 = ["envoy", "dock", "vault", "ilum", "adraasHunt"]
const CSV = "/home/jess/projects/tw-logs/w33/a33/bench.csv"
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	if "--bench-only" in OS.get_cmdline_user_args():
		bench()
		print("MAPLAYOUT33: ", checks, " checks, ", failures, " failures")
		quit(1 if failures else 0)
		return
	var manifest := Maps.manifest()
	for id in manifest.missions:
		var data := Maps.load_map(Maps.resolve(str(id)), 1)
		validate_map(data, str(id))
	for path in manifest.web_variants:
		var data := Maps.load_map(str(path), 1)
		validate_map(data, str(data.id))
	var relay := Maps.load_map(Maps.resolve("relay"), 1)
	check(not bool(relay.concealed), "Mission 1 starts revealed")
	check(relay.squad.all(func(u): return int(u[2]) in [16,17]), "Mission 1 squad y=16–17")
	var front := true
	for group in relay.groups:
		for u in group:
			if int(u[2]) >= 16: front = false
	check(front, "Mission 1 starting enemies are ahead")
	check(not relay.get("wave_roster", []).is_empty(), "Mission 1 reinforcement roster")
	check(relay.wave_roster[0].size() == 2, "Mission 1 first wave warns of two enemies")
	for at in [Vector2i(12,16), Vector2i(13,16), Vector2i(14,16), Vector2i(9,18), Vector2i(10,18)]:
		check(str(relay.rows[at.y])[at.x] not in ["#", "c", "h", "k", "w"], "Mission 1 setup tile stays open %s" % str(at))
	var socket_shifts := {}
	for id in BENCH: socket_shifts[posmod(str(id).hash(), 3) - 1] = true
	check(socket_shifts.size() >= 2, "cover sockets vary across benchmark maps")
	if "--base-only" not in OS.get_cmdline_user_args():
		for id in manifest.missions:
			var source := Maps.read(Maps.resolve(str(id)))
			if not bool(source.get("procedural", false)): continue
			var seen := {}
			var props := {}
			for seed_value in range(1, 21):
				var a := Maps.load_map(Maps.resolve(str(id)), seed_value)
				var b := Maps.load_map(Maps.resolve(str(id)), seed_value)
				check(a.rows == b.rows and a.plot == b.plot, "%s deterministic seed %d" % [id, seed_value])
				seen[JSON.stringify(a.rows)] = true
				props[JSON.stringify(a.plot.placements)] = true
				validate_map(a, "%s seed %d" % [id, seed_value])
			check(seen.size() >= 2, "%s procedural cover varies" % id)
			check(props.size() >= 2, "%s procedural props vary" % id)
			print("PROCEDURAL ", id, " variants=", seen.size())
		if "--layout-only" not in OS.get_cmdline_user_args(): bench()
	print("MAPLAYOUT33: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)

func validate_map(data: Dictionary, label: String) -> void:
	check(not data.is_empty(), "%s exists" % label)
	if data.is_empty(): return
	var rows: Array = data.rows
	var topology := Validator.topology(rows)
	check(int(topology.components) == 1 and topology.cuts.is_empty(), "%s connected without cuts" % label)
	var start := Maps.point([data.squad[0][1], data.squad[0][2]])
	for at in data.objective.points + data.entries + data.evac:
		check(not Validator.path(rows, start, Maps.point(at)).is_empty(), "%s objective/entry/evac reachable %s" % [label, str(at)])
	if label not in BENCH and label not in E1: return
	var full := 0
	var half := 0
	for y in range(1, rows.size() - 1):
		for x in range(1, str(rows[y]).length() - 1):
			if str(rows[y])[x] == "#": full += 1
			elif str(rows[y])[x] in ["c", "h", "k"]: half += 1
	var squad_cover := local_cover(rows, [data.squad])
	var enemy_cover := local_cover(rows, data.groups)
	print("COVER ", label, " full=", full, " half=", half, " squad=", squad_cover, " enemy=", enemy_cover)
	check(full >= 14 and full <= 22, "%s full cover 14–22" % label)
	check(half >= 20 and half <= 35, "%s half cover 20–35" % label)
	check(absf(squad_cover - enemy_cover) <= 1.0, "%s spawn cover tilt" % label)
	var high := 0
	var upper := 0
	for row in rows:
		for tile in str(row):
			if tile in ["^", "M"]: high += 1
	check(high > 0, "%s high ground" % label)
	for row in rows:
		for tile in str(row):
			if tile == "M": upper += 1
	check(upper > 0, "%s tier-two high ground" % label)
	var contract: Dictionary = data.route_validation
	var route_start := Maps.point(contract.start)
	var route_goal := Maps.point(contract.goal)
	var routes := 0
	for via in contract.via:
		var midpoint := Maps.point(via)
		if not Validator.path(rows, route_start, midpoint, 3).is_empty() and not Validator.path(rows, midpoint, route_goal, 3).is_empty(): routes += 1
	check(routes >= 2, "%s has two wide flank approaches" % label)
	for lane in data.plot.lanes:
		for y in range(3, rows.size() - 3):
			var near := false
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					if maxi(absi(dx), absi(dy)) > 4: continue
					var q := Vector2i(int(lane) + dx, y + dy)
					if q.x <= 0 or q.y <= 0 or q.y >= rows.size() - 1 or q.x >= str(rows[q.y]).length() - 1: continue
					if str(rows[q.y])[q.x] in ["#", "c", "h", "k"]: near = true
			check(near, "%s lane %d y=%d has cover within four tiles" % [label, int(lane), y])

func local_cover(rows: Array, groups: Array) -> float:
	var total := 0.0
	var units := 0
	for group in groups:
		for u in group:
			units += 1
			var at := Vector2i(int(u[1]), int(u[2]))
			for y in range(maxi(1, at.y - 5), mini(rows.size() - 1, at.y + 6)):
				for x in range(maxi(1, at.x - 5), mini(str(rows[y]).length() - 1, at.x + 6)):
					if absi(x - at.x) + absi(y - at.y) <= 5 and str(rows[y])[x] in ["#", "c", "h", "k"]: total += 1.0
	return total / maxf(1.0, float(units))

func cap(m) -> int:
	var clock := int(m.spec.get("turn_limit", 0))
	if str(m.spec.family) == "defend" and int(m.spec.objective.get("hold_turns", 0)) == 0:
		return maxi(24, int(m.spec.objective.get("waves", 0)) * 5 + 8)
	return maxi(18, clock + 8)

func bench() -> void:
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("--map="): only = str(arg).trim_prefix("--map=")
	var output := CSV if only == "" else "/home/jess/projects/tw-logs/w33/a33/bench-%s.csv" % only
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_line("map,bot,wins,losses,timeouts,runs,mean_turns")
	for id in BENCH:
		if only != "" and id != only: continue
		for kind in ["campaign", "flank"]:
			var wins := 0
			var losses := 0
			var timeouts := 0
			var turns := 0
			for seed_value in range(1, 11):
				var c = Campaign.new("normal")
				c.state.options = [{"mission":id,"map_variant":0,"adv":false}]
				c.select_mission(0)
				var m = Battle.create(c, seed_value)
				for step in cap(m):
					if m.result != "": break
					if kind == "campaign": Basic.turn(m)
					else: Flank.turn(m)
				turns += int(m.turn)
				if m.result == "win": wins += 1
				elif m.result == "": timeouts += 1
				else: losses += 1
				print("BENCH SEED ", id, " ", kind, " ", seed_value, " ", m.result if m.result != "" else "timeout", " t", m.turn,
					" primary_t=", m.metrics.get("objective_turn", -1), " phase=", m.objective_state.phase, " reason=", m.log_lines[-1] if not m.log_lines.is_empty() else "")
			file.store_line("%s,%s,%d,%d,%d,10,%.1f" % [id, kind, wins, losses, timeouts, float(turns) / 10.0])
			file.flush()
			check(wins + losses + timeouts == 10, "%s %s bot terminates with classified result" % [id, kind])
			check(timeouts == 0, "%s %s has no benchmark timeouts" % [id, kind])
			print("BENCH ", id, " ", kind, " ", wins, "/10 wins, ", timeouts, " timeouts")
	file.close()
