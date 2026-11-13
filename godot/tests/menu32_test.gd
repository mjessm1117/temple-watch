extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MENU32: " + label)

func settle(frames: int = 8) -> void:
	for i in frames: await process_frame

func escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event, true)

func scene_is(name: String) -> bool:
	return current_scene != null and current_scene.scene_file_path.ends_with("/" + name + ".tscn")

func run() -> void:
	Phone.test_touch = 1
	Phone.test_mobile = 1
	DisplayServer.window_set_size(Vector2i(390, 844))
	root.size = Vector2i(390, 844)
	root.content_scale_size = root.size
	var flow := root.get_node("CampaignFlow")
	flow.fade_duration = 0.01
	flow.go("menu")
	await settle(12)
	flow.open_settings()
	await settle(10)
	var scroll: ScrollContainer = flow.settings_panel.find_child("SettingsScroll", true, false)
	var shield: Control = flow.settings_layer.find_child("SettingsTouchShield", true, false)
	var first: OptionButton = flow.settings_panel.find_child("GraphicsTier", true, false)
	check(scroll != null and shield != null and first != null, "portrait Settings list and first option exist")
	if scroll == null or shield == null or first == null:
		print("menu32_test: %d checks, %d failures" % [checks, failures])
		quit(1)
		return
	var start := first.get_global_rect().get_center()
	var down := InputEventScreenTouch.new()
	down.position = start
	down.pressed = true
	shield._gui_input(down)
	var last := start
	for i in 8:
		var next := start + Vector2(0, -22 * (i + 1))
		var drag := InputEventScreenDrag.new()
		drag.position = next
		drag.relative = next - last
		shield._gui_input(drag)
		last = next
		await process_frame
	var up := InputEventScreenTouch.new()
	up.position = last
	up.pressed = false
	shield._gui_input(up)
	await settle(2)
	check(scroll.scroll_vertical > 0 and not first.get_popup().visible, "drag on first Settings button scrolls without activating it")
	scroll.scroll_vertical = int(scroll._limit(1))
	scroll.edge = Vector2.ZERO
	scroll._move(Vector2(0, 120), true)
	await settle(2)
	var content: Control = scroll._content()
	check(scroll.scroll_vertical <= int(scroll._limit(1)) and content.position.y + scroll.scroll_vertical <= 0.01 and content.position.y + scroll.scroll_vertical >= -0.01, "content remains clamped after drag past end")
	var saved := scroll.scroll_vertical
	flow.open_settings()
	flow.open_settings()
	await settle(8)
	scroll = flow.settings_panel.find_child("SettingsScroll", true, false)
	check(scroll.scroll_vertical == saved and saved > 0, "Settings scroll position survives re-entry")
	escape()
	await settle(4)
	check(not is_instance_valid(flow.settings_panel) and scene_is("menu"), "Escape closes Settings exactly one level")
	flow.open_settings()
	await settle(2)
	var back: Button = flow.settings_panel.find_child("SettingsBack", true, false)
	back.pressed.emit()
	await settle(4)
	check(not is_instance_valid(flow.settings_panel) and scene_is("menu"), "Settings Back closes exactly one level")
	flow.open_settings()
	await settle(2)
	var graphics: OptionButton = flow.settings_panel.find_child("GraphicsTier", true, false)
	graphics.grab_focus()
	escape()
	await settle(4)
	check(not is_instance_valid(flow.settings_panel) and scene_is("menu"), "Escape from graphics options closes Settings once")
	flow.open_saves("menu")
	await settle(12)
	check(scene_is("save_load"), "Save screen opens")
	current_scene._request("save", 1)
	escape()
	await settle(2)
	check(scene_is("save_load") and current_scene.pending_slot == -1, "Escape cancels Save confirmation one level")
	escape()
	await settle(12)
	check(scene_is("menu"), "Escape from Save returns to menu once")
	flow.open_saves("menu")
	await settle(12)
	var save_back: Button = current_scene.find_child("SaveBack", true, false)
	check(save_back != null, "Save Back button exists")
	save_back.pressed.emit()
	await settle(12)
	check(scene_is("menu"), "Save Back returns to menu once")
	flow.campaign = Campaign.new()
	flow.story = Story.new(flow.campaign.state)
	flow.active = true
	flow.prepare_briefing(0)
	await settle(12)
	check(scene_is("briefing"), "Story briefing opens")
	escape()
	await settle(12)
	check(scene_is("galaxy"), "Escape from Story briefing returns to mission map once")
	flow.prepare_briefing(0)
	await settle(12)
	var story_back: Button = current_scene.find_child("BriefingBack", true, false)
	check(story_back != null, "Story Back button exists")
	story_back.pressed.emit()
	await settle(12)
	check(scene_is("galaxy"), "Story Back returns to mission map once")
	flow.open_codex()
	await settle(12)
	check(scene_is("codex"), "Story archive opens")
	escape()
	await settle(12)
	check(scene_is("galaxy"), "Escape from Story archive returns to its opener once")
	flow.screen = {"kind": "talk", "title": "Route check", "text": "Return to Temple.", "choices": []}
	flow.screen_return = "temple"
	flow.go("dialogue")
	await settle(12)
	check(scene_is("dialogue"), "Story dialogue opens")
	escape()
	await settle(12)
	check(scene_is("temple"), "Escape from Story dialogue returns one level without reopening it")
	flow.screen = {"kind": "talk", "title": "Route check", "text": "Return to Temple.", "choices": []}
	flow.screen_return = "temple"
	flow.go("dialogue")
	await settle(12)
	var dialogue_back: Button = current_scene.find_child("StoryBack", true, false)
	check(dialogue_back != null, "Story dialogue Back button exists")
	dialogue_back.pressed.emit()
	await settle(12)
	check(scene_is("temple"), "Story dialogue Back returns one level without reopening it")
	print("menu32_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
