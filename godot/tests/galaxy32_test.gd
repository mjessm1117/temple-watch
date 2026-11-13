extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(reason)

func frames(n: int = 8) -> void:
	for i in n: await process_frame

func run() -> void:
	Phone.test_scale = 1.0
	Phone.test_touch = 1
	Phone.test_mobile = 1
	Phone.test_window_size = Vector2i(390, 844)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://galaxy32-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new()
	flow.story = flow.campaign.story
	var stage := SubViewport.new()
	stage.size = Vector2i(390, 844)
	root.add_child(stage)
	var galaxy = load("res://scenes/galaxy.tscn").instantiate()
	galaxy.test_safe_insets32 = Vector4(59, 0, 34, 0)
	stage.add_child(galaxy)
	await frames(12)
	for label in [galaxy.deadline_rail, galaxy.contact_action]:
		var bounds: Rect2 = label.get_global_rect()
		check(label.visible and not label.text.is_empty() and bounds.position.x >= 59 and bounds.end.x <= 390 - 34 and bounds.size.y > 0, "Deadline or contact text fits 59/34 safe inset")
		var text_width: float = label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		check(text_width <= bounds.size.x - 8, "Deadline or contact text is not clipped")
	galaxy._select(0)
	await frames(8)
	var selected_id := str(flow.campaign.state.w25_selected_mission_id)
	galaxy.scroll.scroll_vertical = 90
	await frames(2)
	var held_scroll: int = galaxy.scroll.scroll_vertical
	check(held_scroll > 0, "Selected detail can scroll")
	galaxy._show_details()
	await frames(3)
	check(galaxy.scroll.scroll_vertical == held_scroll, "Refresh preserves detail scroll while idle")
	check(galaxy.selected == 0 and str(flow.campaign.state.w25_selected_mission_id) == selected_id, "Refresh preserves selected contact")
	var ready_shortcut: Button = galaxy.find_child("SignalReadyShortcut32", true, false)
	check(ready_shortcut != null and ready_shortcut.visible and not ready_shortcut.disabled, "Galaxy home exposes mobile READY shortcut")
	flow.active = true
	var taps := 1 # Select signal from Galaxy home.
	if ready_shortcut != null:
		ready_shortcut.pressed.emit()
		taps += 1
		await create_timer(0.8).timeout
	var ready = current_scene
	check(ready != null and ready.name == "Readiness25", "Shortcut reaches readiness")
	if ready != null and ready.name == "Readiness25":
		var choice: Button = ready.find_child("ReadyChoice0", true, false)
		if choice != null:
			choice.pressed.emit()
			taps += 1
		var confirm: Button = ready.find_child("ReadyConfirm", true, false)
		check(confirm != null and confirm.visible and not confirm.disabled, "Mobile confirm card exposes direct deploy")
		if confirm != null: taps += 1
	check(taps <= 4, "Galaxy signal to deploy takes at most four taps")
	stage.free()
	if ready != null and ready.name == "Readiness25": await flow.back_from_ready25()
	await frames(4)
	Phone.test_window_size = Vector2i(956, 440)
	var war_stage := SubViewport.new()
	war_stage.size = Vector2i(956, 440)
	root.add_child(war_stage)
	var war = load("res://scenes/sith_report.tscn").instantiate()
	war.test_safe_insets32 = Vector4(59, 0, 34, 0)
	war_stage.add_child(war)
	await frames(10)
	var close: Button = war.find_child("WarClose32", true, false)
	check(close != null and close.get_global_rect().size.y >= 44, "Shadow War CLOSE height is at least 44 px")
	var safe_left := 59.0
	var safe_right := 34.0
	if close != null:
		var bounds := close.get_global_rect()
		check(bounds.position.x >= safe_left and bounds.end.x <= 956.0 - safe_right, "CLOSE fits 59/34 safe inset")
	var deadline: Label = war.find_child("WarDeadline32", true, false)
	check(deadline != null and deadline.visible and not deadline.text.is_empty(), "Shadow War deadline is visible")
	if deadline != null:
		var bounds := deadline.get_global_rect()
		check(bounds.position.x >= safe_left and bounds.end.x <= 956.0 - safe_right and bounds.position.y >= 0 and bounds.end.y <= 440, "Deadline fits 59/34 safe inset")
	war_stage.free()
	Phone.test_window_size = Vector2i.ZERO
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("Galaxy32: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
