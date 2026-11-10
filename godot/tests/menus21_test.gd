extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Slots = preload("res://scripts/campaign/save_slots.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MENUS21: " + detail)

func settle(frames: int = 30) -> void:
	for i in frames: await process_frame

func touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = pressed
	root.push_input(event, true)

func drag(from: Vector2, to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = to
	event.relative = to - from
	root.push_input(event, true)

func run() -> void:
	Phone.test_touch = 1
	Phone.test_mobile = 1
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	var flow := root.get_node("CampaignFlow")
	check(flow.fade_duration >= 0.2 and flow.fade_duration <= 0.3, "scene fade lasts about a quarter second")
	flow.fade_duration = 0.02
	var old := Campaign.new()
	old.state.step = 4
	var legacy := FileAccess.open(Slots.path(0), FileAccess.WRITE)
	check(legacy != null, "legacy autosave opened")
	legacy.store_string(JSON.stringify({"v":1, "C":old.state}))
	legacy.close()
	var migrated := Campaign.new()
	check(Slots.read(migrated, 0), "legacy autosave loads as slot zero")
	check(Slots.metadata(0).missions == 4, "metadata mission count")
	for slot in range(1, 4):
		old.state.step = slot
		check(Slots.write(old, slot), "slot %d writes" % slot)
		var loaded := Campaign.new()
		check(Slots.read(loaded, slot) and loaded.state.step == slot, "slot %d loads" % slot)
	flow.new_campaign("normal")
	check(root.get_node_or_null("CampaignFadeLayer") != null, "scene change creates visible fade layer")
	await settle()
	check(current_scene.scene_file_path.ends_with("opening.tscn") and flow.campaign.state.flow_stage == "opening", "fresh save plays W20 opening")
	check(current_scene.next_button.custom_minimum_size.y >= 44, "opening Next 44 px")
	check(current_scene.actions.get_child(1).custom_minimum_size.y >= 44, "opening Skip 44 px")
	check(current_scene.narrative.get_theme_font_size("normal_font_size") >= 14, "opening text 14 px")
	DisplayServer.window_set_size(Vector2i(390, 844))
	root.size = Vector2i(390, 844)
	root.content_scale_size = root.size
	await settle()
	check(current_scene.narrative.get_theme_font_size("normal_font_size") >= 14 and current_scene.next_button.size.y >= 44, "portrait opening text and Next size")
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	await settle()
	check(flow.has_method("go"), "scene change fade configured")
	current_scene._finish()
	await settle()
	check(current_scene.scene_file_path.ends_with("briefing.tscn"), "opening leads to story briefing")
	check(current_scene.find_child("BriefingBack", true, false) != null, "briefing has Back")
	check(flow.has_method("back_from_squad") and flow.has_method("back_from_briefing"), "Back routes exist at each launch step")
	check(current_scene.choice_buttons.size() > 0 and current_scene.choice_buttons[0].custom_minimum_size.y >= 44, "briefing choice is a phone tap")
	flow.back_from_briefing()
	await settle()
	check(current_scene.scene_file_path.ends_with("galaxy.tscn"), "briefing Back returns to mission map")
	flow.prepare_briefing(0)
	await settle()
	check(current_scene.scene_file_path.ends_with("briefing.tscn"), "mission tap opens briefing")
	flow.story_finished()
	await settle()
	check(current_scene.scene_file_path.ends_with("squad.tscn"), "briefing continues to squad")
	check(current_scene.find_child("DEPLOY", true, false) != null or current_scene.get("deploy") != null, "squad has Deploy")
	flow.back_from_squad()
	await settle()
	check(current_scene.scene_file_path.ends_with("briefing.tscn"), "squad Back returns to briefing")
	flow.go("menu")
	await settle()
	var title := current_scene
	check(title.find_child("ContinueButton", true, false) != null, "title Continue")
	check(title.find_child("ContinueMetadata", true, false) != null, "title save overview")
	check(flow.has_method("open_settings"), "single Settings entry point")
	flow.open_saves("menu")
	await settle()
	check(current_scene.scene_file_path.ends_with("save_load.tscn"), "save screen opens")
	var saves = current_scene
	var scroll: ScrollContainer = saves.list.get_parent()
	var button: Button = saves.list.get_child(0).get_child(1).get_child(2).get_child(0)
	check(scroll.scroll_deadzone == 10 and button.mouse_filter == Control.MOUSE_FILTER_PASS, "save list passes button drags")
	var center := button.get_global_rect().get_center()
	touch(center, true)
	var last := center
	for step in 8:
		var next := center + Vector2(0, -12 * (step + 1))
		drag(last, next)
		last = next
		await process_frame
	touch(last, false)
	await process_frame
	check(scroll.scroll_vertical > 0 and saves.pending_slot == -1, "save button drag scrolls without action")
	saves._request("save", 1)
	check(saves.pending_slot == 1 and saves.pending_action == "save", "overwrite asks confirmation")
	saves._cancel()
	check(saves.pending_slot == -1, "confirmation cancels")
	saves._request("save", 2)
	saves._confirm()
	check(saves.pending_slot == -1 and not Slots.metadata(2).is_empty(), "confirmed overwrite saves slot")
	saves._request("load", 1)
	check(saves.pending_slot == 1 and saves.pending_action == "load", "load asks confirmation")
	saves._confirm()
	await settle()
	check(flow.campaign.state.step == 1, "confirmed load restores selected slot")
	check(current_scene != null and not current_scene.scene_file_path.ends_with("save_load.tscn"), "confirmed load leaves save screen")
	print("menus21_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
