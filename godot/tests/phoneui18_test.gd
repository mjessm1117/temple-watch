extends SceneTree
## Phone battle geometry, gestures, aim state, and optional evidence captures.
const Campaign = preload("res://scripts/campaign/state.gd")
const Chains = preload("res://scripts/ability_chains.gd")
const Layout = preload("res://scripts/hud_phone_layout.gd")
const Shot = preload("res://scripts/shot.gd")
var checks := 0
var failures := 0
var capture := false
var physical_scale := 1.0
const OUT = "res://../docs/godot/w18/phoneui/"

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PHONEUI18: " + label)

func size_to(value: Vector2i) -> void:
	DisplayServer.window_set_size(value)
	root.size = value; root.content_scale_size = value
	await process_frame

func shot(name: String, directory: String = OUT) -> void:
	if not capture: return
	await create_timer(1.4).timeout
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(directory + name + ".png")) == OK, "capture " + name)

func touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new(); event.index = 0; event.position = at; event.pressed = pressed
	root.push_input(event, true)

func swipe(at: Vector2) -> void:
	touch(at, true)
	var previous := at
	for step in 8:
		var next := at + Vector2(-80.0 * float(step + 1) / 8.0, 0)
		var drag := InputEventScreenDrag.new(); drag.index = 0; drag.position = next; drag.relative = next - previous
		root.push_input(drag, true); previous = next
		await process_frame
	touch(previous, false); await process_frame

func controls(node: Node, found: Array[BaseButton]) -> void:
	if node is BaseButton and node.is_visible_in_tree() and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		found.append(node)
	for child in node.get_children(): controls(child, found)

func clipped_rect(control: Control) -> Rect2:
	var result := control.get_global_rect().intersection(Rect2(Vector2.ZERO, root.size))
	var parent := control.get_parent()
	while parent is Control:
		if parent.clip_contents or parent is ScrollContainer: result = result.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return result

func geometry(nodes: Array[Node], label: String) -> void:
	var buttons: Array[BaseButton] = []
	for node in nodes: controls(node, buttons)
	for i in buttons.size():
		var a := clipped_rect(buttons[i])
		if not a.has_area(): continue
		check(a.size.x * physical_scale >= 43.9 and a.size.y * physical_scale >= 43.9, "%s %s hit %s" % [label, buttons[i].name, a])
		for j in range(i + 1, buttons.size()):
			var b := clipped_rect(buttons[j])
			if b.has_area(): check(not a.intersects(b), "%s %s overlaps %s: %s %s" % [label, buttons[i].name, buttons[j].name, a, b])

