extends SceneTree

const Story = preload("res://scripts/story/story_engine.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Room = preload("res://scripts/w25_menus_room_story.gd")
const Comms = preload("res://scripts/story14_comms.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Bot = preload("res://tests/campaign_bot.gd")
const RankBeats = preload("res://scripts/story/rank19_beats.gd")
const Arcs = preload("res://scripts/story/arc_night1.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(note)

func run() -> void:
	var barks: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/story14-barks.json")).heroes
	var names := ["Kira Venn", "Tor Saalen", "Sgt. Rhal Dax", "Ilsa Myr", "Doc Bren", "Grak Ordo"]
	for hero in names:
		for event in ["opening_contact", "first_wound", "flanked", "recovery", "promotion", "kill", "ally_down"]:
			check(barks.get(hero, {}).get(event, []).size() > 0, "reachable named line %s %s" % [hero,event])
	var stub := Node.new()
	root.add_child(stub)
	var comms := Comms.new(stub)
	for hero in names:
		for event in ["opening_contact", "first_wound", "flanked", "recovery", "promotion", "kill", "ally_down"]:
			comms.bark_number = barks[hero][event].size() - 1
			comms._show(stub, event + "|" + hero, [{"name":hero,"hp":5}])
			check(comms.triggered_named > 0 and comms.text_label.text == barks[hero][event][-1], "combat line displayed %s %s" % [hero,event])
	stub.queue_free()
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/room_story25.json"))
	for row in rows:
		check(row.has("id") and row.has("room") and row.has("done") and row.has("name") and row.has("title") and row.has("text") and row.has("choices") and row.choices.all(func(choice): return choice.has("label") and choice.has("follow")), "room keys " + str(row.get("id", "")))
	for id in ["w29e_gate_watch", "w29e_branch_watch", "w29e_envoy_watch", "w29e_first_loss"]:
		check(rows.any(func(r): return r.id == id and not str(r.text).is_empty() and not r.choices.is_empty()), "room line " + id)
	var rank_campaign := Campaign.new()
	RankBeats.on_rank(rank_campaign.state, rank_campaign.state.roster[0], 1, 2)
	check(str(RankBeats.next(rank_campaign.state).text).contains(barks["Kira Venn"].promotion[0]), "promotion line enters Temple record")
	var camp := Campaign.new()
	var story := Story.new(camp.state)
	var s: Dictionary = camp.state
	var first := story.start_debrief({"mission_id":"relay","won":true,"units":[{"id":"kira","kills":1,"hp":4,"max_hp":5}]})
	check(first.text.contains("Kira held the gate") and s.w29e_events.get("kira_gate", false), "in mission kill resolves Kira gate beat")
	var arc_rows: Array = story.table("N1_ARCS")
	s.personal_arcs.arc_0 = 2
	s.story.done = 6
	check(Arcs.next_talk(s, [arc_rows[0]]).get("kind", "") == "arc_resolution", "Kira resolution unlocked by field action")
	s.personal_arcs.arc_0 = 0
	s.story.done = 1
	story.start_briefing("rescue")
	check(s.w29e_reserved.has("s11_01"), "mission two reserves first relationship beat")
	check(Room.due(camp,"comms").get("id","") == "comms_signal", "existing room beat remains")
	s.w25_room_seen = {"comms_signal":true}
	check(Room.due(camp,"comms").get("id","") == "w29e_gate_watch", "mission one follow up")
	var second := story.start_debrief({"mission_id":"rescue","won":true,"units":[{"id":"tor","kills":0,"hp":5,"max_hp":5}],"saved_by":{"kira":"tor"}})
	check(second.text.contains("captive gives Kira") and second.text.contains("Tor got a squadmate standing") and s.w29e_events.get("tor_action",false), "rescue debrief and Tor recovery consequence")
	s.personal_arcs.arc_1 = 2
	s.story.done = 6
	check(Arcs.next_talk(s, [arc_rows[1]]).get("kind", "") == "arc_resolution", "Tor resolution unlocked by recovery action")
	s.personal_arcs.arc_1 = 0
	s.story.done = 2
	s.w25_room_seen = {"archives_lamp":true}
	check(Room.due(camp,"archives").get("id","") == "w29e_branch_watch", "mission two follow up")
	var envoy := story.start_briefing("envoy")
	check(envoy.text.contains("captive heard the envoy") and not envoy.text.contains("recovered records carry"), "rescue Envoy bridge")
	check(s.w29e_reserved.has("s11_02") and story.journal(s).squad.any(func(line): return str(line).contains("heard before deployment")), "milestone relationship beat reserved")
	var third := story.start_debrief({"mission_id":"envoy","won":true,"units":[]})
	check(not third.is_empty(), "third mission debrief")
	check(story.journal(s).squad.any(func(line): return str(line).contains("missed at the Temple")), "missed optional scene reaches journal")
	s.w25_room_seen = {"council_window":true}
	check(Room.due(camp,"council").get("id","") == "w29e_envoy_watch", "mission three follow up")
	s.roster[0].status = "dead"
	s.w25_room_seen = {"memorial_name":true}
	check(Room.due(camp,"memorial").get("id","") == "w29e_first_loss", "first casualty follow up")
	var path := "user://story29-save.json"
	check(camp.save(path), "campaign state saved")
	var loaded := Campaign.new()
	check(loaded.load_save(path) and loaded.state.w29e_events.get("rescue_saved",false) and loaded.state.w29e_events.get("tor_action",false) and loaded.state.w29e_reserved.has("s11_02"), "early flags load")
	var archive := Story.new()
	check(archive.start_debrief({"mission_id":"archive","won":true,"units":[]}).text.contains("Ilsa finds the envoy's cipher"), "archive debrief bridge")
	check(archive.start_briefing("envoy").text.contains("recovered records carry the envoy") and not archive.state.w29e_events.get("rescue_saved",false), "archive Envoy bridge")
	archive.state.personal_arcs.arc_0 = 2
	archive.state.story.done = 6
	check(Arcs.next_talk(archive.state, [arc_rows[0]]).is_empty(), "unearned Kira resolution waits for field action")
	check(archive.journal(archive.state).arcs.any(func(line): return str(line).contains("Kira must clear a path")), "journal explains field gate")
	var rescue_loss := Story.new()
	check(rescue_loss.start_debrief({"mission_id":"rescue","won":false,"units":[]}).text.contains("captive was lost"), "rescue loss consequence")
	var archive_loss := Story.new()
	check(archive_loss.start_debrief({"mission_id":"archive","won":false,"units":[]}).text.contains("records were lost"), "archive loss consequence")
	var fallen := Story.new()
	fallen.state.story.done = 1
	fallen.state.roster[0].status = "dead"
	var fallen_brief: Dictionary = fallen.start_briefing("rescue")
	check(not fallen_brief.text.contains("The docking ring is quiet") and fallen.journal(fallen.state).squad.any(func(line): return str(line).contains("missed before deployment")), "fallen speaker scene journals without playing")
	if OS.get_cmdline_user_args().has("--bot-count"): count_bot_lines(barks)
	if OS.get_cmdline_user_args().has("--capture"): await capture_evidence()
	print("Story29: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func count_bot_lines(barks: Dictionary) -> void:
	var before := 0
	var after := 0
	for mission_id in ["relay", "rescue", "envoy"]:
		var camp := Campaign.new("normal")
		camp.state.options = [{"mission":mission_id,"map_variant":0,"adv":false}]
		camp.select_mission(0)
		var m = Battle.create(camp, 1)
		var snapshots: Dictionary = {}
		var first_wounds: Dictionary = {}
		var earlier_enemies: int = m.living("enemy").size()
		var earlier_done := 0
		for unit in m.living("player"):
			snapshots[str(unit.get("rid", unit.get("id", "")))] = {"hp":int(unit.get("hp", 0)),"kills":int(unit.get("kills", 0))}
		for turn in 60:
			if m.result != "": break
			if turn == 0:
				for unit in m.living("player"):
					if barks.has(str(unit.get("name", ""))): before += 1; after += 1; break
			Bot.turn(m)
			for unit in m.units:
				if str(unit.get("side", "")) != "player": continue
				var name := str(unit.get("name", ""))
				if not barks.has(name): continue
				var id := str(unit.get("rid", unit.get("id", "")))
				var hp := int(unit.get("hp", 0))
				var kills := int(unit.get("kills", 0))
				if snapshots.has(id):
					var previous: Dictionary = snapshots[id]
					if kills > int(previous.kills):
						before += kills - int(previous.kills) if not barks[name].get("kill", []).is_empty() else 0
						after += kills - int(previous.kills)
					if hp < int(previous.hp) and hp > 0 and not first_wounds.has(id):
						first_wounds[id] = true; after += 1
					if hp > int(previous.hp): after += 1
					if hp <= 0 and int(previous.hp) > 0: before += 1; after += 1
				snapshots[id] = {"hp":hp,"kills":kills}
			var enemies: int = m.living("enemy").size()
			var done: int = m.objective_state.get("done", {}).size()
			if earlier_enemies > 1 and enemies == 1: before += 1; after += 1
			if done > earlier_done: before += 1; after += 1
			earlier_enemies = enemies; earlier_done = done
		print("STORY29 BOT %s %s turns %d" % [mission_id, m.result, m.turn])
	print("STORY29 NAMED TRIGGERS before %d after %d" % [before, after])
	check(after >= 12 and after > before, "three mission named line target")

func shot(label: String) -> void:
	for i in 10: await process_frame
	var path := "/home/jess/projects/tw-logs/w29/story29/" + label + ".png"
	check(root.get_texture().get_image().save_png(path) == OK, "capture " + label)

func capture_evidence() -> void:
	print("STORY29 CAPTURE start")
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	var flow := root.get_node("CampaignFlow")
	flow.campaign = Campaign.new()
	flow.story = Story.new(flow.campaign.state)
	flow.campaign.state.options = [{"mission":"relay","map_variant":0,"adv":false}]
	flow.campaign.select_mission(0)
	flow.campaign.state.flow_stage = "battle"
	flow.active = true
	var battle: Node3D = preload("res://scenes/rescue.tscn").instantiate()
	root.add_child(battle)
	print("STORY29 CAPTURE battle added")
	current_scene = battle
	for i in 12: await process_frame
	var radio := Comms.new(battle)
	radio._show(battle, "contact|Kira Venn", [{"name":"Kira Venn","hp":5}])
	print("STORY29 CAPTURE bark shown")
	await shot("story29-before-844x390")
	radio._show(battle, "first_wound|Kira Venn", [{"name":"Kira Venn","hp":3}])
	await shot("story29-mission1-bark-844x390")
	battle.queue_free()
	await process_frame
	flow.active = false
	flow.campaign = Campaign.new()
	flow.story = Story.new(flow.campaign.state)
	flow.campaign.state.story.done = 1
	var room_host := Control.new()
	room_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(room_host)
	current_scene = room_host
	var room := Room.new()
	room_host.add_child(room)
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/room_story25.json"))
	for row in rows:
		if row.id == "w29e_gate_watch": room.present(flow, row.duplicate(true)); break
	await shot("story29-room-followup-844x390")
	room_host.queue_free()
	await process_frame
	var scenarios := ["rescue", "archive"]
	for branch in scenarios:
		var engine := Story.new()
		engine.start_debrief({"mission_id":branch,"won":true,"units":[]})
		var briefing: Dictionary = engine.start_briefing("envoy").duplicate(true)
		for paragraph in str(briefing.text).split("\n\n"):
			if paragraph.contains("captive heard the envoy") or paragraph.contains("recovered records carry the envoy"):
				briefing.text = paragraph
				break
		var page: Control = preload("res://scenes/briefing.tscn").instantiate()
		root.add_child(page)
		current_scene = page
		page.show_scene(briefing)
		page._reveal()
		for i in 4: await process_frame
		var scrollers: Array = page.find_children("*", "ScrollContainer", true, false)
		if not scrollers.is_empty():
			scrollers[0].ensure_control_visible(page.narrative)
			for i in 2: await process_frame
		await shot("story29-envoy-" + branch + "-844x390")
		page.queue_free()
		await process_frame
	DisplayServer.window_set_size(Vector2i(390, 844))
	root.size = Vector2i(390, 844)
	root.content_scale_size = root.size
	flow.campaign = Campaign.new()
	flow.story = Story.new(flow.campaign.state)
	flow.campaign.state.options = [{"mission":"relay","map_variant":0,"adv":false}]
	flow.campaign.select_mission(0)
	flow.campaign.state.flow_stage = "battle"
	flow.active = true
	var portrait_battle: Node3D = preload("res://scenes/rescue.tscn").instantiate()
	root.add_child(portrait_battle)
	current_scene = portrait_battle
	for i in 12: await process_frame
	var portrait_radio := Comms.new(portrait_battle)
	var alerts = portrait_battle.hud_controls.phone.alerts
	alerts.queue.clear(); alerts.remaining = 0.0
	portrait_radio._show(portrait_battle, "contact|Kira Venn", [{"name":"Kira Venn","hp":5}])
	await shot("story29-before-390x844")
	alerts.queue.clear(); alerts.remaining = 0.0
	portrait_radio._show(portrait_battle, "first_wound|Kira Venn", [{"name":"Kira Venn","hp":3}])
	await shot("story29-mission1-bark-390x844")
	portrait_battle.queue_free()
	await process_frame
	flow.active = false
	flow.campaign = Campaign.new()
	flow.story = Story.new(flow.campaign.state)
	flow.campaign.state.story.done = 1
	var portrait_host := Control.new()
	portrait_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(portrait_host)
	current_scene = portrait_host
	var portrait_room := Room.new()
	portrait_host.add_child(portrait_room)
	for row in rows:
		if row.id == "w29e_gate_watch": portrait_room.present(flow, row.duplicate(true)); break
	await shot("story29-room-followup-390x844")
	portrait_host.queue_free()
	await process_frame
