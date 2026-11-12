extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Classes = preload("res://scripts/class_registry.gd")
const OUT = "/home/jess/projects/tw-logs/w28/tree/"
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CLASS_TREE28: " + message)

func resize_to(value: Vector2i) -> void:
	DisplayServer.window_set_size(value)
	root.size = value; root.content_scale_size = value
	for i in 3: await process_frame

func touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0; event.position = at; event.pressed = pressed
	root.push_input(event, true)

func drag(from: Vector2, to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0; event.position = to; event.relative = to - from
	root.push_input(event, true)

func inspect_case(flow, value: Vector2i, label: String) -> void:
	await resize_to(value)
	var screen = load("res://scenes/squad.tscn").instantiate()
	root.add_child(screen)
	for i in 3: await process_frame
	var index: int = screen.selected.find("u1")
	check(index >= 0, label + " unit in squad")
	if index < 0:
		screen.queue_free(); await process_frame; return
	screen.inspect(index); screen._tab_armory_skills()
	for i in 3: await process_frame
	var tree = screen.arsenal.picker.get_node_or_null("SkillTree")
	check(tree != null, label + " tree shown")
	if tree == null:
		screen.queue_free(); await process_frame; return
	var r: Dictionary = flow.campaign.soldier("u1")
	var side_name := "jedi" if Progression.is_jedi(r) else "soldier"
	var maximum := Classes.ranks(side_name).size()
	check(tree.rows.size() == maximum, label + " every rank shown")
	check(not tree.get_node("RankColumns").has_node("LaterRanks"), label + " no placeholder")
	for rank in range(1, maximum + 1):
		var row: Control = tree.rows[rank]
		var title: Label = row.get_node("Tier")
		check(title.text.contains(str(Classes.rank_data(side_name, rank).tier).to_upper()), label + " tier %d named" % rank)
		check(row.get_rect().size.y >= 44, label + " row %d at least 44 px" % rank)
		for card in row.get_node("Pair%d" % rank).get_children():
			check(card.custom_minimum_size.y >= 44, label + " card %d at least 44 px" % rank)
			check(card.find_child("Description", true, false) != null and card.find_child("Chain", true, false) != null, label + " description and chips %d" % rank)
			var reason: Label = card.find_child("LockReason", true, false)
			if rank > int(r.rank): check(reason.text.begins_with("Reach "), label + " rank %d lock reason" % rank)
			if str(card.name).trim_prefix("Skill_") in r.picks: check(reason.text == "PICKED", label + " prior pick shown")
	if label == "recruit":
		for card in tree.rows[1].get_node("Pair1").get_children(): check(not card.disabled, "rank 1 open")
	if label == "promotion":
		var promotion_card: Button = tree.rows[4].get_node("Pair4").get_child(0)
		check(not promotion_card.disabled, "rank 4 promotion remains open after deploy")
		tree._preview(4, str(promotion_card.name).trim_prefix("Skill_"))
		check(tree.selected_rank == 4 and not tree.confirm.disabled, "rank 4 preview uses progression choice")
	if label == "jedi": check(maximum == 8, "Jedi has eight tiers")
	if label == "recruit" and value.x == 390:
		var scroll: ScrollContainer = screen.arsenal.get_parent()
		var first: Button = tree.rows[1].get_node("Pair1").get_child(0)
		check(first.mouse_filter == Control.MOUSE_FILTER_PASS, "card passes touch drag")
		var center := first.get_global_rect().get_center()
		var selected: String = tree.selected_key
		touch(center, true)
		var last := center
		for step in 8:
			var next := center + Vector2(0, -12 * (step + 1))
			drag(last, next); last = next; await process_frame
		touch(last, false); await process_frame
		check(scroll.scroll_vertical > 0, "drag starting on row scrolls")
		check(tree.selected_key == selected, "drag does not select ability")
	if "--capture" in OS.get_cmdline_user_args():
		for i in 6: await process_frame
		check(root.get_texture().get_image().save_png(OUT + "after-%s-%dx%d.png" % [label, value.x, value.y]) == OK, "capture " + label)
	screen.queue_free(); await process_frame

func run() -> void:
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", true)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://class-tree28-test.json"
	flow.campaign = Campaign.new("normal"); flow.story = flow.campaign.story; flow.active = true
	var r: Dictionary = flow.campaign.soldier("u1")
	r.cls = "Trooper"; r.rank = 1; r.skill_rank = 1; r.picks = []; r.spec = ""
	await inspect_case(flow, Vector2i(390, 844), "recruit")
	await inspect_case(flow, Vector2i(844, 390), "recruit")
	r.rank = 4; r.skill_rank = 4
	for rank in range(1, 4):
		var options: Array = Progression.tree_options(r, rank)
		check(not options.is_empty() and Progression.choose(r, str(options[0])), "soldier picks rank %d" % rank)
	flow.campaign.state.skill_picks_locked = true
	await inspect_case(flow, Vector2i(390, 844), "promotion")
	r.rank = 7; r.skill_rank = 7
	for rank in range(4, 8):
		var options: Array = Progression.tree_options(r, rank)
		check(not options.is_empty() and Progression.choose(r, str(options[0])), "soldier picks rank %d" % rank)
	await inspect_case(flow, Vector2i(390, 844), "soldier")
	r.cls = "Guardian"; r.rank = 8; r.skill_rank = 8; r.picks = []; r.spec = ""
	for rank in range(1, 9):
		var options: Array = Progression.tree_options(r, rank)
		check(not options.is_empty() and Progression.choose(r, str(options[0])), "Jedi picks rank %d" % rank)
	await inspect_case(flow, Vector2i(390, 844), "jedi")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("CLASS_TREE28 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
