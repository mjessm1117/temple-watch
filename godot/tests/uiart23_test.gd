extends SceneTree
const Phone = preload("res://scripts/phone_layout.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const UI = preload("res://scripts/campaign/ui.gd")
var checks := 0
var failures := 0
const OUT = "/home/jess/projects/tw-logs/w23/uiart/captures/"

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("UIART23: " + reason)

func frames(n: int = 6) -> void:
	for i in n: await process_frame

func shot(viewport: Viewport, name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	DirAccess.make_dir_recursive_absolute(OUT)
	await frames(2)
	check(viewport.get_texture().get_image().save_png(OUT + name + ".png") == OK, "capture " + name)

func stage(size: Vector2i) -> SubViewport:
	Phone.test_window_size = size
	Phone.test_touch = 1 if size.x < 500 else 0
	Phone.test_mobile = 1 if size.x < 500 else 0
	var view := SubViewport.new()
	view.size = size
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	return view

func run() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://uiart23-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new("normal")
	flow.story = flow.campaign.story
	flow.active = true
	var phone := stage(Vector2i(390, 844))
	var game = load("res://scenes/rescue.tscn").instantiate()
	phone.add_child(game)
	await frames(12)
	var hud = game.hud_controls.phone
	check(hud != null, "portrait HUD exists")
	check(hud.threat_chip.get_parent() == hud.end_button.get_parent(), "threat chip remains beside End Turn")
	check(hud.alerts != null and not hud.alerts.card.mouse_filter == Control.MOUSE_FILTER_STOP, "one non-blocking alert layer")
	check(hud.alerts.card.visible, "portrait turn notice uses the alert layer")
	await shot(phone, "phone-alert")
	var actor: Dictionary = {}
	for ally in game.mission.living("player"):
		if "shoot" in ally.get("kit", []): actor = ally; break
	if actor.is_empty(): actor = game.mission.living("player")[0]
	var target: Dictionary = game.mission.living("enemy")[0]
	target.awake = true; target.spotted = true
	game.selected_id = int(actor.id); game.target_id = int(target.id); game.action = "shoot"
	game._refresh()
	await frames(4)
	var aim = game.hud_controls.aim_ui
	check(aim.panel.visible and hud.odds_plate.visible, "portrait aim and odds visible")
	check(not aim.odds.get_parent().visible and not aim.odds_detail.visible, "inline aim odds suppressed")
	check(hud.odds_plate.get_global_rect().end.y < phone.size.y * 0.25, "odds anchored above sight line")
	check(not hud.odds_plate.get_global_rect().intersects(aim.target_row.get_global_rect()), "odds and target selection do not overlap")
	check(not aim.panel.get_global_rect().intersects(aim.target_row.get_global_rect()), "one lower confirmation tray")
	for button in [aim.confirm, aim.cancel]:
		check(button.get_global_rect().size.y >= 44 and button.get_global_rect().end.x <= 378, "aim action touch target and safe edge " + button.name)
	await shot(phone, "phone-aim")
	var battle_draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var battle_tris := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	check(DisplayServer.get_name() == "headless" or battle_draws > 0 and battle_tris > 0, "battle renderer exposes draw and triangle counters")
	game.queue_free(); await frames()
	phone.queue_free(); await frames()
	var home_view := stage(Vector2i(390, 844))
	var home = load("res://scenes/temple.tscn").instantiate()
	home_view.add_child(home)
	await frames(10)
	check(home.room_picker.visible and home.room_picker.size.y < home_view.size.y * 0.55, "portrait room sheet leaves set visible")
	home._open_room("training", "Roster")
	await frames(6)
	check(home.station_panel.size.y < home_view.size.y * 0.55, "contextual station sheet leaves set visible")
	check(home.station_panel.find_child("StationHeading", true, false).text.to_lower().contains("training"), "room heading is contextual")
	await shot(home_view, "phone-temple")
	home.queue_free(); await frames()
	var galaxy = load("res://scenes/galaxy.tscn").instantiate()
	home_view.add_child(galaxy)
	await frames(10)
	galaxy._select(0); await frames(6)
	check(galaxy.selected_card.visible and galaxy.selected_forecast.text.contains("THREAT") and galaxy.selected_forecast.text.contains("REWARD"), "selected mission shows threat and reward together")
	check(galaxy.detail_panel.size.y < home_view.size.y * 0.6, "selected mission card preserves map")
	check(galaxy.selected_card.mouse_filter == Control.MOUSE_FILTER_PASS, "drag starting on selected mission card reaches scroll")
	await create_timer(0.4).timeout
	await shot(home_view, "phone-galaxy")
	galaxy.queue_free(); await frames()
	var squad = load("res://scenes/squad.tscn").instantiate()
	home_view.add_child(squad)
	await frames(12)
	check(squad.resources.get_parent().visible and squad.resources.text.contains("Intel"), "portrait resources remain readable below title")
	check(squad.header.get_global_rect().size.y <= 70, "portrait header does not shade the hero stage: %.1f" % squad.header.size.y)
	check(not squad.counter.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "portrait squad counter stays on one line")
	squad.inspect(0); await frames(8)
	check(squad.drawer.size.y > home_view.size.y * 0.6, "focused armory has a tall scroll region")
	if squad.arsenal != null:
		var tile: Button = squad.arsenal.slot_row.get_child(0)
		var title: Label = tile.get_node("SlotLabel")
		var item: Label = tile.get_node("ItemName")
		check(title.get_rect().end.y < item.get_rect().position.y, "gear tile title and item lines do not collide")
		check(tile.mouse_filter == Control.MOUSE_FILTER_PASS, "drag starting on gear tile reaches scroll")
	await shot(home_view, "phone-armory")
	squad.queue_free(); home_view.queue_free(); await frames()
	flow.active = false
	var story_view := stage(Vector2i(390, 844))
	var story = load("res://scenes/briefing.tscn").instantiate()
	story_view.add_child(story); await frames(8)
	check(story.speaker_portrait != null and story.speaker_portrait.custom_minimum_size.x >= 52, "phone story portrait leads card")
	story._reveal()
	await shot(story_view, "phone-story")
	story.show_scene(story.engine.start_debrief({"mission_id":"relay", "won":true}))
	await frames(8)
	check(story.narrative != null and story.page_counter != null, "debrief uses shared story card")
	story._reveal()
	await shot(story_view, "phone-debrief")
	story.queue_free(); story_view.queue_free(); await frames()
	var desktop := stage(Vector2i(1280, 720))
	var wide_game = load("res://scenes/rescue.tscn").instantiate()
	desktop.add_child(wide_game); await frames(10)
	check(wide_game.hud_controls.phone == null, "desktop uses desktop HUD")
	check(wide_game.hud_controls.left_panel.size.x <= 200, "desktop squad panel is narrow: %.1f" % wide_game.hud_controls.left_panel.size.x)
	check(not wide_game.hud_controls.right_panel.visible, "desktop targeting panel waits for an action")
	check(wide_game.hud_controls.desktop_bottom.size.y <= 130, "desktop action tray is compact")
	await shot(desktop, "desktop-battle")
	wide_game.queue_free(); desktop.queue_free(); await frames()
	check(UI.SURFACE_RAISED != UI.PANEL and UI.TYPE_CAPTION >= 14, "shared palette and type tokens")
	print("UIART23: %d checks, %d failures; battle draws %d; tris %d" % [checks, failures, battle_draws, battle_tris])
	quit(1 if failures else 0)
