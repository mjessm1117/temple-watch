extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0
var capture := false

func _initialize() -> void:
	call_deferred("run")

func fail(path: String, reason: String) -> void:
	failures += 1
	print("TAP16 FAIL ", path, ": ", reason)

func scan(screen: Node, title: String) -> void:
	await process_frame
	var buttons: Array[BaseButton] = []
	var surfaces: Array[Control] = []
	_collect(screen, buttons)
	_collect_surfaces(screen, surfaces)
	var view := Rect2(Vector2.ZERO, Vector2(root.size))
	for button in buttons:
		var rect := button.get_global_rect()
		if not _visible_rect(button, view).has_area(): continue
		checks += 1
		var phone_hud_button := "PhoneBattleHUD" in str(button.get_path())
		var pixel_scale := 1.2 if phone_hud_button else 1.0
		if rect.size.x * pixel_scale < 43.9 or rect.size.y * pixel_scale < 43.9:
			fail(str(button.get_path()), "%s hit rect %s below 44x44" % [title, rect])
		var primary: bool = button.name in ["PhoneEndTurn", "FireButton", "GalaxyOverview", "Tab_Galaxy", "MoreCommands", "MenuCommand"] or button.text.strip_edges() in ["MOVE", "FIRE", "OVERWATCH", "CANCEL", "END TURN", "DEPLOY →", "ROOMS", "MISSION BRIEFING  →", "←  TEMPLE"]
		if button.name.begins_with("Tab_") or button.text.begins_with("SITH INTELLIGENCE"): primary = true
		if button.get("ability_id") != null and str(button.get("ability_id")) in ["move", "shoot", "overwatch"]: primary = true
		var primary_height := 48 if phone_hud_button and button.get("ability_id") != null else 44 if button.name == "PhoneEndTurn" else 50 if button.name in ["FireButton", "AimCancel"] else 56
		if primary and rect.size.y * pixel_scale < primary_height - 0.1: fail(str(button.get_path()), "%s primary height %s below %d" % [title, rect.size.y * pixel_scale, primary_height])
		if button.name != "UnitCard" and button.has_theme_font_size_override("font_size") and button.get_theme_font_size("font_size") < 14:
			fail(str(button.get_path()), "%s font below 14" % title)
	for surface in surfaces:
		if not _visible_rect(surface, view).has_area(): continue
		checks += 1
		var rect := surface.get_global_rect()
		if rect.size.x < 44 or rect.size.y < 44:
			fail(str(surface.get_path()), "%s custom tap rect %s below 44x44" % [title, rect])
	var hit_controls: Array[Control] = []
	for button in buttons: hit_controls.append(button)
	for surface in surfaces: hit_controls.append(surface)
	for i in hit_controls.size():
		var a := _visible_rect(hit_controls[i], view)
		if not a.has_area(): continue
		for j in range(i + 1, hit_controls.size()):
			var b := _visible_rect(hit_controls[j], view)
			if not b.has_area(): continue
			if hit_controls[i].is_ancestor_of(hit_controls[j]) or hit_controls[j].is_ancestor_of(hit_controls[i]): continue
			var grouped := hit_controls[i].get_parent() == hit_controls[j].get_parent() and hit_controls[i].get_parent() is Container and (title == "battle" or title == "aim")
			var phone_pair := "PhoneBattleHUD" in str(hit_controls[i].get_path()) and "PhoneBattleHUD" in str(hit_controls[j].get_path())
			var gap_min := 6.5 if phone_pair else 7.9 # 6.5 logical px is about 8 physical px.
			if a.intersects(b): fail(str(hit_controls[i].get_path()), "%s overlaps %s: %s / %s" % [title, hit_controls[j].get_path(), a, b])
			elif not grouped and a.end.y > b.position.y and b.end.y > a.position.y and minf(absf(a.end.x - b.position.x), absf(b.end.x - a.position.x)) < gap_min:
				fail(str(hit_controls[i].get_path()), "%s horizontal gap below 8 to %s" % [title, hit_controls[j].get_path()])
			elif not grouped and a.end.x > b.position.x and b.end.x > a.position.x and minf(absf(a.end.y - b.position.y), absf(b.end.y - a.position.y)) < 7.9:
				fail(str(hit_controls[i].get_path()), "%s vertical gap below 8 to %s" % [title, hit_controls[j].get_path()])
	print("TAP16 ", title, " visible buttons=", buttons.size(), " custom surfaces=", surfaces.size())

func _collect(node: Node, output: Array[BaseButton]) -> void:
	if node is BaseButton and node.is_visible_in_tree() and not node.disabled and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		output.append(node)
	for child in node.get_children(): _collect(child, output)

func _collect_surfaces(node: Node, output: Array[Control]) -> void:
	if node is Control and not node is BaseButton and node.is_visible_in_tree() and node.mouse_filter == Control.MOUSE_FILTER_STOP:
		if not node.get_signal_connection_list("gui_input").is_empty(): output.append(node)
	for child in node.get_children(): _collect_surfaces(child, output)

func _visible_rect(control: Control, viewport_rect: Rect2) -> Rect2:
	var area := control.get_global_rect().intersection(viewport_rect)
	var parent := control.get_parent()
	while parent is Control:
		if parent.clip_contents or parent is ScrollContainer:
			area = area.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return area