func battle(value: Vector2i) -> void:
	await size_to(value)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://phoneui18-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	var game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(game)
	for i in 8: await process_frame
	game.demo_mode = true
	var phone = game.hud_controls.phone
	check(phone != null, "%s phone HUD exists" % value)
	physical_scale = float(value.x) / phone.overlay.size.x
	var layout := Layout.boxes(value)
	var header: Control = phone.overlay.find_child("PhoneTopStrip", true, false)
	var header_background: Control = phone.overlay.find_child("PhoneTopBackground", true, false)
	var header_pixels: float = header_background.get_global_rect().size.y * float(value.y) / game.camera.get_viewport().get_visible_rect().size.y
	print("PHONEUI18 METRICS ", value, " header_px=", snappedf(header_pixels, 0.1), " map_fraction=", snappedf(float(layout.map.size.y) / float(value.y), 0.01))
	check(header.get_global_rect().size.y <= 44.0, "%s header at most 44" % value)
	check(header_pixels <= 44.1, "%s rendered header at most 44 px" % value)
	check(layout.map.size.y >= game.camera.get_viewport().get_visible_rect().size.y * 0.75 and game.camera.get_viewport().get_visible_rect().size.y >= value.y * 0.8, "%s full map viewport" % value)
	check(phone.unit_plate.get_global_rect().get_center().x < value.x * 0.5 and phone.unit_plate.get_global_rect().get_center().y > value.y * 0.5, "%s plate bottom left" % value)
	check(phone.unit_plate.get_global_rect().size.x >= 44.0 and phone.unit_plate.get_global_rect().size.y >= 44.0, "%s swipe plate hit area" % value)
	check(not phone.unit_plate.get_global_rect().intersects(phone.ability_tray.get_global_rect()), "%s plate and tray separated" % value)
	var band_top: float = minf(phone.unit_plate.get_global_rect().position.y, phone.ability_tray.get_global_rect().position.y)
	print("PHONEUI18 BAND ", value, " plate=", phone.unit_plate.get_global_rect(), " tray=", phone.ability_tray.get_global_rect(), " overlay=", phone.overlay.get_global_rect())
	check((phone.overlay.size.y - band_top) / phone.overlay.size.y <= 0.22, "%s bottom band at most 22 percent" % value)
	var plate_limit := Vector2(230, 70) if value.x < 750 else Vector2(260, 76)
	var scale := physical_scale
	check(phone.unit_plate.size.x * scale <= plate_limit.x + 0.1 and phone.unit_plate.size.y * scale <= plate_limit.y + 0.1, "%s plate within size limit" % value)
	check(phone.unit_portrait.size.x * scale >= 48 and phone.unit_portrait.size.y * scale >= 48 and phone.unit_portrait.texture != null, "%s actual portrait at least 48 square" % value)
	check(not header.get_global_rect().intersects(phone.unit_plate.get_global_rect()) and not header.get_global_rect().intersects(phone.ability_tray.get_global_rect()), "%s header separated from bottom HUD" % value)
	var squad: Array[Dictionary] = game.mission.living("player")
	var enemies: Array[Dictionary] = game.mission.living("enemy")
	var actor: Dictionary = squad[0]
	var enemy: Dictionary = enemies[0]
	enemy.x = int(actor.x) + 2; enemy.y = int(actor.y) - 2; enemy.awake = true; enemy.spotted = true
	game._refresh_figures()
	Chains.apply_tag(actor, "ATTUNED", int(squad[1].id))
	Chains.apply_tag(actor, "INSPIRED", int(squad[1].id))
	Chains.apply_tag(enemy, "MARKED", int(actor.id))
	Chains.apply_tag(enemy, "EXPOSED", int(actor.id))
	game.mission.chain_momentum = 3; game._refresh()
	for i in 3: await process_frame
	var shown := 0
	for button in phone.ability_buttons:
		if button.visible:
			shown += 1
			check(not button.phone_badge_rect(button.size).intersects(button.phone_label_rect(button.size)), "%s %s badge clear of label" % [value, button.ability_id])
	check(shown >= (3 if value.x < 750 else 4), "%s visible ability count" % value)
	check(phone.momentum_strike.visible and phone.more_button.visible, "%s strike and more visible" % value)
	check(phone.ability_tray.get_global_rect().encloses(phone.momentum_strike.get_global_rect()), "%s strike inside tray" % value)
	check(phone.ability_tray.get_global_rect().encloses(phone.momentum_plate.get_global_rect()), "%s pips inside tray" % value)
	geometry([phone.overlay, game.hud_controls.combo_overlay], str(value) + " battle")
	var badge: Button = game.hud_controls.combo_overlay.icons[int(actor.id)][0]
	for tagged in [actor, enemy]:
		var head: Vector2 = game.camera.unproject_position(Vector3(tagged.x, Shot.elevation(game.mission, Vector2i(tagged.x, tagged.y)) * 0.7 + 1.85, tagged.y))
		var badges: Array = game.hud_controls.combo_overlay.icons[int(tagged.id)]
		for icon in badges: check(icon.get_global_rect().end.y <= head.y - 7.0, "%s %s badge above head" % [value, tagged.name])
	if value.x == 844: await shot("battle-844x390")
	else: await shot("battle-667x375")
	for control in [phone.ability_buttons[0], badge, phone.unit_card]:
		var before: Vector3 = game.pivot
		await swipe(control.get_global_rect().get_center())
		if control == phone.ability_buttons[0]:
			check(game.pivot.distance_to(before) > 0.03, "%s ability drag still pans in HUD lane" % value)
		else:
			check(game.pivot.distance_to(before) < 0.03, "%s drag from %s leaves board still" % [value, control.name])
	var selected_before: int = game.selected_id
	await swipe(phone.unit_portrait.get_global_rect().get_center())
	check(game.selected_id != selected_before, "%s plate swipe cycles unit" % value)
	var shooter: Dictionary = {}
	for member in squad:
		if "shoot" in member.get("kit", []): shooter = member; break
	check(not shooter.is_empty(), "%s shooter" % value)
	game._select(int(shooter.id))
	for i in 2: await process_frame
	enemy.x = int(shooter.x) + 2; enemy.y = int(shooter.y); game._refresh_figures()
	var other_enemy: Dictionary = enemies[1]
	other_enemy.x = int(shooter.x) + 3; other_enemy.y = int(shooter.y) + 1
	other_enemy.awake = true; other_enemy.spotted = true; game._refresh_figures()
	game._choose_action("shoot")
	for i in 3: await process_frame
	var aim = game.hud_controls.aim_ui
	check(aim.panel.visible and aim.target_row.visible and aim.targets.get_child_count() > 0, "%s target row" % value)
	check(not aim.target_row.get_global_rect().intersects(aim.panel.get_global_rect()), "%s aim target and confirm areas separated" % value)
	check(aim.confirm.visible and aim.cancel.visible and aim.confirm.get_global_rect().size.y >= 44, "%s confirm and cancel" % value)
	check(aim.odds.text.contains("HIT") and aim.odds_detail.text.contains("CRIT") and aim.odds_detail.text.contains("DMG"), "%s hit crit damage" % value)
	check(aim.panel.get_global_rect().encloses(aim.odds.get_global_rect()) and aim.panel.get_global_rect().encloses(aim.odds_detail.get_global_rect()), "%s aim readout fully inside panel" % value)
	check(aim.confirm.text.count("\n") <= 1 and not aim.confirm.text.contains("% HIT") and not aim.confirm.text.contains("% CRIT"), "%s confirm has no duplicate numeric readout" % value)
	check(aim.aim_momentum.text == "●●●", "%s full momentum remains visible in aim" % value)
	check(not game.hud_controls.night.chips.visible, "%s no ghost hit text" % value)
	if aim.targets.get_child_count() >= 2:
		var original_target: int = game.target_id
		aim.targets.get_child(1).pressed.emit(); await process_frame
		check(game.target_id != original_target, "%s target icon switches target" % value)
		aim.targets.get_child(0).pressed.emit(); await process_frame
	geometry([phone.overlay, aim.panel, aim.target_row], str(value) + " aim")
	if value.x == 844: await shot("aim-844x390")
	game.queue_free(); await process_frame

