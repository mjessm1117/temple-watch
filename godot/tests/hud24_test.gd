extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Layout = preload("res://scripts/hud_phone_layout.gd")
class BindingsFixture extends RefCounted:
	func bindings24() -> Dictionary: return {"overwatch": ["6"]}
var checks := 0
var failures := 0
const OUT := "/home/jess/projects/tw-logs/w24/hud/"

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1; push_error("HUD24: " + label)

func frames(count: int = 3) -> void:
	for i in count: await process_frame

func capture(view: Viewport, name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	DirAccess.make_dir_recursive_absolute(OUT)
	await frames(2)
	await RenderingServer.frame_post_draw
	check(view.get_texture().get_image().save_png(OUT + name + ".png") == OK, "capture " + name)

func hit_rect(control: Control) -> Rect2:
	var rect := control.get_global_rect()
	var parent := control.get_parent()
	while parent is Control:
		if parent.clip_contents or parent is ScrollContainer: rect = rect.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return rect

func touch(view: Viewport, point: Vector2) -> void:
	var event := InputEventScreenTouch.new(); event.position = point; event.pressed = true
	view.push_input(event, true)
	event = InputEventScreenTouch.new(); event.position = point; event.pressed = false
	view.push_input(event, true)

func geometry(hud, label: String) -> void:
	var buttons: Array[BaseButton] = []
	_collect_buttons(hud.overlay, buttons)
	for i in buttons.size():
		var rect := hit_rect(buttons[i])
		if not rect.has_area(): continue
		check(rect.size.x >= 44 and rect.size.y >= 44, label + " visible touch target >=44 " + buttons[i].name)
		for j in range(i + 1, buttons.size()):
			var other := hit_rect(buttons[j])
			if other.has_area(): check(not rect.intersects(other), label + " no button overlap " + buttons[i].name + "/" + buttons[j].name)
	var arrows: Array[Control] = [hud.overlay.find_child("UnitPrevious", true, false), hud.overlay.find_child("UnitNext", true, false)]
	for arrow in arrows:
		check(hit_rect(arrow).size.x >= 44 and hit_rect(arrow).size.y >= 44, label + " unit arrow >=44")
		for ability in hud.ability_buttons:
			if ability.visible: check(not hit_rect(arrow).intersects(hit_rect(ability)), label + " arrow outside ability " + ability.ability_id + " " + str(hit_rect(arrow)) + " " + str(hit_rect(ability)))
	for control in [hud.end_button, hud.more_button, hud.momentum_strike]:
		if control.visible: check(hit_rect(control).size.x >= 44 and hit_rect(control).size.y >= 44, label + " " + control.name + " >=44")
	for ability in hud.ability_buttons:
		if ability.visible: check(hit_rect(ability).size.x >= 44 and hit_rect(ability).size.y >= 44, label + " ability >=44 " + ability.ability_id)
	check(not hit_rect(hud.end_button).intersects(hit_rect(hud.unit_plate)), label + " End Turn clear of unit")
	check(not hit_rect(hud.end_button).intersects(hit_rect(hud.ability_tray)), label + " End Turn clear of actions")
	check(hit_rect(hud.end_button).end.y <= hud.overlay.get_global_rect().position.y + 44, label + " End Turn outside map taps")

func _collect_buttons(node: Node, found: Array[BaseButton]) -> void:
	if node is BaseButton and node.is_visible_in_tree() and node.mouse_filter != Control.MOUSE_FILTER_IGNORE: found.append(node)
	for child in node.get_children(): _collect_buttons(child, found)

func _check_button_rects(buttons: Array[BaseButton], label: String) -> void:
	for i in buttons.size():
		var rect := hit_rect(buttons[i])
		if not rect.has_area(): continue
		check(rect.size.x >= 44 and rect.size.y >= 44, label + " target >=44 " + buttons[i].name)
		for j in range(i + 1, buttons.size()):
			var other := hit_rect(buttons[j])
			if other.has_area(): check(not rect.intersects(other), label + " no overlap " + buttons[i].name + "/" + buttons[j].name)

func battle(size: Vector2i) -> void:
	Phone.test_window_size = size
	Phone.test_touch = 1 if size.x < 500 else 0
	Phone.test_mobile = 1 if size.x < 500 else 0
	var view := SubViewport.new(); view.size = size; view.render_target_update_mode = SubViewport.UPDATE_ALWAYS; root.add_child(view)
	var game = load("res://scenes/rescue.tscn").instantiate(); view.add_child(game)
	await frames(10)
	var hud = game.hud_controls.phone
	if size.x >= 1000:
		check(hud == null, "desktop retains desktop HUD")
		for panel in [game.hud_controls.left_panel, game.hud_controls.desktop_bottom]:
			var buttons: Array[BaseButton] = []
			_collect_buttons(panel, buttons)
			_check_button_rects(buttons, "desktop " + panel.name)
		check(hit_rect(game.audio_slider).size.x >= 44 and hit_rect(game.audio_slider).size.y >= 44, "desktop volume slider >=44")
		var boxes: Dictionary = Layout.boxes(size)
		check(not boxes.header.intersects(boxes.plate) and not boxes.header.intersects(boxes.tray), "desktop reserved rects separate")
		if size.x == 1280: await capture(view, "after-1280x720-start")
		if size.x == 1280:
			var actor: Dictionary = {}
			for ally in game.mission.living("player"):
				if "shoot" in ally.get("kit", []): actor = ally; break
			var target: Dictionary = game.mission.living("enemy")[0]
			target.awake = true; target.spotted = true
			game.selected_id = int(actor.id); game.target_id = int(target.id); game.action = "shoot"
			game._refresh(); await frames()
			var aim_buttons: Array[BaseButton] = []
			_collect_buttons(game.hud_controls.aim_ui.panel, aim_buttons)
			_check_button_rects(aim_buttons, "desktop aim")
			await capture(view, "after-1280x720-aim")
	else:
		check(hud != null, str(size) + " phone HUD")
		if hud != null:
			game._refresh(); await frames()
			geometry(hud, str(size))
			if size.x < size.y: await capture(view, "after-390x844-start")
			if size.x < size.y:
				check(hud.ability_tray.get_global_rect().position.y > hud.unit_plate.get_global_rect().end.y, "portrait unit and actions in separate rows")
				var target: Dictionary = game.mission.living("enemy")[0]
				var actor: Dictionary = {}
				for ally in game.mission.living("player"):
					if "shoot" in ally.get("kit", []): actor = ally; break
				game.selected_id = int(actor.id); game._refresh(); await frames()
				await capture(view, "after-390x844-overwatch")
				touch(view, hud.end_button.get_global_rect().get_center()); await frames(1)
				check(hud.end_confirm, "B15 End Turn requires second tap while AP remains")
				hud.end_confirm = false
				var overwatch: Control
				for ability in hud.ability_buttons:
					if ability.ability_id == "overwatch": overwatch = ability
				check(overwatch != null and overwatch.visible, "K3 Overwatch visible without MORE " + str(actor.get("kit", [])))
				target.awake = true; target.spotted = true
				game.selected_id = int(actor.id); game.target_id = int(target.id); game.action = "shoot"
				game._refresh(); await frames()
				check(hud.odds_plate.visible and not game.hud_controls.aim_ui.odds.get_parent().visible, "B1 one portrait odds card")
				check(not hud.odds_plate.get_global_rect().intersects(game.hud_controls.aim_ui.target_row.get_global_rect()), "B1 odds clear of target row")
				await capture(view, "after-390x844-aim")
				check(hud.feedback.details_button.visible, "B12 reasons expand in card")
				hud.feedback.details_button.pressed.emit(); await frames()
				check(hud.odds_modifiers.visible and hud.feedback.details_open, "B12 reasons revealed")
				check(hud.odds_plate.get_global_rect().size.y >= 200, "B12 expanded card height")
				hud.odds_modifiers.text = "Modifier +1\n".repeat(20); await frames()
				var reasons_at: Vector2 = hud.odds_scroll.get_global_rect().get_center()
				var reason_down := InputEventScreenTouch.new(); reason_down.position = reasons_at; reason_down.pressed = true; view.push_input(reason_down, true)
				var reason_drag := InputEventScreenDrag.new(); reason_drag.position = reasons_at + Vector2(0, -120); reason_drag.relative = Vector2(0, -120); view.push_input(reason_drag, true)
				var reason_up := InputEventScreenTouch.new(); reason_up.position = reason_drag.position; reason_up.pressed = false; view.push_input(reason_up, true)
				await frames(1)
				check(hud.odds_scroll.scroll_vertical > 0, "B12 full reason list scrolls in card")
				game.action = "move"; game.target_id = -1; game._refresh(); await frames()
				hud.feedback.refresh_pressure({"pending_groups": [{"count": 2, "turns": 1, "entry_pos": Vector2i(8, 4)}]})
				check(hud.feedback.reinforcement.visible and hud.feedback.reinforcement.text.contains("INBOUND 2") and hud.feedback.reinforcement.text.contains("1 TURN") and hud.feedback.reinforcement.text.contains("ENTRY 8, 4"), "B13 reinforcement count turn entry")
				actor.ap = 0; game._refresh(); await frames()
				var blocked: Button
				for ability in hud.ability_buttons:
					if ability.visible and ability.disabled: blocked = ability; break
				check(blocked != null, "K9 disabled action remains visible")
				if blocked != null:
					var tapped_ms := Time.get_ticks_msec()
					touch(view, blocked.get_global_rect().get_center())
					var visible_ms := Time.get_ticks_msec() - tapped_ms
					check(visible_ms <= 100 and hud.feedback.ability_reason.visible, "K9 Low tap response <=100 ms: %d" % visible_ms)
					await frames(1)
					check(hud.feedback.ability_reason.visible and hud.feedback.ability_reason.text == blocked.tooltip_text and blocked.tooltip_text.contains("AP"), "K9 disabled tap shows reason and cost")
					print("HUD24 tap_ms=", visible_ms)
				hud.feedback._busy_changed(true)
				check(hud.feedback.busy.visible, "K11 busy cue visible")
				hud.feedback._busy_changed(false)
				check(not hud.feedback.busy.visible, "K11 busy cue clears")
				var controls := preload("res://scripts/w24_hud_controls_settings.gd").new(); view.add_child(controls); await frames()
				check(controls.find_child("CameraSensitivity", true, false) != null, "K12 sensitivity control")
				check(controls.key_buttons.has("overwatch"), "K12 merged command bindings are editable")
				(controls.find_child("CameraSensitivity", true, false) as HSlider).value = 1.3
				var cfg := ConfigFile.new(); cfg.load("user://controls24.cfg")
				check(is_equal_approx(float(cfg.get_value("controls", "cam_sensitivity", 0)), 1.3), "K12 controls24.cfg saved")
				for name in ["invert_pan", "invert_rotate", "edge_pan", "confirm_move"]:
					var option: CheckButton = controls.find_child(name.to_pascal_case(), true, false)
					check(option != null and option.size.y >= 44, "K12 option target >=44 " + name)
					option.button_pressed = not option.button_pressed
					cfg.load("user://controls24.cfg")
					check(bool(cfg.get_value("controls", name)) == option.button_pressed, "K12 option persisted " + name)
				controls.queue_free()
				var remap := preload("res://scripts/w24_hud_controls_settings.gd").new()
				remap.source = BindingsFixture.new(); view.add_child(remap); await frames()
				check(remap.key_buttons.has("overwatch"), "K12 bindings24 yields remap row")
				remap.key_buttons["overwatch"].pressed.emit()
				var key := InputEventKey.new(); key.keycode = KEY_Y; key.pressed = true
				view.push_input(key, true); await frames(1)
				cfg.load("user://controls24.cfg")
				check(cfg.get_value("controls", "keymap", {}).get("overwatch", []) == ["Y"], "K12 key remap saved")
				remap.queue_free()
				hud._show_settings(); hud.popup.show(); await frames()
				check(hud.popup.find_child("ControlsSection", true, false) != null and hud.detail_scroll is ScrollContainer, "K12 battle settings scroll with touch")
				var scroll_start: int = hud.detail_scroll.scroll_vertical
				var point: Vector2 = hud.detail_scroll.get_global_rect().get_center()
				var down := InputEventScreenTouch.new(); down.position = point; down.pressed = true; view.push_input(down, true)
				var drag := InputEventScreenDrag.new(); drag.position = point + Vector2(0, -220); drag.relative = Vector2(0, -220); view.push_input(drag, true)
				var up := InputEventScreenTouch.new(); up.position = drag.position; up.pressed = false; view.push_input(up, true)
				await frames(1)
				check(hud.detail_scroll.scroll_vertical > scroll_start, "K12 iPhone drag scrolls controls")
				await capture(view, "after-390x844-settings")
	game.queue_free(); view.queue_free(); await frames()

func run() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://hud24-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new("normal"); flow.story = flow.campaign.story; flow.active = true
	for size in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1366, 768), Vector2i(1280, 720)]: await battle(size)
	print("HUD24: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
