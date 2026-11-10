extends SceneTree
const Base = preload("res://scripts/mission.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Mission = preload("res://scripts/combat_mission.gd")
const Shot = preload("res://scripts/shot.gd")
const Hud = preload("res://scripts/hud_controls.gd")
const HudPhone = preload("res://scripts/hud_phone.gd")
const Grid = preload("res://scripts/map_art_grid.gd")
const InputControls = preload("res://scripts/input_controls.gd")
const Targeting = preload("res://scripts/combat_targeting.gd")
const Threat = preload("res://scripts/decision22_threat.gd")
const CAPTURE_DIR = "/home/jess/projects/tw-logs/w22/decision"
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(reason)

func channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)

func contrast(foreground: Color, background: Color) -> float:
	var a := 0.2126 * channel(foreground.r) + 0.7152 * channel(foreground.g) + 0.0722 * channel(foreground.b)
	var b := 0.2126 * channel(background.r) + 0.7152 * channel(background.g) + 0.0722 * channel(background.b)
	return (maxf(a,b)+0.05)/(minf(a,b)+0.05)

func arena() -> RefCounted:
	var m: RefCounted = Mission.adopt(Base.new(7))
	for y in range(1, 25):
		for x in range(1, 25): m.set_tile(Vector2i(x, y), "_")
	var squad: Array = m.living("player")
	var enemy: Dictionary = m.living("enemy")[0]
	m.units.assign([squad[0], enemy])
	squad[0].x = 2; squad[0].y = 2; squad[0].ap = 2
	enemy.x = 7; enemy.y = 2; enemy.awake = true; enemy.spotted = true
	return m

func layout_check(view: Vector2i) -> void:
	# Graphics' headless fallback forces widths below 486 back to desktop; a real phone reports a window size.
	if view.x < 486:
		for connection in root.size_changed.get_connections():
			if connection.callable.get_object() == root.get_node("Graphics"):
				root.size_changed.disconnect(connection.callable)
	DisplayServer.window_set_size(view); root.size = view; root.content_scale_size = view
	await process_frame
	var layout_game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(layout_game)
	layout_game.set_process(false)
	for i in 8: await process_frame
	var layout_phone = layout_game.hud_controls.phone
	check(layout_phone != null, "phone HUD exists at %s" % view)
	if layout_phone == null:
		layout_game.queue_free(); await process_frame; return
	var scale: float = float(view.x) / layout_phone.overlay.size.x
	var controls: Array[Control] = [layout_phone.end_button, layout_phone.overlay.find_child("PhoneMenu", true, false), layout_phone.unit_card, layout_phone.overlay.find_child("UnitPrevious", true, false), layout_phone.overlay.find_child("UnitNext", true, false)]
	for camera_button in layout_phone.camera_rail.get_children(): controls.append(camera_button)
	for control in controls:
		var rect: Rect2 = control.get_global_rect()
		check(rect.size.x * scale >= 44 and rect.size.y * scale >= 44, "%s has 44px target at %s" % [control.name, view])
		check(rect.position.x * scale >= 12 and rect.end.x * scale <= view.x - 12, "%s respects 12px side margin at %s: %s" % [control.name, view, rect])
	var end_rect: Rect2 = layout_phone.end_button.get_global_rect()
	var menu_rect: Rect2 = controls[1].get_global_rect()
	check(not end_rect.intersects(menu_rect), "End Turn and menu do not overlap at %s" % view)
	check(layout_phone.odds_hit.get_theme_font_size("font_size") * scale >= 24 and layout_phone.odds_modifiers.get_theme_font_size("font_size") * scale >= 14, "phone odds meet 14px text at %s" % view)
	check(layout_game.objective_label.get_theme_font_size("font_size") * scale >= 14 and layout_phone.action_name.get_theme_font_size("font_size") * scale >= 14, "objective and route text meet 14px at %s" % view)
	var sample_threat := {"exposed_units": [1,2], "objective_risk": 4, "pending_groups": [{"label":"West"}], "villain": {}}
	layout_phone.last_threat = sample_threat; layout_phone.threat_chip.visible = true
	layout_phone._relayout(); await process_frame
	var chip_rect: Rect2 = layout_phone.threat_chip.get_global_rect()
	end_rect = layout_phone.end_button.get_global_rect(); menu_rect = controls[1].get_global_rect()
	check(chip_rect.end.x <= end_rect.position.x and end_rect.end.x <= menu_rect.position.x, "D threat chip stays beside End Turn at %s" % view)
	check(menu_rect.end.x * scale <= view.x - 12 and chip_rect.size.y <= 44, "D threat chip keeps header within phone at %s: chip %s menu %s scale %.2f" % [view, chip_rect, menu_rect, scale])
	check(layout_phone.threat_chip.text.count("\n") <= 1 and layout_phone.threat_chip.get_theme_font_size("font_size") * scale >= 14, "D threat chip is two readable lines at %s" % view)
	layout_phone.last_threat = {}; layout_phone.threat_chip.visible = false; layout_phone._relayout()
	var shooter: Dictionary = {}
	for unit in layout_game.mission.living("player"):
		if "shoot" in unit.get("kit", []): shooter = unit; break
	var foe: Dictionary = layout_game.mission.living("enemy")[0]
	foe.awake = true; foe.spotted = true
	if view.x < 600:
		layout_game.selected_id = int(shooter.id); layout_game.action = "move"
		var reachable: Dictionary = layout_game.mission.reach_tiles(shooter, 1)
		for tile in reachable.costs:
			if tile != Shot.pos(shooter): layout_game.preview_tile = tile; break
		layout_game._refresh_highlights(); layout_phone.refresh(); await process_frame
		check(layout_phone.odds_plate.visible and layout_phone.odds_hit.text.contains("ACTION"), "portrait move cost is visible above tray")
		check(layout_phone.odds_badge.get_theme_font_size("font_size") >= 14, "portrait destination risk uses readable text")
	layout_game.selected_id = int(shooter.id); layout_game.target_id = int(foe.id); layout_game.action = "shoot"
	layout_game._refresh(); await process_frame
	var aim = layout_game.hud_controls.aim_ui
	for control in [aim.panel, aim.target_row, aim.confirm, aim.cancel]:
		var rect: Rect2 = control.get_global_rect()
		check(rect.position.x * scale >= 12 and rect.end.x * scale <= view.x - 12, "%s aim control inside phone at %s: %s" % [control.name, view, rect])
	check(not aim.confirm.get_global_rect().intersects(aim.cancel.get_global_rect()) and not aim.panel.get_global_rect().intersects(aim.target_row.get_global_rect()), "aim controls are separate at %s" % view)
	check(not layout_phone.unit_plate.visible and layout_phone.odds_plate.visible, "portrait readout clears lower aim controls at %s" % view)
	layout_game.queue_free(); await process_frame

