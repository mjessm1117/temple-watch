extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Strategy = preload("res://scripts/w25_galaxy_strategy.gd")
const Phone = preload("res://scripts/phone_layout.gd")
class ScanCampaign extends "res://scripts/campaign/state.gd":
	var calls := 0
	var interrupt_on := 0
	func advance_strategy_day25(days: int, _reason: String) -> Dictionary:
		calls += 1
		advance_days(days)
		return {"days_advanced": days, "events": ["incoming signal"] if calls == interrupt_on else []}

var checks := 0
var failures := 0

func check(ok: bool, name: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(name)

func frames(n: int = 8) -> void:
	for i in n: await process_frame

func run() -> void:
	var capture := "--capture" in OS.get_cmdline_user_args()
	var c := ScanCampaign.new()
	Strategy.ensure(c.state)
	check(c.state.w25_contacts == ["outer"], "Only home contacted by default")
	check(Strategy.active_scans(c.state).size() == 3, "Three map scans active")
	var site: Dictionary = Strategy.active_scans(c.state)[0]
	var start_day := int(c.state.elapsed_days)
	var start_intel := int(c.state.res.intel)
	var receipt := Strategy.scan(c, str(site.id))
	check(int(receipt.days_advanced) == int(site.days) and c.calls == int(site.days), "Scan commits each day through contract")
	check(int(c.state.elapsed_days) == start_day + int(site.days), "Scan advances strategy clock")
	check(int(c.state.res.intel) == start_intel + int(site.reward.intel), "Completed scan pays reward")
	check(Strategy.active_scans(c.state).size() == 3 and not Strategy.active_scans(c.state).has(site), "Completed site rotates out")
	c.interrupt_on = c.calls + 1
	var interrupted := Strategy.scan(c, str(Strategy.active_scans(c.state)[0].id))
	check(int(interrupted.days_advanced) == 1 and not interrupted.events.is_empty(), "Event interrupts scan")
	check(c.state.w25_scans_done.size() == 1, "Interrupted scan has no payout")
	check(int(c.state.w25_scan_progress.get("outer_cache",0)) == 1, "Interrupted scan saves progress")
	c.interrupt_on = 0
	var resumed := Strategy.scan(c,"outer_cache")
	check(int(resumed.days_advanced) == 2 and c.state.w25_scans_done.has("outer_cache"), "Scan resumes with remaining days")
	var absent := Strategy.scan(Campaign.new(),str(site.id))
	check(int(absent.days_advanced) == 0, "Absent time contract is safe")
	var poor := Campaign.new()
	poor.state.res.intel = 10; poor.state.res.credits = 500
	check(Strategy.make_contact(poor,"mid"), "Contact spends resources")
	check(not Strategy.make_contact(poor,"core"), "Two-slot contact cap enforced")
	check(poor.state.w25_contacts.size() == 2, "Contact count persisted")
	poor.state.staff.comms = "u1"
	check(Strategy.contact_capacity(poor.state) == 3 and Strategy.make_contact(poor,"core"), "Comms staff adds read-only slot")
	var income_before := int(poor.state.res.credits)
	poor.state.month = 2
	check(Strategy.settle_months(poor) == Strategy.monthly_income(poor.state), "Contacted regions add monthly income")
	check(int(poor.state.res.credits) == income_before + Strategy.monthly_income(poor.state), "Monthly income paid")
	var save_path := "user://galaxy25-contact-%d.json" % OS.get_process_id()
	check(poor.save(save_path), "Contact state saves")
	var loaded := Campaign.new()
	check(loaded.load_save(save_path) and loaded.state.w25_contacts.size() == 3, "Contact state survives load")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var revealer := Campaign.new()
	Strategy.ensure(revealer.state)
	revealer.state.sith.ops[0].revealed = false
	var concealed: Dictionary = revealer.sith.operations()[0]
	var op_region := Strategy.operation_region(revealer,concealed)
	check(str(Strategy.operation_display(revealer,concealed).n) == "Concealed operation", "Uncontacted Sith operation stays concealed")
	revealer.state.w25_leads.append("scan_lead")
	check(str(Strategy.operation_display(revealer,concealed).n) != "Concealed operation", "Scan lead reveals a Sith operation")
	revealer.state.w25_leads.clear()
	revealer.state.res.intel = 10; revealer.state.res.credits = 500
	check(Strategy.make_contact(revealer,op_region), "Can contact operation region")
	check(str(Strategy.operation_display(revealer,concealed).n) != "Concealed operation", "Contact reveals Sith operation")
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://galaxy25-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story
	for dims in [Vector2i(390,844), Vector2i(844,390), Vector2i(1366,768)]:
		flow.campaign = ScanCampaign.new() if dims.x == 390 else Campaign.new()
		flow.story = flow.campaign.story
		Phone.test_scale = 3.0 if dims.x != 1366 else 1.0
		Phone.test_touch = 1 if dims.x != 1366 else 0
		Phone.test_mobile = 1 if dims.x != 1366 else 0
		var stage := SubViewport.new(); stage.size = dims; stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS if capture else SubViewport.UPDATE_DISABLED
		root.add_child(stage)
		var view = load("res://scenes/galaxy.tscn").instantiate(); stage.add_child(view)
		await frames(12)
		check((view.deadline_rail.visible and view.deadline_rail.text.contains("ESCALATION")) or view.contact_action.text.contains("SITH"), "Threat countdown visible %s" % dims)
		check(view.contact_action.visible and view.contact_action.custom_minimum_size.y >= 44, "Contact choice above map %s" % dims)
		var contact_rect: Rect2 = view.contact_action.get_global_rect()
		check(contact_rect.position.x >= 0 and contact_rect.end.x <= dims.x and contact_rect.position.y >= 0 and contact_rect.end.y <= dims.y and contact_rect.size.y >= 44, "Contact action fits viewport %s" % dims)
		if dims.x == 390:
			check(view.map_view.scans.size() == 3, "Portrait scan sites visible")
			var before_day := int(flow.campaign.state.elapsed_days)
			var before_intel := int(flow.campaign.state.res.intel)
			var tap_start := Time.get_ticks_usec()
			view._scan_site_open("outer_relay")
			var tap_ms := float(Time.get_ticks_usec() - tap_start) / 1000.0
			check(tap_ms <= 100.0, "Scan tap responds within 100 ms")
			if capture: print("GALAXY25 TAP scan_open=%.2f ms" % tap_ms)
			await frames(2)
			if capture:
				await frames(15); await RenderingServer.frame_post_draw
				check(stage.get_texture().get_image().save_png("/home/jess/projects/tw-logs/w25/galaxy/after-scan-390x844.png") == OK, "Scan image saved")
			var commit: Button = view.find_child("ScanCommit25",true,false)
			var scan_rect: Rect2 = commit.get_global_rect() if commit != null else Rect2()
			check(commit != null and not commit.disabled and scan_rect.size.y >= 44 and scan_rect.position.x >= 0 and scan_rect.end.x <= dims.x and scan_rect.position.y >= 0 and scan_rect.end.y <= dims.y, "Portrait Scan here fits viewport")
			commit.pressed.emit(); await frames(3)
			check(int(flow.campaign.state.elapsed_days) == before_day + 2 and int(flow.campaign.state.res.intel) == before_intel + 2, "Portrait scan commits and pays")
			check(view.deadline_rail.visible and view.deadline_rail.text.contains("DAY 2"), "Threat countdown remains visible after scan")
			view._overview(); await frames(2)
		else: check(view.map_view.scans.is_empty(), "Scan hidden without contract")
		var rail_rect: Rect2 = view.deadline_rail.get_global_rect()
		if view.deadline_rail.visible: check(rail_rect.position.y >= 0 and rail_rect.end.y <= dims.y, "Deadline rail inside viewport %s" % dims)
		if capture:
			await frames(25)
			await RenderingServer.frame_post_draw
			check(stage.get_texture().get_image().save_png("/home/jess/projects/tw-logs/w25/galaxy/after-overview-%dx%d.png" % [dims.x,dims.y]) == OK, "Overview image saved")
		view._select(0); await frames(4)
		if capture:
			await frames(25)
			await RenderingServer.frame_post_draw
			check(stage.get_texture().get_image().save_png("/home/jess/projects/tw-logs/w25/galaxy/after-selected-%dx%d.png" % [dims.x,dims.y]) == OK, "Selected image saved")
			print("GALAXY25 PERF %dx%d: draws=%d tris=%d" % [dims.x,dims.y,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))])
		if dims.x == 390:
			check(view.region_strip.visible and view.region_strip.get_child_count() > 0, "Portrait keeps region strip")
			check(view.selected_forecast.text.contains("THREAT") and view.selected_forecast.text.contains("REWARD") and view.selected_forecast.text.contains("DEADLINE"), "Selected threat, reward and deadline chips visible")
			check(view.selected_forecast.get_global_rect().end.y <= dims.y, "Selected deadline and reward inside viewport")
			check(view.detail_panel.visible and view.map_view.visible, "Map and selection coexist")
			flow.campaign.set("interrupt_on",int(flow.campaign.get("calls"))+1)
			view._scan_site_open("outer_cache"); await frames(2)
			view._scan_commit25(); await frames(2)
			check(view.page == "Event" and view.scan_feedback.contains("paused"), "Portrait interrupt opens event result")
			check(view.detail.get_child_count() > 2 and str(view.detail.get_child(0).text).contains("INTERRUPTED"), "Event result is above the fold")
			view._overview(); await frames(2)
			check(view.selected == 0 and str(flow.campaign.state.w25_selected_mission_id) != "", "Back keeps selection")
		view.open_intel_view25(); check(view.page == "Intel", "Comms can open Intel workbench")
		if capture and dims.x == 390:
			await frames(15); await RenderingServer.frame_post_draw
			check(stage.get_texture().get_image().save_png("/home/jess/projects/tw-logs/w25/galaxy/after-intel-390x844.png") == OK, "Intel image saved")
		view.queue_free(); await frames(2); stage.free()
	Phone.test_scale = 3.0; Phone.test_touch = 1; Phone.test_mobile = 1
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story
	change_scene_to_file("res://scenes/galaxy.tscn"); await frames(12)
	var round_trip = current_scene
	check(round_trip.campaign.state.options.size() > 1, "Round trip has another mission")
	if round_trip.campaign.state.options.size() > 1:
		round_trip._select(1)
		var chosen_id := str(round_trip.campaign.state.options[1].mission)
		var chosen_region: String = round_trip.campaign.region_for_mission(chosen_id)
		if chosen_region != "" and not Strategy.contacted(round_trip.campaign.state,chosen_region): round_trip.campaign.state.w25_contacts.append(chosen_region)
		round_trip._launch()
		await create_timer(0.8).timeout
		check(int(flow.campaign.state.get("launch_index",-1)) == 1, "Ready fallback opens today's Briefing")
		flow.back_from_briefing(); await create_timer(0.8).timeout
		check(current_scene != null and current_scene.has_method("open_intel_view25") and current_scene.selected == 1, "Briefing Back restores selected mission")
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("Galaxy25: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func _initialize() -> void:
	call_deferred("run")