func desktop() -> void:
	await size_to(Vector2i(1366, 768))
	var game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(game)
	for i in 8: await process_frame
	check(game.hud_controls.bar != null and game.hud_controls.phone == null, "desktop HUD available")
	await shot("desktop-1366x768")
	game.queue_free(); await process_frame

func audit() -> void:
	await size_to(Vector2i(844, 390))
	var flow = root.get_node("CampaignFlow")
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	var directory := OUT + "audit/"
	var menu = load("res://scenes/menu.tscn").instantiate(); root.add_child(menu)
	await process_frame; await shot("title", directory)
	menu.queue_free(); await process_frame
	var temple = load("res://scenes/temple.tscn").instantiate(); root.add_child(temple)
	for i in 5: await process_frame
	await shot("temple-home", directory)
	for entry in [["Arsenal", "armory"], ["Roster", "barracks"]]:
		temple._change_page(str(entry[0])); await process_frame; await shot(str(entry[1]), directory)
	temple.queue_free(); await process_frame
	var galaxy = load("res://scenes/galaxy.tscn").instantiate(); root.add_child(galaxy)
	for i in 4: await process_frame
	await shot("galaxy-map", directory)
	galaxy.queue_free(); await process_frame
	var promotion = preload("res://scripts/campaign/promotion_screen.gd").new(); root.add_child(promotion)
	promotion.setup(flow.campaign, "u1"); await process_frame; await shot("promotion", directory)
	promotion.queue_free(); await process_frame
	var briefing = load("res://scenes/briefing.tscn").instantiate(); root.add_child(briefing)
	for i in 4: await process_frame
	await shot("mission-briefing", directory)
	briefing.queue_free(); await process_frame
	var story = preload("res://scripts/story/story_engine.gd").new()
	var debrief = load("res://scenes/dialogue.tscn").instantiate(); debrief.set_campaign_state(story.state)
	debrief.show_scene(story.start_debrief({"mission_id":"relay", "won":true}))
	root.add_child(debrief)
	for i in 4: await process_frame
	await shot("debrief", directory)
	debrief.queue_free(); await process_frame

func run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "audit/"))
	if "--audit" in OS.get_cmdline_user_args():
		capture = true; await audit()
	else:
		await battle(Vector2i(844, 390))
		await battle(Vector2i(667, 375))
		await desktop()
	print("PHONEUI18 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