func capture_after(view: Vector2i) -> void:
	DisplayServer.window_set_size(view); root.size = view; root.content_scale_size = view
	await process_frame
	DirAccess.make_dir_recursive_absolute(CAPTURE_DIR)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://decision22-capture-%d.json" % OS.get_process_id()
	var campaign = Campaign.new("normal")
	campaign.select_mission(0); campaign.state.flow_stage = "battle"
	flow.campaign = campaign; flow.story = campaign.story; flow.active = true
	var game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(game)
	for i in 20: await process_frame
	flow.active = false; game.demo_mode = true; game.animate_headless = true
	game.phase_banner.hide()
	var actor: Dictionary = {}
	for unit in game.mission.living("player"):
		if "shoot" in unit.get("kit", []): actor = unit; break
	if actor.is_empty(): actor = game.mission.living("player")[0]
	game._select(int(actor.id)); game._choose_action("move")
	var reach: Dictionary = game.mission.reach_tiles(actor, 1)
	var destination := Shot.pos(actor)
	for tile in reach.costs:
		if tile != Shot.pos(actor) and Shot.pos(actor).distance_to(tile) >= 2 and game.mission.tile(tile) != "#": destination = tile; break
	game.preview_tile = destination; game.hovered = destination; game._refresh_highlights(true)
	await create_timer(1.8).timeout
	root.get_texture().get_image().save_png(CAPTURE_DIR + "/after-move-%dx%d.png" % [view.x, view.y])
	game._move_selected(destination)
	var deadline := Time.get_ticks_msec() + 20000
	while game.player_attack_pending and Time.get_ticks_msec() < deadline: await process_frame
	var enemy: Dictionary = game.mission.living("enemy")[0]
	enemy.awake = true; enemy.spotted = true
	for offset in [Vector2i(2,-2),Vector2i(3,-1),Vector2i(2,1),Vector2i(-2,-1),Vector2i(1,2)]:
		enemy.x = int(actor.x) + offset.x; enemy.y = int(actor.y) + offset.y
		if game.mission.in_bounds(Shot.pos(enemy)) and not InputControls.valid_targets(game.mission,actor,"shoot").is_empty(): break
	game._refresh_figures(); game._select(int(actor.id)); game._choose_action("shoot")
	if game.target_id < 0: game.target_id = int(enemy.id); game.action = "shoot"; game._frame_target(); game._refresh()
	for i in 20: await process_frame
	print("CAPTURE RECTS ", game.hud_controls.aim_ui.panel.get_global_rect(), " ", game.hud_controls.aim_ui.confirm.get_global_rect(), " ", game.hud_controls.aim_ui.cancel.get_global_rect(), " root=", root.size, " overlay=", game.hud_controls.phone.overlay.size)
	root.get_texture().get_image().save_png(CAPTURE_DIR + "/after-aim-%dx%d.png" % [view.x, view.y])
	game.queue_free(); await process_frame

