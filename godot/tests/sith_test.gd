extends SceneTree
const Layer = preload("res://scripts/campaign/sith_layer.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func fresh(seed_value: int = 731):
	var state: Dictionary = Campaign.new().state
	state.erase("sith") # This suite tests the standalone scheduler; host integration has its own gate.
	return Layer.new(state, seed_value)

func advance(layer, days: int) -> void:
	for day in days: layer.advance_day()

func find_mission(layer, kind: String, rival: String = "") -> Dictionary:
	for m in layer.mission_options():
		if m.kind == kind and (rival == "" or m.get("rival_id", "") == rival): return m
	return {}

func run() -> void:
	_test_clock_and_project()
	_test_operations()
	_test_rivals()
	_test_darkness()
	_test_crises()
	_test_year()
	if ResourceLoader.exists("res://scenes/sith_report.tscn"):
		root.size = Vector2i(1366, 768)
		var scene: Control = load("res://scenes/sith_report.tscn").instantiate()
		root.add_child(scene)
		await create_timer(0.1).timeout
		check(scene.layer != null, "standalone report initializes")
		for width in [1366, 1920]:
			root.size = Vector2i(width, 768 if width == 1366 else 1080)
			for page in ["operations", "rivals", "report"]:
				scene.show_page(page)
				await create_timer(0.1).timeout
				check(scene.page_content.global_position.y < 350, "%s %d keeps content above fold" % [page, width])
				check(scene.status_line.get_global_rect().end.y <= root.size.y, "%s %d keeps footer in window" % [page, width])
				check(scene.page_content.size.x <= root.size.x - 60, "%s %d fits horizontal viewport" % [page, width])
		scene.bind_state(fresh().state)
		scene.show_page("operations")
		var op: Dictionary = scene.layer.operations()[0]
		scene._choose(str(op.mission_id))
		check(scene.selected_id == op.mission_id and scene.layer.operations()[0].status == "open", "UI selects counter without fabricating a combat win")
		scene.layer.state.res.intel = 10
		scene._intel(str(op.id))
		check(scene.layer.operations()[0].status == "countered", "UI Intel action uses real logic")
		scene.queue_free()
		await process_frame
	print("SITH TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _test_clock_and_project() -> void:
	var l = fresh()
	check(l.s.day == 0 and l.s.month == 1 and l.rivals().size() == 3, "initial clock and rivals")
	check(l.month_end().is_empty(), "cannot end a month early")
	advance(l, 29)
	check(l.s.reports.is_empty() and l.project_status().next_escalation == 30, "next escalation visible before boundary")
	l.advance_day()
	check(l.s.reports.size() == 1 and l.s.month == 2, "exact boundary rolls month")
	var snapshot := JSON.stringify(l.s)
	l.month_end()
	check(JSON.stringify(l.s) == snapshot, "monthly hook is idempotent")
	check(l.state.elapsed_days == 0, "layer never double advances host time")
	var events: Array = l.pending_events()
	var id: String = events[0].id
	events[0].kind = "tampered"
	check(l.pending_events()[0].kind != "tampered", "event snapshots cannot mutate persistence")
	check(l.acknowledge(id) and not l.acknowledge(id), "events acknowledged exactly once")
	l = fresh()
	l.change_segments(10, "test")
	check(l.project_status().collapse_day == 14, "full Darkness starts recovery window")
	var project := find_mission(l, "project")
	check(l.resolve_mission(project.id, true), "risky objective resolves")
	check(l.s.segments == 10 and l.s.collapse_day == -1, "risky objective reverses two segments and cancels collapse")
	check(not l.resolve_mission(project.id, true), "result replay cannot farm Darkness reduction")
	l.change_segments(-100, "test")
	check(l.s.segments == 0, "Darkness clamps at zero")
	l.change_segments(100, "test")
	advance(l, 14)
	check(l.s.defeated, "unanswered full project ends campaign at deadline")
	snapshot = JSON.stringify(l.s)
	l.advance_day()
	check(not l.resolve_mission("invented", true) and JSON.stringify(l.s) == snapshot, "terminal state cannot advance")

func _test_operations() -> void:
	var l = fresh()
	var op: Dictionary = l.operations()[0]
	check(not l.counter(op.id, "archive"), "counter requires its exact offered mission ID")
	check(l.counter(op.id, op.mission_id), "mission choice reserves counter")
	check(l.resolve_mission(op.mission_id, true), "selected counter victory resolves")
	check(l.operations()[0].status == "countered", "victory stops chosen operation")
	advance(l, 60)
	check(l.operations().size() == 2, "two operations from month three")
	var concealed: Dictionary = l.operations()[1]
	check(not concealed.revealed and not concealed.has("key") and not concealed.has("mod"), "hidden operation redacts its identity and effects")
	var concealed_mission: Dictionary = l.s.missions[concealed.mission_id]
	check(find_mission(l, "counter").has("id"), "counter mission remains offered")
	l.state.res.intel = 0
	check(not l.reveal_operation(concealed.id), "reveal cannot overspend")
	l.state.res.intel = 10
	check(l.reveal_operation(concealed.id) and l.state.res.intel == 9, "reveal costs one Intel")
	check(not l.reveal_operation(concealed.id), "duplicate reveal does not charge")
	check(l.counter(l.operations()[0].id, l.operations()[0].mission_id), "month has a new mission choice")
	check(not l.counter(concealed.id, concealed_mission.id), "one chosen counter mission per month")
	check(l.counter_with_intel(concealed.id), "web Intel alternative can stop the other operation")
	check(not l.resolve_mission(concealed_mission.id, true), "Intel cancellation cannot be resolved again")
	# Exercise every frozen web operation rather than depending on random annual draws.
	for key in l.data.operations:
		var probe = fresh()
		probe.s.ops[0].key = key
		probe.s.ops[0].revealed = true
		probe.state.res.credits = 50
		probe.state.res.kyber = 0
		advance(probe, 30)
		check(probe.s.reports[0].operations[0].status == "hit", key + " applies at deadline")
		var def: Dictionary = probe.data.operations[key]
		if def.has("mod"):
			for mod_key in def.mod: check(probe.campaign_mods()[mod_key] == def.mod[mod_key], key + " exports tactical modifier")
			probe.after_mission("a")
			check(not probe.after_mission("a") and probe.s.mods[0].left == 1, "result replay cannot consume modifier twice")
			probe.after_mission("b")
			check(probe.s.mods.is_empty(), key + " wears off after two battles")
		if key == "supply": check(probe.state.res.credits == 0, "supply raids clamp resources")
		if key == "kyberRaid": check(probe.state.res.kyber == 0, "kyber raid cannot make stock negative")
		if key == "propaganda": check(probe.state.res.favor == 31, "propaganda and two crisis penalties stack")
		if key == "ritual": check(probe.state.orderDark == 5, "ritual affects Order Darkness separately")
		if key in ["bounty", "hunter"]:
			var wounded := false
			for r in probe.state.roster: wounded = wounded or int(r.wound) >= (14 if key == "hunter" else 10)
			check(wounded, key + " wounds an eligible unit")
		if key == "saboteurs":
			check(probe.s.jams.size() == 2, "saboteurs jam two built wings")
			probe.after_mission("a"); probe.after_mission("b"); probe.after_mission("c")
			check(probe.s.jams.is_empty(), "wing jams wear off after three missions")
	l = fresh(1)
	op = l.operations()[0]
	check(not l.send_team(op.id, ["u1", "u1"]), "team members must be distinct")
	l.state.pending_mission = {"squad": ["u1"]}
	check(not l.send_team(op.id, ["u1", "u2"]), "deployed unit cannot join covert team")
	l.state.pending_mission = {}
	check(l.send_team(op.id, ["u1", "u2"]), "web two-unit team deploys")
	check(l.soldier("u1").assign.begins_with("sith_op:"), "covert team unavailable for deployment")
	advance(l, 30)
	check(l.soldier("u1").assign == "" and l.soldier("u2").assign == "", "deadline returns team even without a tactical mission")
	var team_events: Array = l.pending_events().filter(func(e: Dictionary) -> bool: return e.kind == "team_result")
	check(team_events.size() == 1 and int(team_events[0].chance) == 74, "web team odds are rank based")
	for seed_value in [1, 4]:
		var team_layer = fresh()
		var team_op: Dictionary = team_layer.operations()[0]
		var xp: int = team_layer.soldier("u1").xp
		team_layer.send_team(team_op.id, ["u1", "u2"])
		team_layer.s.rng = seed_value
		team_layer.after_mission("team_battle")
		if seed_value == 1:
			check(team_layer.operations()[0].status == "countered" and team_layer.soldier("u1").xp == xp + 15, "successful covert team earns web XP")
		else:
			check(team_layer.operations()[0].status == "open" and team_layer.soldier("u1").stress == 20, "failed covert team leaves operation open with stress")
			team_layer.state.res.intel = 10
			check(team_layer.counter_with_intel(team_op.id), "failed team still permits Intel counter before deadline")

func _test_rivals() -> void:
	var l = fresh()
	advance(l, 14)
	var m := find_mission(l, "ambush", "veyra")
	check(not m.is_empty(), "rival announces first ambush")
	var spawn: Dictionary = l.rival_for_mission(m.id)
	check(spawn.id == "veyra" and spawn.strengths.size() == 2 and spawn.weaknesses.size() == 2, "spawn contract carries rival identity and traits")
	spawn.strengths.clear()
	check(l.rival_for_mission(m.id).strengths.size() == 2, "spawn snapshot cannot erase traits")
	l.resolve_mission(m.id, true)
	check(l.s.rivals.veyra.revealed.size() == 1, "first defeat reveals one practical countermeasure")
	advance(l, 28)
	m = find_mission(l, "ambush", "veyra")
	l.resolve_mission(m.id, true)
	check(l.s.rivals.veyra.revealed.size() == 2 and l.s.rivals.veyra.phase == "stronghold", "second defeat reveals counter and locates stronghold")
	m = find_mission(l, "stronghold", "veyra")
	check(l.resolve_mission(m.id, false), "stronghold failure resolves")
	m = find_mission(l, "stronghold", "veyra")
	check(not m.is_empty(), "stronghold can be retried after failure")
	l.resolve_mission(m.id, true)
	check(l.s.rivals.veyra.revealed.size() == 3, "stronghold victory reveals a countermeasure")
	m = find_mission(l, "pursuit", "veyra")
	check(l.rival_for_mission(m.id).final, "final pursuit spawn flagged")
	l.resolve_mission(m.id, true)
	check(l.s.rivals.veyra.phase == "eliminated" and l.s.rivals.veyra.revealed.size() == 4, "final pursuit permanently eliminates rival")
	check(l.rival_for_mission(m.id).is_empty(), "eliminated rival cannot spawn")
	advance(l, 60)
	check(find_mission(l, "ambush", "veyra").is_empty(), "eliminated rival never returns")
	l = fresh()
	l.s.rivals.nyss.knowledge = 49
	advance(l, 28)
	m = find_mission(l, "kidnap", "nyss")
	check(not m.is_empty(), "knowledge changes ambush into abduction")
	l.resolve_mission(m.id, false, {"captive_id": "u2"})
	check(l.soldier("u2").status == "captured" and l.soldier("u2").sith_captor == "nyss", "failed defense captures a roster member")
	m = find_mission(l, "rescue_rival", "nyss")
	l.resolve_mission(m.id, false)
	m = find_mission(l, "rescue_rival", "nyss")
	check(not m.is_empty() and m.hostages.has("u2"), "failed rescue retains recovery route")
	l.resolve_mission(m.id, true)
	check(l.soldier("u2").status == "active" and not l.soldier("u2").has("sith_captor"), "rescue releases captive")
	var no_captive = fresh()
	for unit in no_captive.state.roster: unit.assign = "train"
	no_captive.s.rivals.nyss.knowledge = 99
	advance(no_captive, 28)
	var abduction := find_mission(no_captive, "kidnap", "nyss")
	var before: int = no_captive.s.segments
	no_captive.resolve_mission(abduction.id, false)
	check(no_captive.s.segments == before + 1 and no_captive.s.rivals.nyss.knowledge == 100, "no eligible captive adds influence; knowledge clamps at 100")
	check(find_mission(no_captive, "rescue_rival").is_empty(), "no empty rescue mission when nobody can be abducted")
	l.retaliation_trigger("test", 3)
	check(not find_mission(l, "retaliation").is_empty(), "retaliation trigger creates mission")
	var count: int = l.s.missions.size()
	l.retaliation_trigger("test", 3)
	check(l.s.missions.size() == count, "retaliation cooldown prevents duplicate attacks")

func _test_darkness() -> void:
	var l = fresh()
	l.soldier("u1").dark = 8
	check(l.mercy("u1", "battle1", "heal1") == 0, "one mercy point carries within battle")
	check(l.mercy("u1", "battle1", "heal1") == 0, "same healing action cannot farm mercy")
	check(l.mercy("u1", "battle1", "heal2") == 1, "two mercy points reduce personal Darkness")
	check(l.mercy("u1", "battle1", "spare", 2) == 1, "sparing surrendered foe earns two points")
	check(l.mercy("u1", "battle1", "heal3", 2) == 0 and l.soldier("u1").dark == 6, "mercy capped at two reductions per mission")
	check(l.mercy("u3", "battle1", "heal4", 2) == 0, "troops cannot accrue Jedi mercy")
	l.after_mission("battle1")
	check(l.mercy("u1", "battle1", "late", 2) == 0, "closed result cannot accept mercy")
	l.soldier("u1").rank = 4
	l.soldier("u1").dark = 0
	l.soldier("u2").dark = 6
	l.state.pairs = {"u2": "u1"}
	advance(l, 30)
	check(l.soldier("u2").dark == 5, "Padawan follows light Master")
	l.soldier("u1").dark = 8
	advance(l, 30)
	check(l.soldier("u2").dark == 6, "dark mentor can corrupt student")
	l.soldier("u2").title = "Knight"
	check(l.set_counsel("u2", "u1"), "rank four Knight can counsel")
	check(not l.set_counsel("u1", "u1") and not l.set_counsel("u1", "u3"), "invalid counselors rejected")
	check(l.set_counsel("u2", ""), "counsel can be removed")
	l = fresh()
	l.soldier("u1").dark = 7
	l.soldier("u1").stress = 40
	var m := find_mission(l, "redemption")
	check(not l.resolve_mission(m.id, true), "redemption needs affected Jedi deployed")
	check(l.resolve_mission(m.id, true, {"deployed": ["u1"]}), "redemption victory accepted with Jedi present")
	check(l.soldier("u1").dark == 3 and l.soldier("u1").stress == 20, "redemption web rewards")
	l.soldier("u1").dark = 8
	check(find_mission(l, "redemption").is_empty(), "one redemption attempt per Jedi per era")
	l.state.era = 2
	m = find_mission(l, "redemption")
	check(not m.is_empty() and m.mission == "r_hospital", "next era restores redemption opportunity")
	l.resolve_mission(m.id, false, {"deployed": ["u1"]})
	check(l.soldier("u1").dark == 9, "failed redemption adds one Darkness")

func _test_crises() -> void:
	var l = fresh()
	var seen := {}
	for month in 5:
		for m in l.mission_options():
			if m.kind == "crisis": seen[m.crisis_id] = true
		advance(l, 30)
	check(seen.size() == 5, "all five data-campaign crises rotate into play")
	check(l.s.reports[0].metrics.crises_ignored == 2, "ignored crises recorded in council report")
	var count: int = l.s.events.size()
	l.month_end()
	check(l.s.events.size() == count, "crisis penalties do not repeat on duplicate month_end")
	var host_owned = fresh()
	host_owned.set_crisis_schedule(false)
	advance(host_owned, 30)
	check(find_mission(host_owned, "crisis").is_empty(), "host can disable duplicate crisis scheduling")
	check(host_owned.s.reports[0].metrics.get("crises_ignored", 0) == 0, "disabled crises never apply invisible ignore penalties")
	host_owned.set_crisis_schedule(true)
	advance(host_owned, 30)
	check(not find_mission(host_owned, "crisis").is_empty(), "crisis rotation resumes at next boundary")

func _test_year() -> void:
	var l = fresh(42)
	var twin = fresh(42)
	var all_rivals := {}
	for day in 360:
		for current in [l, twin]:
			# Active resistance: choose a counter, hit conduits, defend and pursue.
			for m in current.mission_options():
				if m.kind == "counter" and not current.counter(m.op_id, m.id): continue
				current.resolve_mission(m.id, true, {"deployed": ["u1", "u2"]})
			current.after_mission("day_%d" % day)
			current.advance_day()
		check(l.s.day == day + 1 and not l.s.defeated, "active year day %d advances safely" % day)
		if day == 179:
			# JSON conversion catches int/float and dictionary persistence assumptions.
			var loaded: Dictionary = JSON.parse_string(JSON.stringify(l.state))
			l = Layer.new(loaded, 999)
		for r in l.rivals(): all_rivals[r.id] = r.phase
	check(l.s.reports.size() == 12 and l.s.month == 13, "twelve council reports across 360-day year")
	check(JSON.parse_string(JSON.stringify(l.state)) == JSON.parse_string(JSON.stringify(twin.state)), "midyear save/load preserves deterministic future including RNG")
	check(all_rivals.values().all(func(phase: String) -> bool: return phase == "eliminated"), "all three pursuit arcs can finish in one year")
	check(l.s.reports[0].rivals[0].phase != "eliminated", "historical reports retain their original snapshot")
	var idle = fresh()
	advance(idle, 360)
	check(idle.s.defeated and int(idle.s.day) <= 360, "unopposed Sith can win within a year")
