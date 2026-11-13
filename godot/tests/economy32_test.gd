extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const Queue = preload("res://scripts/campaign/research_queue.gd")
const Data = preload("res://scripts/campaign/data.gd")
const Classes = preload("res://scripts/class_registry.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func run() -> void:
	var c = Campaign.new()
	var p: Dictionary = c.build_preview25("b0", "archives")
	var before := int(c.state.res.credits)
	check(p.valid and c.confirm_build25("b0", "archives"), "build confirms")
	check(before - int(c.state.res.credits) == int(p.cost), "build preview equals committed cost")
	check(int(Base.power(c.state).used) == int(p.power_after), "build preview equals committed power")
	var elapsed := 0
	while c.state.build != "" and elapsed < 20:
		c.advance_strategy_day25(1, "construction test"); elapsed += 1
	check(elapsed == int(p.days), "build preview equals committed days")
	check(int(p.month_credit_delta) == -int(Data.get_table("core", "WINGS").archives.up[1]) + int(Data.get_table("core", "WINGS").archives.up[0]), "build month delta matches upkeep")
	var study: Dictionary = Data.get_table("research", "RESEARCH").ataru
	before = int(c.state.res.credits)
	check(Queue.enqueue(c, "ataru"), "study confirms")
	check(before - int(c.state.res.credits) == int(study.cost.credits) and int(study.days) == 15, "study card matches committed cost and time")
	before = int(c.state.res.credits)
	var recruits := int(c.state.res.recruits)
	check(Base.hire_staff(c, "archivist"), "staff confirms")
	check(before - int(c.state.res.credits) == 75 and recruits - int(c.state.res.recruits) == 1, "staff card matches committed cost")
	var urgent = Campaign.new()
	urgent.state.wings.archives = 1
	urgent.state.crises11 = {"active":[{"n":"Envoy signal", "deadline":int(urgent.state.elapsed_days) - 1}]}
	var snapshot: Dictionary = urgent.strategic_snapshot25()
	check(snapshot.top_priority.room_id == "war", "overdue threat outranks idle Archives")
	for item in snapshot.priority_items:
		check(str(item.get("reason", "")) != "" and item.has("days_left") and str(item.reason).contains("day"), "priority reason and day count")
	var stale := ["Defender", "Shieldbearer", "Gunslinger", "Soldier"]
	for key in ["core", "temple", "research"]:
		var raw := FileAccess.get_file_as_string("res://data/campaign/%s.json" % key)
		for name in stale: check(not raw.contains('"' + name + '"'), "%s has no stale %s class" % [key, name])
	check(Classes.class_data("trooper").base_stats == Data.get_table("core", "CLASS").Trooper, "Trooper data matches class registry")
	var legacy = Campaign.new()
	for old_class in ["Soldier", "Defender", "Shieldbearer", "Gunslinger"]:
		legacy.state.roster[0].cls = old_class
		legacy.state.roster[0].classes = [old_class.to_lower()]
		legacy._migrate()
		check(not Classes.class_data(str(legacy.state.roster[0].cls)).is_empty() and Classes.class_data(str(legacy.state.roster[0].classes[0])).id == Classes.class_id(str(legacy.state.roster[0].cls)), "old save migrates %s class" % old_class)
	var totals := []
	var receipt_runs := []
	for repeat in 2:
		var fixture = Campaign.new()
		var receipts := []
		fixture.state.pending_mission = {"mission_id":"relay", "squad":["u1","u2","u3"]}
		receipts.append(fixture.apply_mission_result({"mission_id":"relay", "win":true, "story":true, "units":[{"id":"u1","status":"active","hp":5,"max_hp":5,"kills":3},{"id":"u2","status":"active","hp":2,"max_hp":5,"kills":2},{"id":"u3","status":"active","hp":5,"max_hp":5,"kills":1}]}).rewards)
		fixture.state.wings.training = 1; fixture.state.wings.archives = 1; fixture.state.wings.armory = 1
		fixture.ensure_strategy(); fixture.refresh_options()
		var recruit: Dictionary = fixture.state.roster[0].duplicate(true)
		recruit.id = "audit-recruit"; recruit.n = "Audit Recruit"; fixture.state.roster.append(recruit)
		fixture.state.res.credits = 700; fixture.state.res.kyber = 8; fixture.state.res.intel = 12
		fixture.state.wings.forge = 1; fixture.state.wings.comms = 1; fixture.state.wings.gardens = 1
		fixture.state.research.done = ["holocron", "holonet"]; fixture.state.research.cur = ""; fixture.state.research.prog = 0.0
		for j in 4:
			var mission_id := "relay"
			if not fixture.state.options.is_empty(): mission_id = str(fixture.state.options[0].get("mission", "relay"))
			fixture.state.pending_mission = {"mission_id":mission_id, "squad":["u1","u2","u3"], "adv":true}
			receipts.append(fixture.apply_mission_result({"mission_id":mission_id, "win":true, "story":true, "units":[{"id":"u1","status":"active","hp":5,"max_hp":5,"kills":2},{"id":"u2","status":"active","hp":3,"max_hp":5,"kills":1},{"id":"u3","status":"active","hp":5,"max_hp":5,"kills":1}]}).rewards)
			fixture.advance_days(4)
		totals.append([int(fixture.state.res.credits), int(fixture.state.res.intel)])
		receipt_runs.append(receipts)
		check(receipts.size() == 5, "fixture records five win receipts")
	check(receipt_runs[0] == receipt_runs[1], "each five-win receipt is deterministic")
	check(totals[0] == totals[1], "five-win receipts deterministic")
	check(absf(totals[0][0] - 777) <= 777 * 0.05 and absf(totals[0][1] - 16) <= 16 * 0.05, "five-win totals stay within five percent")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(390, 844); root.add_child(viewport)
	var flow = root.get_node("CampaignFlow")
	flow.campaign = c; flow.story = c.story
	var temple: Control = load("res://scenes/temple.tscn").instantiate()
	viewport.add_child(temple)
	for frame in 3: await process_frame
	temple.set_meta("w32c_research_id", "djemSo"); temple._change_page("Research")
	for frame in 3: await process_frame
	var research_cards: Array = temple.page_content.find_children("*", "Label", true, false).filter(func(label): return str(label.text).contains("CONFIRM RESEARCH"))
	check(research_cards.size() == 1, "one research confirm card")
	temple.set_meta("w32c_staff_role", "archivist"); temple._change_page("Build")
	for frame in 3: await process_frame
	var staff_cards: Array = temple.page_content.find_children("*", "Label", true, false).filter(func(label): return str(label.text).contains("CONFIRM STAFF"))
	check(staff_cards.size() == 1, "one staff confirm card")
	viewport.queue_free()
	print("ECONOMY32 FIVE-WIN %s" % JSON.stringify(totals))
	print("ECONOMY32 RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