func run() -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await capture_after(Vector2i(390,844) if "--portrait" in OS.get_cmdline_user_args() else Vector2i(844,390))
		print("DECISION22 CAPTURE COMPLETE"); quit(); return
	if "--portrait" in OS.get_cmdline_user_args():
		await layout_check(Vector2i(390,844))
		print("DECISION22 TEST RESULTS: %d checks, %d failures" % [checks, failures])
		quit(1 if failures else 0); return
	DisplayServer.window_set_size(Vector2i(844,390))
	root.size = Vector2i(844,390); root.content_scale_size = Vector2i(844,390)
	await process_frame
	var game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(game)
	await process_frame
	game.demo_mode = true; game.set_process(false)
	var m: RefCounted = arena(); game.mission = m
	var actor: Dictionary = m.living("player")[0]
	var enemy: Dictionary = m.living("enemy")[0]
	game.selected_id = int(actor.id); game.action = "move"; game.target_id = -1
	game._refresh()
	var phone = game.hud_controls.phone
	check(phone != null, "landscape phone HUD exists")
	check(is_equal_approx(Hud.move_fill(1).a, 0.24) and is_equal_approx(Hud.move_fill(2).a, 0.24), "grid fills are dimmed equally")
	check(0.12 * Grid.focus_alpha(Vector3(8, 0, 8), Vector2i(2, 2)) <= 0.08, "far grid alpha stays below 0.08 behind units")
	check(contrast(Color("ef6a5d"), Color("101b26")) >= 4.5 and contrast(Color("60b9ff"), Color("101b26")) >= 4.5, "flank and route text pass AA contrast")
	check(Hud.move_color(1) == Color("60b9ff") and Hud.move_color(2) == Color("ffd16a"), "one and two action edges keep distinct colors")
	var edge := Node3D.new(); game.add_child(edge)
	var block := {"costs": {Vector2i(3,3): 1, Vector2i(4,3): 1, Vector2i(3,4): 1, Vector2i(4,4): 1}}
	for p in block.costs: game.hud_controls._range_edge(edge, p, 1, block, block)
	check(edge.get_child_count() == 8, "four tile block draws perimeter edges only")
	var walk: Dictionary = InputControls.move_preview(m, actor, Vector2i(3,2))
	var dash: Dictionary = InputControls.move_preview(m, actor, Vector2i(2 + int(actor.mob) + 1,2))
	check(int(walk.ap) == 1 and int(dash.ap) == 2, "route costs preserve XCOM action split")
	game.preview_tile = Vector2i(3, 2); game._refresh_highlights()
	var endpoint := 0; var arrow_wings := 0; var route_width := 0.0
	for node in game.hover_highlights.get_children():
		if node is MeshInstance3D and node.mesh is BoxMesh:
			if is_equal_approx(node.mesh.size.x, 0.34): endpoint += 1
			if is_equal_approx(node.mesh.size.x, 0.11): arrow_wings += 1
			if is_equal_approx(node.mesh.size.x, 0.15): route_width = node.mesh.size.x
	check(endpoint >= 1 and arrow_wings == 2 and route_width >= 0.15, "hover route has thick segment, arrow and endpoint marker")
	var shields := Node3D.new(); game.add_child(shields)
	game.hud_controls._shield(shields, Vector2i(3,2), Vector2i.UP, true)
	game.hud_controls._shield(shields, Vector2i(3,2), Vector2i.RIGHT, false)
	var vertices: PackedVector3Array = shields.get_child(0).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var lo := 99.0; var hi := -99.0
	for vertex in vertices: lo = minf(lo, vertex.x); hi = maxf(hi, vertex.x)
	check(shields.get_child_count() == 2 and hi - lo > 0.60, "full and half shields are scaled for phone")
	var preview: Dictionary = InputControls.move_preview(m, actor, Vector2i(4,2))
	check(preview.seen_by.size() == 1, "visible enemy LOS appears at hovered destination")
	check(HudPhone.compact_names(["Sith Trooper", "Sith Trooper", "Scout"]) == "Sith Trooper ×2, Scout", "portrait preview groups visible enemies by name")
	enemy.spotted = false; enemy.awake = true
	preview = InputControls.move_preview(m, actor, Vector2i(4,2))
	check(preview.seen_by.is_empty() and preview.flanks.is_empty(), "unspotted enemy never leaks into destination forecast")
	enemy.detected = true; preview = InputControls.move_preview(m, actor, Vector2i(4,2))
	check(preview.seen_by.size() == 1, "detected enemy is a known destination threat")
	enemy.detected = false
	enemy.spotted = true
	m.set_tile(Vector2i(4,3), "c"); enemy.x = 6; enemy.y = 4
	preview = InputControls.move_preview(m, actor, Vector2i(4,4))
	check(preview.flanks.size() == 1 and preview.seen_by.size() == 1, "hovered destination identifies a visible flanker")
	enemy.spotted = false; preview = InputControls.move_preview(m, actor, Vector2i(4,4))
	check(preview.flanks.is_empty() and preview.seen_by.is_empty(), "hidden flanker is excluded")
	enemy.spotted = true; enemy.x = 7; enemy.y = 2; m.set_tile(Vector2i(4,3), "_")
	var flank_probe: Dictionary = {"hit": 80, "cover": 0, "flanked": true, "lines": [["Base aim", 80], ["No cover", 0], ["High ground", 20], ["Range", -20]]}
	var decision: Dictionary = Targeting.decision_summary(flank_probe, "Scout")
	check(decision.hit == 80 and decision.target == "Scout" and decision.badge == "FLANKED", "hit, named target, flank badge are explicit")
	check(decision.modifiers.size() == 2 and decision.modifiers[0] == "NO COVER +0" and decision.modifiers[1] == "HEIGHT +20", "top two cover and height modifiers show without tap")
	flank_probe.flanked = false; decision = Targeting.decision_summary(flank_probe, "Scout")
	check(decision.badge == "NO COVER", "no cover has an unmistakable badge")
	var data: Dictionary = Shot.calculate(m, actor, enemy)
	decision = Targeting.decision_summary(data, str(enemy.name))
	check(decision.hit == int(data.hit) and decision.modifiers.size() >= 1, "readout uses live combat odds")
	game.action = "shoot"; game.target_id = int(enemy.id); game._refresh(); await process_frame
	check(phone.odds_plate.visible and phone.odds_hit.text.contains("%d%%" % int(data.hit)), "phone displays large live hit odds: %s vs %s" % [phone.odds_hit.text, data.hit])
	check(phone.odds_title.text == str(enemy.name).to_upper() and phone.odds_badge.text.contains("COVER"), "phone shows target and cover badge")
	check(phone.odds_modifiers.text.contains("COVER"), "phone displays modifier without opening details")
	enemy.spotted = false; enemy.awake = true; phone._refresh_odds()
	check(phone.odds_plate.visible, "active known aim target keeps odds visible")
	enemy.spotted = true
	check(game.hud_controls.night.target_details.text.contains("COVER"), "desktop displays modifier without opening ODDS")
	var forecast := {"exposed_units": [1,2], "objective_risk": 4, "pending_groups": [{"label":"West"}], "villain": {}}
	check(Threat.chip(forecast).contains("2 EXPOSED") and Threat.chip(forecast).contains("OBJ −4") and Threat.chip(forecast).contains("+1 IN") and Threat.chip(forecast).count("\n") == 1, "End Turn chip fits two lines while counting D's numeric threats")
	check(Threat.phone_chip(forecast) == "OBJ\n−4" and Threat.phone_chip({"exposed_units":[1],"objective_risk":0}) == "1\nEXPOSED", "portrait chip prioritizes objective and exposed threats")
	var shot_script: Script = load("res://scripts/shot.gd")
	check(shot_script.has_method("calculate"), "guarded Script.has_method detects static cross-lane APIs")
	check(Threat.summary(m).is_empty() and not phone.threat_chip.visible, "threat chip hides while D API is unavailable")
	check(Threat.reveal(m, []).is_empty(), "reveal hook stays guarded before D merges")
	game.hud_controls.night.show_reveal("Patrol: 3 troopers")
	check(game.hud_controls.night.phase_plate.visible and game.hud_controls.night.phase_text.text == "PATROL: 3 TROOPERS", "reveal title hook displays D's title")
	game.queue_free(); await process_frame
	await layout_check(Vector2i(844,390))
	DisplayServer.window_set_size(Vector2i(1366,768)); root.size = Vector2i(1366,768); root.content_scale_size = Vector2i(1366,768)
	await process_frame
	var desktop_game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(desktop_game)
	for i in 8: await process_frame
	check(desktop_game.hud_controls.phone == null and desktop_game.hud_controls.bar != null, "desktop layout remains available")
	check(not desktop_game.hud_controls.desktop_threat_chip.visible, "desktop End Turn chip hides before D API merges")
	desktop_game.queue_free(); await process_frame
	print("DECISION22 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
