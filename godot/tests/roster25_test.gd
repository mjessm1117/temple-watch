extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const People = preload("res://scripts/w25_roster_people.gd")
const Squad = preload("res://scripts/campaign/squad.gd")
const Roster = preload("res://scripts/campaign/strat_roster.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("ROSTER25 " + label)

func run() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://roster25.json"
	flow.campaign = Campaign.new("normal"); flow.story = flow.campaign.story; flow.active = true
	var c = flow.campaign
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("/home/jess/projects/tw-logs/w25/audit/mid-save.json"))
	c.state = fixture.C
	check(int(c.state.roster[0].fatigue) == 80 and int(c.state.roster[2].fatigue) == 80, "audit mid save loaded")
	c.state.roster[3].wound = 6
	var groups: Dictionary = People.groups(c)
	check(groups.Tired.size() >= 3 and groups.Wounded.size() == 1, "fixture groups")
	check(groups.Tired[0].eta > 0 and groups.Wounded[0].eta > 0, "return ETA")
	var best: Array = People.best_ready(c, 5)
	for id in best: check(People.group(c.soldier(id)) == "Ready", "best ready skips ineligible")
	c.state.facility.relay = maxi(int(c.state.facility.relay), ceili(float(Base.power(c.state).used - 8) / 4.0))
	var patient_id := str(c.state.roster[3].id)
	var choices: Array = People.patient_actions(c, patient_id)
	check(choices.size() == 3 and choices[0].id == "rest" and choices[1].id == "standard" and choices[1].enabled, "real patient choices")
	check(Roster.patient_actions25(c, patient_id).size() == 3, "economy patient contract")
	check(People.apply_patient(c, patient_id, "rest"), "rest through campaign state")
	flow.save()
	check(str(FileAccess.get_file_as_string(flow.save_path)).contains('"assign":"rest"'), "patient action saved")
	c.state.facility.workers.remove_at(2)
	c.soldier(patient_id).wound = 10
	var before_healer_eta := People.eta(c, c.soldier(patient_id))
	var old_credits := int(c.state.res.credits)
	var old_recruits := int(c.state.res.recruits)
	check(People.patient_actions(c, patient_id)[2].enabled, "healer trade available")
	check(People.apply_patient(c, patient_id, "healer"), "healer assigned through staff calls")
	check(int(c.state.res.credits) == old_credits - 75 and int(c.state.res.recruits) == old_recruits - 1 and Base.staff_count(c.state, "medical") == 1, "healer cost and recovery staff saved in state")
	check(People.eta(c, c.soldier(patient_id)) < before_healer_eta, "healer speeds recovery")
	flow.save()
	check(str(FileAccess.get_file_as_string(flow.save_path)).contains('"wing":"medical"'), "healer assignment saved")
	var soldier_id := str(c.state.roster[6].id)
	var before_stats: Dictionary = Gear.battle_stats(c, soldier_id)
	var delta: Array = People.delta(c, soldier_id, {"action":"armor", "key":"armoredRobes"})
	check(not delta.is_empty(), "armor delta exists")
	check(People.delta(c, soldier_id, "armoredRobes") == delta, "item ID contract resolves armor")
	var original_armor: String = str(c.soldier(soldier_id).gear.armor)
	c.soldier(soldier_id).gear.armor = "armoredRobes"
	var after_stats: Dictionary = Gear.battle_stats(c, soldier_id)
	c.soldier(soldier_id).gear.armor = original_armor
	for entry in delta:
		var field: String = {"HP":"hp", "move":"mob"}.get(str(entry.stat), str(entry.stat))
		check(entry.before == before_stats.get(field, 0) and entry.after == after_stats.get(field, 0), "delta %s exact values" % entry.stat)
	var contract_screen := Squad.new()
	check(contract_screen.has_method("open_from_temple") and contract_screen.has_method("patient_actions25") and contract_screen.has_method("loadout_delta25"), "cross lane contracts")
	contract_screen.free()
	var initial_viewport: Vector2i = DisplayServer.window_get_size()
	var viewports := [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1366, 768)]
	if initial_viewport in viewports:
		viewports.erase(initial_viewport); viewports.push_front(initial_viewport)
	if "--capture" in OS.get_cmdline_user_args(): viewports = [initial_viewport]
	for viewport in viewports:
		DisplayServer.window_set_size(viewport)
		root.size = viewport; root.content_scale_size = viewport
		Phone.test_window_size = viewport
		for i in 2: await process_frame
		var screen = load("res://scenes/squad.tscn").instantiate()
		screen.from_temple = true; screen.temple_focus = "loadout"; screen.temple_soldier_id = soldier_id
		root.add_child(screen)
		screen.size = viewport; screen._layout()
		for i in 4: await process_frame
		check(screen.arsenal.active_slot == "weapon" and screen.arsenal.offers.any(func(offer): return offer.slot == "weapon" and offer.card.visible), "Temple Equip third tap can choose weapon %s" % viewport)
		var actor_rect: Rect2 = screen.stage_container.get_global_rect()
		check(actor_rect.size.y + 0.1 >= viewport.y * 0.45, "actor height %s: %s" % [viewport, actor_rect])
		check(viewport.x < 500 or actor_rect.end.x <= viewport.x * 0.5, "actor left half %s" % viewport)
		check(Rect2(Vector2.ZERO, viewport).encloses(screen.drawer.get_global_rect()), "drawer inside %s: %s" % [viewport, screen.drawer.get_global_rect()])
		check(Rect2(Vector2.ZERO, viewport).encloses(screen.footer.get_global_rect()), "Back footer inside %s: %s" % [viewport, screen.footer.get_global_rect()])
		for slot in screen.arsenal.slot_row.get_children():
			if slot.visible: check(slot.get_global_rect().size.x >= 44 and slot.get_global_rect().size.y >= 44, "slot target %s" % viewport)
		if "--capture" in OS.get_cmdline_user_args() and viewport == initial_viewport and root.get_texture() != null:
			await create_timer(0.25).timeout
			DirAccess.make_dir_recursive_absolute("/home/jess/projects/tw-logs/w25/roster")
			root.get_texture().get_image().save_png("/home/jess/projects/tw-logs/w25/roster/after-%s.png" % str(viewport).replace("(", "").replace(")", "").replace(", ", "x"))
			for tab in ["roster", "medical"]:
				screen._tab(tab)
				for i in 3: await process_frame
				root.get_texture().get_image().save_png("/home/jess/projects/tw-logs/w25/roster/after-%s-%s.png" % [tab, str(viewport).replace("(", "").replace(")", "").replace(", ", "x")])
		screen.queue_free()
		for i in 2: await process_frame
	print("ROSTER25: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
