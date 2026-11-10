extends SceneTree
const Phone = preload("res://scripts/phone_layout.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const OUT := "/home/jess/projects/tw-logs/w20/story/"
var checks := 0
var failures := 0
var capture := false
var capture3 := false

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("STORY20: " + label)

func settle() -> void:
	for i in 8: await process_frame

func shot(label: String) -> void:
	if not capture: return
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT + label + ".png") == OK, "capture " + label)

func words(value: String) -> int:
	return value.replace("\n", " ").strip_edges().split(" ", false).size()

func run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	capture3 = "--capture3" in OS.get_cmdline_user_args()
	Phone.test_scale = 3.0; Phone.test_touch = 1; Phone.test_mobile = 1
	check(Phone.narrow(Vector2i(2868, 1320)), "956x440 logical at 3x selects phone layout")
	if capture3:
		DisplayServer.window_set_size(Vector2i(2868, 1320))
		root.content_scale_size = Vector2i(956, 440)
	else:
		Phone.test_scale = 1.0
		DisplayServer.window_set_size(Vector2i(956, 440))
		root.size = Vector2i(956, 440)
		root.content_scale_size = root.size
	await settle()
	var flow := root.get_node("CampaignFlow")
	flow.save_path = "user://story20-%d.json" % OS.get_process_id()
	change_scene_to_file("res://scenes/menu.tscn")
	await settle()
	check(current_scene.scene_file_path.ends_with("menu.tscn"), "title opens")
	await shot("title")
	var resumed := Campaign.new()
	resumed.story.start_briefing("envoy")
	resumed.state.flow_stage = "briefing"
	resumed.state.launch_option = {"mission":"envoy", "story":true}
	check(resumed.save(flow.save_path), "mid-campaign save written")
	flow.continue_campaign()
	await settle()
	check(current_scene.scene_file_path.ends_with("briefing.tscn") and flow.campaign.state.flow_stage == "briefing" and flow.screen.get("id", "") == "envoy", "Continue preserves saved stage")
	flow.go("menu")
	await settle()
	var start_button: Button = current_scene.find_child("StartButton", true, false)
	check(start_button != null and start_button.is_visible_in_tree(), "START is visible")
	start_button.pressed.emit()
	await settle()
	check(current_scene.scene_file_path.ends_with("opening.tscn"), "START opens story before Temple and Sith")
	check(flow.campaign.state.flow_stage == "opening", "opening stage persists")
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/opening.json"))
	var pages: Array = parsed.pages
	var total := 0
	for page in pages: total += words(str(page.text))
	check(pages.size() >= 6 and pages.size() <= 9 and total >= 800 and total <= 1100, "eight paced panels and 800-1100 words")
	check(not flow.show_sith_events(), "Sith intelligence held until first mission ends")
	flow.open_intelligence()
	check(not is_instance_valid(flow.intelligence), "direct Sith panel route held until first mission ends")
	var opening = current_scene
	for i in pages.size():
		opening._show_page(i)
		await settle()
		check(opening.narrative.get_content_height() <= opening.narrative.size.y + 1, "956x440 panel %d fits" % i)
	if not capture3:
		DisplayServer.window_set_size(Vector2i(844, 390))
		root.size = Vector2i(844, 390); root.content_scale_size = root.size
		await settle()
		for i in pages.size():
			opening._show_page(i)
			await settle()
			check(opening.narrative.get_content_height() <= opening.narrative.size.y + 3, "844x390 panel %d fits" % i)
	if not capture:
		Phone.test_touch = 0; Phone.test_mobile = 0
		DisplayServer.window_set_size(Vector2i(1366, 768))
		root.size = Vector2i(1366, 768); root.content_scale_size = root.size
		await settle()
		for i in pages.size():
			opening._show_page(i)
			await settle()
			check(opening.narrative.get_content_height() <= opening.narrative.size.y + 1, "1366x768 panel %d fits" % i)
		Phone.test_touch = 1; Phone.test_mobile = 1
	if not capture3:
		DisplayServer.window_set_size(Vector2i(956, 440))
		root.size = Vector2i(956, 440); root.content_scale_size = root.size
		await settle()
	opening._show_page(0)
	await settle()
	opening.narrative.visible_characters = -1
	check(opening.narrative.get_global_rect().end.y <= opening.actions.get_global_rect().position.y, "opening text area clears actions")
	check(opening.narrative.get_content_height() <= opening.narrative.size.y + 1, "first panel fully readable without scrolling")
	await shot("opening-01")
	opening._show_page(1)
	await settle()
	opening.narrative.visible_characters = -1
	check(opening.narrative.get_content_height() <= opening.narrative.size.y + 1, "second panel fully readable without scrolling")
	await shot("opening-02")
	var skip_button: Button
	for button in opening.find_children("*", "Button", true, false):
		if button.text == "SKIP STORY": skip_button = button
	check(skip_button != null and skip_button.is_visible_in_tree() and skip_button.size.y >= 44, "visible 44 px Skip")
	skip_button.pressed.emit()
	await settle()
	check(current_scene.scene_file_path.ends_with("briefing.tscn"), "Skip reaches first briefing")
	check(str(flow.screen.get("id", "")) == "relay" and words(str(flow.screen.text)) >= 150, "Temple Outer Gate briefing expanded")
	current_scene._reveal()
	await shot("briefing")
	var briefing = current_scene
	briefing._skip_dialogue()
	briefing._choose("brief:0")
	await settle()
	check(current_scene.scene_file_path.ends_with("squad.tscn"), "briefing leads to existing squad loadout")
	await shot("squad")
	await create_timer(0.25).timeout
	var engine := Story.new()
	var sum := 0
	for id in ["relay","envoy","vault","ilum","adraasHunt","dock","r_muster","r_ravine","r_caves","r_sixth","r_seventh","r_bomb","h_hetzal","h_grove","h_valo","h_tempest","h_husks","h_beacon"]:
		var mission: Dictionary = engine.mission(id)
		var extended: Dictionary = engine.story20.missions[id]
		var count := words(str(mission.brief)) + words(str(extended.brief))
		sum += count
		check(count >= 120 and count <= 250, "briefing length " + id)
		for outcome in ["win", "lose"]:
			var debrief_count := words(str(mission[outcome])) + words(str(extended[outcome]))
			check(debrief_count >= 120 and debrief_count <= 250, "debrief length %s %s" % [id,outcome])
	check(sum >= 582 * 3, "briefings at least 3x fbc2447 baseline: %d" % sum)
	for id in engine.story20.events:
		check(words(str(engine.story20.events[id])) >= 120, "Council event length " + id)
	var empty_state: Dictionary = Campaign.new().state
	empty_state.sith.ops = []
	empty_state.sith.missions = {}
	var dossier: Control = load("res://scenes/sith_report.tscn").instantiate()
	dossier.bind_state(empty_state)
	root.add_child(dossier)
	await settle()
	var empty_notice := false
	for label in dossier.find_children("*", "Label", true, false):
		if label.text == "No Sith movements detected yet.": empty_notice = true
	check(empty_notice, "Sith panel explains empty operations")
	dossier.queue_free()
	await process_frame
	var chosen_squad: Array = current_scene.selected.duplicate()
	check(flow.launch_squad(chosen_squad), "squad deploys from first briefing")
	await settle()
	check(current_scene.scene_file_path.ends_with("rescue.tscn"), "deployment reaches battle")
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	Phone.test_scale = 0.0; Phone.test_touch = -1; Phone.test_mobile = -1
	print("STORY20: %d checks, %d failures, %d briefing words / 582 baseline" % [checks, failures, sum])
	quit(1 if failures else 0)
