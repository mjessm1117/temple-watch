extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const Queue = preload("res://scripts/campaign/research_queue.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Resources = preload("res://scripts/campaign/home_resources.gd")
var checks := 0
var failures := 0
var month_rows: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func frames(n: int = 3) -> void:
	for i in n: await process_frame

func run() -> void:
	var c = Campaign.new("normal")
	check(int(c.state.res.credits) >= 250, "first room affordable in month 1")
	var before: Dictionary = c.state.duplicate(true)
	var preview: Dictionary = c.build_preview25("b0", "archives")
	check(preview.valid and int(preview.cost) == 250 and int(preview.power_after) == 5, "preview shows cost and power")
	check(c.state == before, "preview does not spend or place")
	check(c.confirm_build25("b0", "archives") and not c.confirm_build25("b0", "forge"), "confirm reserves one build")
	c.advance_strategy_day25(5, "test construction")
	check(int(c.state.wings.archives) == 1 and int(c.state.month) == 1, "first room finishes in month 1")
	check(c.start_research("ataru") and not c.start_research("djemSo"), "only one active research project")
	check(Queue.enqueue(c, "djemSo") and not Queue.enqueue(c, "djemSo"), "queue excludes duplicate project")
	check(str(c.state.research.cur) == "ataru" and c.state.research.queue.size() == 1, "queue does not start second project")
	var snapshot: Dictionary = c.strategic_snapshot25()
	check(snapshot.has("forecast_month_credits") and snapshot.top_priority.has("room_id"), "forecast and priority contract")
	check(int(snapshot.forecast_month_credits) == int(c.monthly_credits25().net), "forecast matches next stipend less upkeep and pay")
	var forecast_line := Resources.forecast_label(c)
	check(forecast_line.text.ends_with("Cr at month end"), "compact forecast line")
	forecast_line.free()
	var priority = Campaign.new()
	check(priority.strategic_snapshot25().top_priority.room_id == "works", "unbuilt urgent room priority")
	priority.state.wings.archives = 1
	check(priority.strategic_snapshot25().top_priority.room_id == "archives", "idle lab outranks room")
	priority.state.research.cur = "ataru"; priority.state.wings.forge = 1
	check(priority.strategic_snapshot25().top_priority.room_id == "forge", "idle forge priority")
	priority.state.wings.armory = 1
	check(priority.strategic_snapshot25().top_priority.room_id == "works", "power over cap outranks threat")
	c.month_advanced.connect(func(month: int, _snapshot: Dictionary):
		month_rows.append({"month": month, "credits": int(c.state.res.credits), "forecast": int(c.strategic_snapshot25().forecast_month_credits)}))
	var receipts := [140, 150, 160, 145, 155]
	for i in receipts.size():
		var prior_rows := month_rows.size()
		var paid := int(c.apply_mission_result({"mission_id": "relay", "win": true, "units": [], "rewards": {"credits": receipts[i], "favor": 0}}).rewards.credits)
		check(paid == roundi(receipts[i] * 0.48), "mission %d scaled credit receipt" % (i + 1))
		if month_rows.size() > prior_rows:
			check(int(month_rows.back().credits) >= 130 and int(month_rows.back().credits) <= 650, "month %d credits band" % int(month_rows.back().month))
	check(month_rows.size() == 2, "five missions cross two month ends")
	var credits := int(c.state.res.credits)
	check(credits >= 440 and credits < 650, "five-win savings buy about two desired rooms")
	check(credits >= 230 + 220 and credits < 230 + 220 + 200, "two of Forge, Armory and Medical upgrade affordable")
	print("ECONOMY25 MONTH TABLE %s" % JSON.stringify(month_rows))
	print("ECONOMY25 FIVE-WIN CREDITS %d" % credits)

	var old = Campaign.new()
	var newer = Campaign.new()
	old.state.roster[2].wound = 10; newer.state.roster[2].wound = 10
	old.advance_days(15)
	var tick: Dictionary = newer.advance_strategy_day25(15, "scan")
	check(int(tick.days_advanced) == 15 and tick.events is Array, "tick returns days and events")
	check(old.state == newer.state, "legacy 15 days equals strategy tick")
	var path := "user://economy25-old-save.json"
	var legacy: Dictionary = old.state.duplicate(true)
	legacy.erase("elapsed_days"); legacy.research.erase("queue"); legacy.research.erase("last")
	legacy.erase("facility"); legacy.erase("slots")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"v": 2, "C": legacy})); file.close()
	var restored = Campaign.new()
	check(restored.load_save(path), "old save loads")
	check(restored.state.has("elapsed_days") and restored.state.research.has("queue") and restored.state.has("facility"), "old save receives defaults")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	await ui_rects(Vector2i(390, 844))
	await ui_rects(Vector2i(844, 390))
	await ui_rects(Vector2i(1366, 768))
	print("ECONOMY25 RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func ui_rects(size: Vector2i) -> void:
	Phone.test_window_size = size
	var display := SubViewport.new()
	display.size = size; display.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(display)
	var flow = root.get_node("CampaignFlow")
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story
	var temple: Control = load("res://scenes/temple.tscn").instantiate()
	display.add_child(temple)
	await frames()
	if size.x == 390:
		var visible_forecast := false
		for label in temple.find_children("MonthCreditForecast", "Label", true, false):
			if label.is_visible_in_tree() and label.get_global_rect().end.x <= size.x: visible_forecast = true
		check(visible_forecast, "one-line month forecast visible inside portrait header")
	temple._change_page("Build")
	await create_timer(0.45).timeout
	await frames()
	if "--capture" in OS.get_cmdline_user_args():
		scroll_to_heading(temple, "BUILD GRID")
		await shot(display, "build", size)
	var count := 0
	for bay in temple.page_content.find_children("Bay_*", "Button", true, false):
		var rect: Rect2 = bay.get_global_rect()
		if rect.size.x <= 0: continue
		count += 1
		check(rect.position.x >= 0 and rect.end.x <= size.x + 1, "bay %s inside %d px" % [bay.name, size.x])
		check(rect.size.y >= 44, "bay %s touch target" % bay.name)
	check(count > 0, "build bay controls rendered")
	if size.x == 390:
		var bay: Button = temple.page_content.find_child("Bay_b0", true, false)
		var tap_started := Time.get_ticks_msec()
		bay.pressed.emit()
		print("ECONOMY25 BAY TAP %d ms" % (Time.get_ticks_msec() - tap_started))
		await frames()
		var choice: Button
		for item in temple.page_content.find_children("*", "Button", true, false):
			if item.text == "Preview Archives": choice = item; break
		check(choice != null, "select bay reveals room choices")
		if choice != null:
			tap_started = Time.get_ticks_msec()
			choice.pressed.emit()
			print("ECONOMY25 PREVIEW TAP %d ms" % (Time.get_ticks_msec() - tap_started))
			await frames()
			var confirm: Button
			for item in temple.page_content.find_children("*", "Button", true, false):
				if item.text.begins_with("Confirm · 250 Cr"): confirm = item; break
			check(confirm != null and not confirm.disabled, "room preview exposes enabled confirm")
			if "--capture" in OS.get_cmdline_user_args():
				scroll_to_heading(temple, "BUILD PREVIEW")
				await shot(display, "preview", size)
				if confirm != null:
					var rect := confirm.get_global_rect()
					check(rect.size.y >= 44 and rect.position.x >= 0 and rect.end.x <= size.x, "confirm touch rect in portrait")
			if confirm != null:
				confirm.pressed.emit(); await frames()
				check(str(flow.campaign.state.build) == "archives", "confirm starts selected build")
	flow.campaign.state.wings.archives = 1
	flow.campaign.state.build = ""
	flow.campaign.state.research.cur = "ataru"
	flow.campaign.state.research.prog = 5.0
	Base.assign_worker(flow.campaign, "staff1", "archives")
	temple._change_page("Research"); await frames()
	var found_worker := false; var found_unlock := false
	for label in temple.page_content.find_children("*", "Label", true, false):
		if label.text.begins_with("Working: Archivist Sera"): found_worker = true
		if label.text.begins_with("Unlocks: "): found_unlock = true
	check(found_worker and found_unlock, "research panel shows worker, ETA and unlock")
	check(temple.page_content.find_child("FirstStudyButton", true, false) != null, "first study stays visible before list")
	if "--capture" in OS.get_cmdline_user_args(): await shot(display, "research", size)
	if size.x == 390:
		temple._change_page("Roster"); await frames()
		var care_action := false
		for item in temple.page_content.find_children("*", "Button", true, false):
			if item.text == "Recover": care_action = true
		check(care_action, "guarded patient-action fallback keeps Recover available")
	display.queue_free(); Phone.test_window_size = Vector2i.ZERO
	await frames()

func shot(display: SubViewport, name: String, size: Vector2i) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	var dir := "/home/jess/projects/tw-logs/w25/economy"
	DirAccess.make_dir_recursive_absolute(dir)
	check(display.get_texture().get_image().save_png("%s/after-%s-%dx%d.png" % [dir, name, size.x, size.y]) == OK, "capture " + name)

func scroll_to_heading(temple: Control, heading: String) -> void:
	var scroll: ScrollContainer = temple.page_content.get_parent()
	for card in temple.page_content.get_children():
		for label in card.find_children("*", "Label", true, false):
			if label.text.begins_with(heading):
				scroll.scroll_vertical = maxi(0, int(card.position.y) - 12)
				return
