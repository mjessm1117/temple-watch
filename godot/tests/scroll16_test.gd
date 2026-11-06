extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("SCROLL16: " + message)

func touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0; event.position = at; event.pressed = pressed
	root.push_input(event, true)

func drag(from: Vector2, to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0; event.position = to; event.relative = to - from
	root.push_input(event, true)

func run() -> void:
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", true)
	print("SCROLL16 touchscreen: ", DisplayServer.is_touchscreen_available())
	var flow = root.get_node("CampaignFlow")
	flow.campaign = Campaign.new(); flow.active = true
	root.size = Vector2i(844, 390); root.content_scale_size = root.size
	var screen = load("res://scenes/squad.tscn").instantiate()
	root.add_child(screen); await process_frame
	screen.inspect(0); await process_frame
	var scroll: ScrollContainer = screen.arsenal.get_parent()
	var button: Button = screen.arsenal.slot_row.get_node("Slot_armor")
	check(scroll.scroll_deadzone == 10 and button.mouse_filter == Control.MOUSE_FILTER_PASS, "armory button passes touch to 10 px scroll")
	var center := button.get_global_rect().get_center()
	print("SCROLL16 geometry: scroll=", scroll.get_global_rect(), " button=", button.get_global_rect(), " max=", scroll.get_v_scroll_bar().max_value)
	var selected: String = screen.arsenal.active_slot
	touch(center, true)
	var last := center
	for step in 8:
		var next := center + Vector2(0, -12 * (step + 1))
		drag(last, next); last = next; await process_frame
	touch(last, false); await process_frame
	check(scroll.scroll_vertical > 0, "armory button drag scrolls")
	check(screen.arsenal.active_slot == selected, "armory button drag does not select")
	scroll.scroll_vertical = 0; await process_frame
	center = button.get_global_rect().get_center()
	touch(center, true); touch(center, false); await process_frame
	check(screen.arsenal.active_slot == "armor", "armory short tap selects")
	# The roster strip is a separate horizontal list of clickable cards.
	# Narrow the strip to a portrait-phone width so four cards overflow it.
	var roster: ScrollContainer = screen.card_scroll
	roster.size.x = 300; await process_frame
	var card: Button = screen.card_row.get_child(1).get_child(0).get_child(0)
	var focus_before: int = screen.focus_index
	check(roster.scroll_deadzone == 10 and card.mouse_filter == Control.MOUSE_FILTER_PASS, "roster card passes touch to 10 px scroll")
	var x_before: int = roster.scroll_horizontal
	center = card.get_global_rect().get_center()
	touch(center, true); last = center
	for step in 8:
		var next := center + Vector2(-12 * (step + 1), 0)
		drag(last, next); last = next; await process_frame
	touch(last, false); await process_frame
	check(roster.scroll_horizontal > x_before, "roster card drag scrolls")
	check(screen.focus_index == focus_before, "roster card drag does not inspect")
	center = card.get_global_rect().get_center()
	touch(center, true); touch(center, false); await process_frame
	check(screen.focus_index == 1, "roster short tap inspects")
	screen.queue_free(); await process_frame
	# Battle abilities use the same scroll owner as armory and roster.
	var battle = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(battle); await process_frame
	var abilities: ScrollContainer = battle.hud_controls.phone.overlay.find_child("Abilities", true, false)
	var action_button: Button = battle.hud_controls.phone.ability_buttons[0]
	check(abilities.scroll_deadzone == 10 and action_button.mouse_filter == Control.MOUSE_FILTER_PASS, "battle ability passes touch to 10 px scroll")
	battle.hud_controls.phone.ability_tray.offset_left = -100
	battle.hud_controls.phone.ability_tray.offset_right = 100
	await process_frame
	center = action_button.get_global_rect().get_center()
	var action_before: String = battle.action
	touch(center, true); last = center
	for step in 8:
		var next := center + Vector2(-12 * (step + 1), 0)
		drag(last, next); last = next; await process_frame
	touch(last, false); await process_frame
	check(abilities.scroll_horizontal > 0, "battle ability button drag scrolls")
	check(battle.action == action_before, "battle ability button drag does not activate")
	battle.queue_free(); await process_frame
	print("SCROLL16 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
