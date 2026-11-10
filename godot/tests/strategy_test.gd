extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const Roster = preload("res://scripts/campaign/strat_roster.gd")
const Ops = preload("res://scripts/campaign/strat_ops.gd")
const Council = preload("res://scripts/campaign/strat_council.gd")
const Identity = preload("res://scripts/campaign/strat_identity.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Prefs = preload("res://scripts/campaign/strat_preferences.gd")
var checks := 0
var failures := 0
var months: Array = []
var results := 0
var dark := 0
var capture := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func fresh():
	var c = Campaign.new()
	c.state.res.credits = 5000; c.state.res.kyber = 10; c.state.res.intel = 30
	return c

func run() -> void:
	capture = "--capture-strategy" in OS.get_cmdline_user_args()
	var c = fresh()
	check(c.state.facility.workers.size() == 3 and c.state.cands.size() == 3, "three staff and monthly candidate pool")
	check(c.squad_capacity() == 5 and c.darkness_segments() == 2 and int(c.state.orderDark) == 0, "initial capacity and darkness")
	check(Base.power(c.state) == {"used":3,"capacity":8}, "starting room power")
	check(Base.adjacent("b1", "b2") and not Base.adjacent("b0", "b2"), "wall-sharing adjacency")
	check(int(Base.effects(c.state).stress) == 8, "staff doubles Infirmary Bunks adjacency")
	check(not Base.place(c, "archives", "sp0"), "spires cannot hold a wing")
	check(not Base.place(c, "archives", "m0"), "sealed bay rejects placement")
	check(Base.excavate(c, "m0"), "free artisan starts excavation")
	check(not Base.excavate(c, "u0"), "only one excavation at a time")
	check(not Base.assign_worker(c, "staff2", ""), "excavator cannot be reassigned")
	c.advance_days(4)
	check(not c.state.facility.clear.has("m0"), "excavation requires full work time")
	c.advance_days(1)
	check(c.state.facility.clear.has("m0") and c.state.facility.workers[1].wing == "", "excavation releases artisan")
	check(Base.place(c, "archives", "m0") and c.build_wing("archives"), "placed room starts building")
	c.advance_days(5)
	check(int(c.state.wings.archives) == 1 and Base.slot_of(c.state, "archives") == "m0", "construction honors placement and artisan speed")
	check(not Base.place(c, "archives", "b0"), "completed room cannot teleport")
	check(Base.assign_worker(c, "staff1", "archives"), "archivist fills research slot")
	check(not Base.assign_worker(c, "staff3", "archives"), "wrong staff specialization rejected")
	check(c.start_research("ataru"), "powered Archives starts research")
	c.advance_days(10)
	check(c.researched("ataru"), "archivist accelerates research")
	c.state.wings.forge = 1; c.state.wings.armory = 1
	check(not Base.operational(c.state, "archives"), "power overload disables facilities")
	check(Base.relay(c) and Base.operational(c.state, "archives"), "relay restores power")
	check(Base.excavate(c, "u1"), "undercroft excavation starts")
	c.advance_days(5)
	check(c.state.mods.dug.u1 and c.state.mods.features.u1 == "holocron", "undercroft discovery persists")
	check(int(Base.effects(c.state).research) >= 6, "Archives activates holocron find")
	c.state.month = 4
	check(Base.spire(c, "sp0"), "spire construction available in month four")
	c.advance_days(14)
	check(c.state.mods.spire.sp0 and int(Base.effects(c.state).research) >= 10, "spire contributes research")

	c = fresh()
	var candidate: String = c.state.cands[0].id
	check(Roster.hire(c, candidate) and not Roster.hire(c, candidate), "candidate can only be recruited once")
	check(c.state.roster.size() == 7 and c.soldier("u7").gear.has("smods"), "recruit receives complete compatible gear")
	c.ensure_strategy()
	check(c.soldier("u7").has("voice"), "new recruit receives identity")
	c.soldier("u3").fatigue = 38
	var tired := Gear.battle_stats(c, "u3")
	c.soldier("u3").fatigue = 0
	check(int(Gear.battle_stats(c, "u3").aim) == int(tired.aim) + 5, "Tired penalty reaches battle stats")
	c.soldier("u3").fatigue = 80
	check(not Roster.ready(c.soldier("u3")), "Exhausted soldiers cannot deploy")
	check(c.select_mission(0, ["u3"]).is_empty(), "state rejects exhausted deployment")
	c.advance_days(10)
	check(Roster.ready(c.soldier("u3")), "bench recovery restores readiness")
	c.state.wings.training = 2
	c.soldier("u3").rank = 4; c.soldier("u3").xp = 200
	check(Roster.upgrade_squad(c) and c.squad_capacity() == 6, "first squad capacity upgrade")
	check(not Roster.upgrade_squad(c), "second upgrade requires Barracks II")
	c.state.wings.barracks = 2
	check(Roster.upgrade_squad(c) and c.squad_capacity() == 7, "second squad capacity upgrade")
	check(c.select_mission(0, ["u1","u1"]).is_empty(), "duplicate deployment rejected")
	check(Roster.train(c, "u1", "retrain"), "retraining reserves a soldier")
	check(not c.assign("u1", ""), "training cannot be evaded through assignments")
	c.advance_days(5)
	check(c.soldier("u1").picks.is_empty() and c.soldier("u1").pick == 1, "retrain clears specialization choices")
	check(Roster.train(c, "u3", "slot"), "extra ability slot starts")
	c.advance_days(5)
	check(c.soldier("u3").ability_slots == 1, "extra slot unlocks after training")
	var options := Roster.extra_options(c.soldier("u3"))
	check(not options.is_empty() and Roster.train(c, "u3", "ability", str(options[0])), "cross-choice ability training")
	c.advance_days(5)
	check(c.soldier("u3").extra_picks.size() == 1, "extra ability retained outside rank choices")
	c.state.wings.forge = 1
	check(Roster.start_project(c, "weave"), "Forge prototype starts")
	check(not Roster.start_project(c, "bacta"), "one prototype at a time")
	var armor := int(Gear.battle_stats(c, "u3").armor)
	c.advance_days(12)
	check("weave" in c.state.strategy.projects and int(Gear.battle_stats(c, "u3").armor) == armor + 1, "completed prototype changes deployed stats")

	c = fresh()
	check(c.state.field.list.size() == 1 and c.state.field.list[0].k == "convoy", "initial field offer")
	check(c.field_odds("convoy", ["u1","u1"]) == 0, "field op cannot duplicate a soldier")
	check(c.send_field_op("convoy", ["u1","u3"]), "two-soldier field deployment")
	check(not c.assign("u1", "") and not c.send_field_op("convoy", ["u2","u4"]), "assigned soldiers and spent offers cannot be reused")
	var op: Dictionary = c.state.field.list[0]
	Ops.resolve(c, op, [0,99,99,99])
	check(op.st == "won" and c.soldier("u1").assign == "" and c.soldier("u1").fatigue == 38, "successful operation returns tired team")
	var reward := int(c.state.res.favor)
	Ops.resolve(c, op, [0,0,0,0])
	check(int(c.state.res.favor) == reward, "resolved operation cannot pay twice")
	c.advance_days(30)
	check(c.state.field.list.any(func(x): return x.k == "vault" and x.st == "open"), "monthly covert offer spawns")
	check(c.send_field_op("vault", ["u2","u4","u5"]), "three-soldier covert deployment")
	op = c.state.field.list.filter(func(x): return x.k == "vault")[0]
	Ops.resolve(c, op, [99,0,0,0])
	check(op.st == "lost" and c.soldier("u5").status == "captured" and c.soldier("u2").wound > 0, "failed covert op can ambush, wound and capture")
	c.advance_days(60)
	check(c.soldier("u5").status == "captured", "covert captive stays until rescued")
	check(c.state.field.list.any(func(x): return x.st == "lapsed"), "open offers expire")
	var rescue: Array = c.state.options.filter(func(x): return x.get("hostages", []).has("u5"))
	check(not rescue.is_empty(), "capture creates rescue hook")

	c = fresh()
	c.month_advanced.connect(func(month, snapshot): months.append([month, snapshot.day]))
	c.mission_resolved.connect(func(_result, _summary): results += 1)
	c.darkness_changed.connect(func(segments, _value): dark = segments)
	check(Council.edicts(c, ["scholarship","relief"]), "two edicts can be adopted")
	check(not Council.edicts(c, []), "edict changes lock until next month")
	check(Council.vote(c, "refugees", 0) and not Council.vote(c, "refugees", 0), "Council vote applies once per month")
	c.advance_days(61)
	check(months == [[2,1],[3,1]], "one month signal per crossed boundary")
	check(c.state.cands[0].id.begins_with("candidate-3"), "monthly recruit pool refresh")
	c.gain("orderDark", 50)
	check(dark == c.darkness_segments() and c.darkness_segments() == int(c.sith.project_status().segments) and int(c.state.orderDark) == 50, "darkness hook exposes live Sith segments separately from Order corruption")
	c.state.step = 1; c.refresh_options()
	var qi := -1
	for i in c.state.options.size():
		if c.state.options[i].get("quest", "") == "u1": qi = i; break
	check(qi >= 0, "personal quest is offered")
	check(c.select_mission(qi, ["u3"]).is_empty(), "quest owner must deploy")
	check(not c.select_mission(qi, ["u1","u3"]).is_empty(), "quest owner can take personal mission")
	c.apply_mission_result({"win":true,"units":[{"id":"u1","hp":8,"max_hp":8},{"id":"u3","hp":8,"max_hp":8}]})
	check(results == 1 and c.state.quests.u1.st == "done" and int(c.soldier("u1").bonus.aim) == 5, "quest rewards and mission result hook")
	check(c.soldier("u1").fatigue == 38, "deployed fatigue survives campaign travel")
	c.soldier("u3").rank = 4; Identity.reveal(c)
	check(c.soldier("u3").lore.revealed, "rank reveals hidden secret")
	check(Identity.proximity(c, "u2", 3, true).aim == 10 and Identity.proximity(c, "u2", 4, true).aim == 0, "Padawan radius hook")
	check(Identity.proximity(c, "u2", 1, false).aim == 0, "lost mentor disables proximity bonus")
	check(Identity.voice_line(c, "u1", "select") != "", "voice event resolves campaign personality")
	var path := "user://strategy-test-%d.json" % OS.get_process_id()
	check(c.save(path), "strategy save writes")
	var restored = Campaign.new()
	check(restored.load_save(path), "strategy save loads")
	check(restored.state.strategy == JSON.parse_string(JSON.stringify(c.state.strategy)) and restored.state.facility == JSON.parse_string(JSON.stringify(c.state.facility)), "strategy queues and staff survive round trip")
	c.state.erase("strategy"); c.state.erase("facility"); c.state.erase("slots"); c.state.erase("cands")
	for r in c.state.roster: r.erase("fatigue"); r.erase("lore"); r.erase("voice")
	for wing in c.state.wings: c.state.wings[wing] = 1
	c.save(path); check(restored.load_save(path), "old v2 save migrates")
	check(restored.state.slots.size() == 8 and Base.power(restored.state).capacity >= Base.power(restored.state).used, "legacy rooms keep placement and usable power")
	check(restored.soldier("u1").fatigue == 0 and restored.soldier("u1").has("voice"), "old soldiers receive neutral defaults")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# Mid-queue persistence and chunked time must match day-by-day simulation.
	c = fresh()
	c.state.wings.training = 2; c.state.wings.forge = 1; c.state.wings.archives = 1
	c.state.facility.relay = 2; c.ensure_strategy()
	check(c.start_research("ataru") and Roster.start_project(c, "weave") and Roster.train(c, "u3", "slot") and Base.excavate(c, "u0"), "independent research, project, training and dig queues")
	c.advance_days(2); c.save(path)
	restored = Campaign.new(); restored.load_save(path)
	check(restored.state.strategy.project.id == "weave" and restored.state.strategy.training.id == "u3" and restored.state.facility.dig.slot == "u0", "active queues resume from save")
	c.advance_days(6)
	for day in 6: restored.advance_days(1)
	check(JSON.parse_string(JSON.stringify(c.state.strategy)) == JSON.parse_string(JSON.stringify(restored.state.strategy)) and c.state.research.prog == restored.state.research.prog and c.soldier("u3").ability_slots == restored.soldier("u3").ability_slots, "chunked time equals daily advancement after reload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	c = fresh()
	c.state.res.credits = 0
	var favor := int(c.state.res.favor)
	check(not Council.vote(c, "refugees", 0) and int(c.state.res.favor) == favor, "unaffordable Council vote changes nothing")
	check(not Council.edicts(c, ["relief","relief"]), "duplicate edict cannot stack")
	check(Council.edicts(c, ["scholarship"]), "research edict adopts")
	c.state.res.intel = 0; c.advance_days(30)
	check(c.state.strategy.edict.is_empty(), "unpaid edict suspends at month end")
	c.soldier("u1").rank = 4
	check(preload("res://scripts/campaign/legacy.gd").retire(c, "u1", "council"), "veteran can retire to Council")
	check(Council.support(c, "u1"), "Council adviser can be requested")
	var buffs := preload("res://scripts/campaign/modules.gd").take_next_battle_buffs(c)
	check(int(buffs.aim) == 5 and int(buffs.will) == 5 and c.state.strategy.support.is_empty(), "support is consumed into next deployment buffs")
	check(not Council.support(c, "u1"), "Council adviser rests for a month")
	c = fresh()
	var safe := c.field_risk("convoy", ["u1","u3"])
	c.soldier("u3").fatigue = 38
	var tired_risk := c.field_risk("convoy", ["u1","u3"])
	check(int(tired_risk.success) == int(safe.success) - 8, "field forecast includes tired penalty")
	Council.edicts(c, ["discretion"])
	check(int(c.field_risk("convoy", ["u1","u3"]).ambush) < int(safe.ambush), "discretion reduces actual ambush odds")
	var team: Dictionary = c.state.teams[0]
	var forecast := Ops.team_risk(c, team, {"mission":"rescue"})
	check(int(forecast.success) > 0 and forecast.why.size() >= 2, "strike team forecast explains rank, leadership, fatigue and mission risk")
	check(int(Ops.team_risk(c, team, {"mission":"rescue"}, ["u1","u3","u4"]).success) == 0, "player squad exclusions prevent double deployment")
	check(Progression.battle_abilities(c.soldier("u1")).has("saberThrow"), "active rank choices exposed for tactical kit integration")
	var deployment = preload("res://scripts/campaign/strat_deployment.gd")
	check(deployment.validate(c, ["u1","u2","u3","u4"]), "shared launch validator accepts available squad")
	check(not deployment.validate(c, ["u1","u2","u3","u4","u5","u6","u7","u8"]), "shared launch validator enforces capacity")
	var mission = preload("res://scripts/mission.gd").new(1)
	mission.units = mission.units.filter(func(u): return u.side != "player")
	var tiles: Array[Vector2i] = deployment.spawn_tiles(mission, 7)
	check(tiles.size() == 7, "seven distinct legal deployment tiles available")
	var positions := {}
	for tile in tiles: positions[tile] = true; check(mission.passable(tile) and not mission.occupied(tile), "expanded spawn is passable and vacant")
	check(positions.size() == 7, "upgraded squad does not overlap spawn positions")
	var tactical := {"kit":[]}
	deployment.apply_identity(c, tactical, c.soldier("u1"))
	check(tactical.kit.has("saberThrow") and tactical.voice != "", "bridge adapter carries abilities and voice")
	await ui_checks()
	print("STRATEGY TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func frames(n: int = 3) -> void:
	for i in n: await process_frame

func shot(label: String) -> void:
	if not capture: return
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://../docs/godot/shots/wave7-strategy-%s.png" % label) == OK, "window capture " + label)

func ui_checks() -> void:
	root.size = Vector2i(1366, 768)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://strategy-ui-%d.json" % OS.get_process_id()
	var c = fresh()
	for wing in c.state.wings: c.state.wings[wing] = 1
	c.state.facility.relay = 3; c.state.month = 4; c.ensure_strategy()
	c.state.mods.dug = {"u0":true,"u1":true,"u2":true}
	c.state.mods.features = {"u0":"kyber2","u1":"holocron","u2":"crypt"}
	c.state.mods.spire = {"sp0":true,"sp1":true}
	Base.assign_worker(c, "staff1", "archives"); Base.assign_worker(c, "staff2", "forge")
	c.start_research("ataru"); Roster.start_project(c, "weave")
	c.soldier("u3").fatigue = 52; c.soldier("u4").wound = 9
	Ops.spawn(c); flow.campaign = c; flow.story = c.story
	var temple: Control = load("res://scenes/temple.tscn").instantiate()
	root.add_child(temple); current_scene = temple
	await frames()
	check(temple.temple_view.rooms.u0.built and temple.temple_view.rooms.sp0.built, "new vault and spire remain in 3D cutaway")
	check(temple.temple_view.rooms.archives.staff == 1 and temple.temple_view.art.people.size() > 20, "assigned staff inhabit cutaway")
	await shot("temple")
	for page in ["Command","Build","Roster","Research","Council","Teams","Legacy","Settings"]:
		temple._change_page(page); await frames()
		check(temple.find_child("GraphicsTier", true, false) != null if page == "Settings" else temple.page == page and temple.page_content.get_child_count() > 1, "strategy page renders " + page)
		if page == "Build":
			var bay: Button = temple.page_content.find_child("Bay_u1", true, false)
			check(bay != null, "stepped build grid has selectable vault bay")
			bay.pressed.emit(); await frames(); check(temple.build_slot == "u1", "bay click changes placement context")
		if page == "Teams":
			temple.field_team = ["u1","u3"]; temple._show_page(); await frames()
		if page in ["Roster","Council","Teams","Build"]: await shot(page.to_lower())
	temple._close_station(); temple.queue_free(); current_scene = null; await frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