func check_card_names(squad: Node, title: String) -> void:
	for id in squad.cards:
		var card: PanelContainer = squad.cards[id]
		var button: Button = card.get_child(0).get_child(0)
		var label: Label = button.get_node("SoldierName")
		var full_name := str(squad.flow.session().soldier(str(id)).n)
		var shown := label.text
		checks += 3
		if label.horizontal_alignment != HORIZONTAL_ALIGNMENT_LEFT or label.position.x < 42.0:
			fail(str(label.get_path()), "%s name does not start right of portrait" % title)
		if not full_name.begins_with(shown.trim_suffix("…")):
			fail(str(label.get_path()), "%s name clipped at start: %s / %s" % [title, shown, full_name])
		var width := ThemeDB.fallback_font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		if width > label.size.x + 0.5 and not shown.ends_with("…"):
			fail(str(label.get_path()), "%s name exceeds label: %s > %s" % [title, width, label.size.x])

func check_roster_rows(squad: Node) -> void:
	for id in squad.choices:
		var button: Button = squad.choices[id]
		var full_name := str(squad.flow.session().soldier(str(id)).n)
		var shown := button.text.trim_suffix("  ✓")
		checks += 2
		if button.alignment != HORIZONTAL_ALIGNMENT_LEFT or not full_name.begins_with(shown.trim_suffix("…")):
			fail(str(button.get_path()), "swap roster name clipped at start: %s / %s" % [shown, full_name])
		var available := button.size.x - 50.0
		var width := ThemeDB.fallback_font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		if width > available + 0.5 and not shown.ends_with("…"):
			fail(str(button.get_path()), "swap roster name exceeds width: %s > %s" % [width, available])

func check_banner(game: Node) -> void:
	var banner: PanelContainer = game.hud_controls.night.phase_plate
	var header: Control = game.hud_controls.phone.overlay.get_child(0)
	var action_strip: Control = game.hud_controls.phone.ability_tray
	banner.visible = true
	banner.position.y = 116.0
	await process_frame
	checks += 3
	if banner.get_global_rect().intersects(header.get_global_rect()):
		fail(str(banner.get_path()), "turn banner intersects phone header")
	if banner.get_global_rect().intersects(action_strip.get_global_rect()):
		fail(str(banner.get_path()), "turn banner intersects action strip")
	if banner.get_global_rect().intersection(Rect2(Vector2.ZERO, Vector2(root.size))) != banner.get_global_rect():
		fail(str(banner.get_path()), "turn banner outside viewport: %s / %s" % [banner.get_global_rect(), root.size])

func shot(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	var stage := "before" if "--before" in OS.get_cmdline_user_args() else "after"
	var path := "res://../docs/godot/shots/w16-tap-%s-%s.png" % [stage, name.trim_prefix("after-")]
	if root.get_texture().get_image().save_png(path) != OK: fail(path, "screenshot save failed")

func run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	root.size = Vector2i(390, 844) if "--portrait" in OS.get_cmdline_user_args() else Vector2i(844, 390)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	print("TAP16 geometry root=", root.size, " physical=", DisplayServer.window_get_size(), " phone=", preload("res://scripts/phone_layout.gd").narrow(preload("res://scripts/phone_layout.gd").window_size()))
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://tap16-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 5: await process_frame
	await scan(game, "battle")
	await check_banner(game)
	await shot("banner")
	game.hud_controls.night.phase_plate.hide()
	var phone_hud = game.hud_controls.phone
	for card in ["unit", "target", "more", "menu"]:
		phone_hud._toggle(card)
		await scan(phone_hud.popup, "battle-" + card)
	phone_hud._show_settings()
	await scan(phone_hud.popup, "battle-settings")
	phone_hud._close()
	var pick = preload("res://scripts/input_controls.gd")
	var actor: Dictionary = game.mission.living("player")[0]
	var tile := Vector2i(int(actor.x), int(actor.y))
	var at: Vector2 = game.camera.unproject_position(Vector3(tile.x, game.Shot.elevation(game.mission, tile) * 0.7 + 1.0, tile.y))
	checks += 2
	if pick.near_unit(game, at + Vector2(27, 0), [actor]).is_empty(): fail("battle/unit", "27 px near tap missed")
	if not pick.near_unit(game, at + Vector2(29, 0), [actor]).is_empty(): fail("battle/unit", "29 px outside tap selected")
	await shot("after-battle-bar")
	game.action = "shoot"; game.target_id = int(game.mission.living("enemy")[0].id); game._refresh()
	for i in 5: await process_frame
	await scan(game, "aim")
	game.hud_controls.night.pause_back.show()
	await scan(game.hud_controls.night.pause_panel, "pause")
	game.hud_controls.night.settings_box.show()
	await scan(game.hud_controls.night.pause_panel, "settings")
	game.queue_free(); await process_frame
	var temple = load("res://scenes/temple.tscn").instantiate()
	root.add_child(temple)
	for i in 5: await process_frame
	await scan(temple, "temple-home")
	await shot("after-temple-home")
	temple._toggle_rooms(); await scan(temple.room_picker, "temple-rooms")
	temple._toggle_rooms()
	temple.queue_free(); await process_frame
	var galaxy = load("res://scenes/galaxy.tscn").instantiate()
	root.add_child(galaxy)
	for i in 5: await process_frame
	await scan(galaxy, "galaxy")
	galaxy._select(0)
	await scan(galaxy, "galaxy-briefing")
	galaxy.queue_free(); await process_frame
	var squad = load("res://scenes/squad.tscn").instantiate()
	root.add_child(squad)
	for i in 5: await process_frame
	await scan(squad, "roster")
	check_card_names(squad, "roster")
	squad.inspect(0)
	for i in 5: await process_frame
	await scan(squad, "armory")
	check_card_names(squad, "armory")
	await shot("after-armory")
	squad._tab("roster")
	for i in 2: await process_frame
	check_roster_rows(squad)
	squad.queue_free(); await process_frame
	var story = load("res://scenes/briefing.tscn").instantiate()
	root.add_child(story)
	for i in 5: await process_frame
	story._skip_dialogue()
	await scan(story, "story-choice")
	story.queue_free(); await process_frame
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("TAP16 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
