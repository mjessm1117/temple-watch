extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Classes = preload("res://scripts/class_registry.gd")
const Promotion = preload("res://scripts/campaign/promotion_screen.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("C30: " + message)

func prepared_campaign():
	var campaign = Campaign.new()
	var jedi: Dictionary = campaign.soldier("u1")
	jedi.cls = "Guardian"
	jedi.rank = 4
	jedi.skill_rank = 4
	jedi.picks = []
	jedi.spec = ""
	for rank in range(1, 5):
		var options := Progression.tree_options(jedi, rank)
		check(not options.is_empty() and Progression.choose(jedi, str(options[0])), "prepare rank %d" % rank)
	jedi.xp = int(Classes.ranks("jedi")[4].xp)
	check(Progression.promote(jedi, campaign.state.roster) and jedi.rank == 5, "rank 4 Jedi promotes to rank 5")
	jedi.pick = Progression.pending_rank(jedi)
	check(jedi.pick == 5, "Jedi awaits rank 5 choice")
	return campaign

func resize_to(value: Vector2i) -> void:
	DisplayServer.window_set_size(value)
	root.content_scale_factor = 1.0
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = value
	Phone.test_window_size = value
	for i in 3: await process_frame

func run() -> void:
	for value in [Vector2i(956, 440), Vector2i(844, 390), Vector2i(390, 844)]:
		await resize_to(value)
		var campaign = prepared_campaign()
		var flow := root.get_node("CampaignFlow")
		flow.campaign = campaign
		flow.save_path = "user://c30-test-save.json"
		flow.active = true
		var jedi: Dictionary = campaign.soldier("u1")
		var original_picks: Array = jedi.picks.duplicate()
		var screen := Promotion.new()
		root.add_child(screen)
		screen.setup(campaign, "u1")
		for i in 6: await process_frame
		var viewport_size := screen.get_viewport_rect().size
		var safe := Phone.safe_margins(viewport_size)
		var done_rect := screen.done_button.get_global_rect()
		var confirm_rect := screen.confirm.get_global_rect()
		var scroll_rect := screen.scroll.get_global_rect()
		var grid: GridContainer = screen.rank_rows[5].get_node("ChoiceGrid")
		print("C30 GEOMETRY %s viewport=%s root=%s screen=%s done=%s confirm=%s scroll=%s card_width=%s safe=%s" % [value, screen.get_viewport_rect().size, root.size, screen.size, done_rect, confirm_rect, scroll_rect, grid.get_child(0).custom_minimum_size.x, safe])
		check(done_rect.size.y >= 44.0 and done_rect.position.x >= safe.x and done_rect.end.x <= viewport_size.x - safe.z and done_rect.end.y <= viewport_size.y - safe.w, "%s DONE clears safe area" % value)
		check(confirm_rect.size.y >= 44.0 and confirm_rect.position.x >= safe.x and confirm_rect.end.x <= viewport_size.x - safe.z and confirm_rect.end.y <= viewport_size.y - safe.w, "%s confirm clears safe area" % value)
		check(scroll_rect.position.x >= safe.x and scroll_rect.end.x <= viewport_size.x - safe.z and scroll_rect.end.y <= viewport_size.y - safe.w, "%s scroll bounds" % value)
		check(grid.columns == 2, "%s two rank choices across" % value)
		for child in grid.get_children():
			var card: Control = child
			var rect := card.get_global_rect()
			check(card.custom_minimum_size.x > 0.0 and rect.position.x >= safe.x and rect.end.x <= viewport_size.x - safe.z, "%s card width and horizontal bounds" % value)
			check(rect.position.y >= scroll_rect.position.y - 1.0 and rect.end.y <= scroll_rect.end.y + 1.0, "%s current choice fully visible" % value)
			if value == Vector2i(844, 390):
				var metric: Label = card.find_child("Metric_*", true, false)
				check(metric != null and metric.get_global_rect().end.y <= rect.end.y, "landscape choice metric visible")
		if value == Vector2i(390, 844):
			var expected_width := minf(220.0, (viewport_size.x - safe.x - safe.z - 24.0 - 16.0 - 4.0) / 2.0)
			check(is_equal_approx(grid.get_child(0).custom_minimum_size.x, expected_width), "portrait responsive card width")
		if DisplayServer.get_name() != "headless":
			var image_path := "/home/jess/projects/tw-logs/w30/c30/promotion-%dx%d.png" % [value.x, value.y]
			check(root.get_texture().get_image().save_png(image_path) == OK, "%s screenshot" % value)
		var options := Progression.tree_options(jedi, 5)
		check(not options.is_empty(), "rank 5 choice available")
		if options.is_empty():
			screen.queue_free(); await process_frame; continue
		var ability_id := str(options[0])
		screen.preview_choice(5, 0)
		check(jedi.picks == original_picks and screen.chosen == ability_id and not screen.confirm.disabled, "preview shown without commit")
		screen.cancel_preview()
		check(jedi.picks == original_picks and screen.chosen == "" and screen.confirm.disabled, "cancel clears preview without commit")
		var events := [0]
		screen.changed.connect(func(): events[0] += 1)
		screen.preview_choice(5, 0)
		screen.confirm.pressed.emit()
		check(jedi.picks.size() == 5 and jedi.picks[4] == ability_id and ability_id in Progression.battle_abilities(jedi), "confirm equips rank 5 ability")
		check(events[0] == 1 and jedi.pick == 0, "confirm emits changed and resolves pending choice")
		var alternate: String = str(Progression.tree_options(jedi, 1)[1])
		check(Progression.set_choice(jedi, 1, alternate, true) and jedi.picks[0] == alternate, "free predeploy respec replaces choice")
		screen.queue_free()
		await process_frame
		var squad = load("res://scenes/squad.tscn").instantiate()
		root.add_child(squad)
		for i in 3: await process_frame
		var index: int = squad.selected.find("u1")
		check(index >= 0, "%s Jedi available in squad" % value)
		if index >= 0:
			squad.inspect(index)
			squad._tab_armory_skills()
			for i in 3: await process_frame
			var tree = squad.arsenal.picker.get_node_or_null("SkillTree")
			check(tree != null, "%s skill tree opens" % value)
			if tree != null:
				var tree_card: Control = tree.rows[5].get_node("Pair5").get_child(0)
				var description: Label = tree_card.find_child("Description", true, false)
				check(tree.comparison.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and tree.comparison.get_global_rect().end.x <= viewport_size.x, "%s comparison wraps within viewport" % value)
				check(description.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and description.max_lines_visible >= 3 and tree_card.size.y >= 136.0, "%s tree card description readable" % value)
				if DisplayServer.get_name() != "headless":
					var tree_path := "/home/jess/projects/tw-logs/w30/c30/tree-%dx%d.png" % [value.x, value.y]
					check(root.get_texture().get_image().save_png(tree_path) == OK, "%s tree screenshot" % value)
		squad.queue_free()
		await process_frame
		if value == Vector2i(390, 844):
			jedi.rank = 3
			jedi.skill_rank = 3
			jedi.picks = jedi.picks.slice(0, 2)
			jedi.spec = ""
			jedi.pick = Progression.pending_rank(jedi)
			var pair_screen := Promotion.new()
			root.add_child(pair_screen)
			pair_screen.setup(campaign, "u1")
			for i in 5: await process_frame
			var pair_grid: GridContainer = pair_screen.rank_rows[3].get_node("ChoiceGrid")
			check(pair_grid.columns == 2 and pair_grid.get_child_count() == 2, "portrait shows both rank 3 options")
			for child in pair_grid.get_children():
				var pair_card: Control = child
				var effect: Label = pair_card.find_child("Effect_" + str(pair_card.name).trim_prefix("Card_"), true, false)
				check(pair_card.get_global_rect().end.x <= viewport_size.x - safe.z and effect.get_global_rect().end.y <= pair_card.get_global_rect().end.y, "portrait option stays visible and text fits")
			pair_screen.queue_free()
			await process_frame
	Phone.test_window_size = Vector2i.ZERO
	print("C30 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
