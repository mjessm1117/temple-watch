extends SceneTree

const Combat = preload("res://scripts/combat_mission.gd")
const Controls = preload("res://scripts/input_controls.gd")
const Grid = preload("res://scripts/map_art_grid.gd")
const Objective = preload("res://scripts/w36route_objective.gd")
const Overwatch = preload("res://scripts/w36route_overwatch.gd")
const Shot = preload("res://scripts/shot.gd")
const OUT := "/home/jess/projects/tw-logs/w36/lane-route/"
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var path := OUT + name + ".png"
	check(root.get_texture().get_image().save_png(path) == OK, "capture " + name)

func run() -> void:
	var rescue := Combat.new(17)
	rescue.setup_combat()
	var selected: Dictionary = rescue.living("player")[0]
	var start: Dictionary = Objective.target(rescue, selected)
	check(start.get("tile") == Shot.pos(rescue.prisoner) and str(start.get("title", "")).contains("MIRA"), "turn 1 points to Mira")
	rescue.prisoner.freed = true
	var evac: Dictionary = Objective.target(rescue, selected)
	var evac_tiles: Array = rescue.spec.evac.map(func(p): return preload("res://scripts/map_catalog.gd").point(p))
	check(evac_tiles.has(evac.get("tile")) and evac.get("title") == "EVAC", "freed captive switches cue to evac")
	rescue.prisoner.freed = false
	for y in range(1, 14):
		for x in range(1, 14): rescue.set_tile(Vector2i(x, y), ".")
	selected.x = 2; selected.y = 5; selected.ap = 2
	for enemy in rescue.living("enemy"):
		enemy.x = 12; enemy.y = 12; enemy.awake = false; enemy.overwatch = false
	var watcher: Dictionary = rescue.living("enemy")[0]
	watcher.x = 8; watcher.y = 5; watcher.awake = true; watcher.spotted = true
	watcher.overwatch = true; watcher.ammo = 4
	var lane_tile := Vector2i(6, 5)
	var outside := Vector2i(1, 1)
	var lane: Dictionary = Overwatch.lane(rescue, watcher)
	check(not lane.is_empty() and rescue.w36_overwatch_watchers_for(lane.to).has(watcher), "armed lane ends on a reacting tile")
	check(rescue.w36_overwatch_watchers_for(lane_tile).has(watcher), "watchers hook returns lane watcher")
	check(rescue.w36_overwatch_watchers_for(outside).is_empty(), "watchers hook excludes outside tile")
	var friendly: Dictionary = rescue.living("player")[2]
	var friendly_old: Vector2i = Shot.pos(friendly)
	friendly.x = 4; friendly.y = 5; friendly.overwatch = true; friendly.ammo = 4
	rescue.phase = "enemy"
	check(rescue.w36_overwatch_watchers_for(lane_tile).has(friendly), "enemy phase queries friendly reaction lane")
	rescue.phase = "player"; friendly.overwatch = false; friendly.x = friendly_old.x; friendly.y = friendly_old.y
	var risk: Dictionary = Controls.move_preview(rescue, selected, lane_tile)
	var markers: Array = Grid.first_threat_markers36(risk)
	check(markers.size() == 1 and markers[0].tile == risk.first_danger_tile and markers[0].kind == "first_threat", "one marker at first threatened path tile")
	watcher.awake = false; watcher.overwatch = false
	var safe: Dictionary = Controls.move_preview(rescue, selected, lane_tile)
	check(safe.get("first_danger_tile", Vector2i(-1, -1)).x < 0 and Grid.first_threat_markers36(safe).is_empty(), "safe path has no threat marker")
	root.size = Vector2i(844, 390); root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	var game: Node = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 18: await process_frame
	var grid: Node = null
	for child in game.highlights.get_children():
		if child.has_method("move_preview_state28"): grid = child; break
	check(grid != null, "route renderer exists")
	if grid == null: quit(1); return
	var cue: Control = grid.objective_cue36
	check(cue != null and cue.cue.get("tile") == Shot.pos(game.mission.prisoner), "real rescue spawn has offscreen Mira cue")
	check(int(cue.cue.get("distance", 0)) > 0 and cue.cue.get("point") is Vector2, "edge cue includes tile distance and arrow position")
	check(cue.mouse_filter == Control.MOUSE_FILTER_IGNORE, "objective cue does not take touch input")
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("DRAW CALLS 844x390: ", draws)
	if DisplayServer.get_name() != "headless": check(draws > 0 and draws <= 150, "844x390 within W33 draw budget")
	await capture("after-844x390")
	var old_pivot: Vector3 = game.pivot
	var mira: Vector2i = Shot.pos(game.mission.prisoner)
	game.pivot = Vector3(mira.x, 0, mira.y); game._update_camera()
	for i in 2: await process_frame
	check(grid.objective_label36.visible and cue.cue.is_empty(), "Mira becomes world marker when on screen")
	game.pivot = old_pivot; game._update_camera()
	game.mission.prisoner.freed = true; game.mission.objective_state.phase = "evac"
	for i in 2: await process_frame
	check(Objective.target(game.mission, game.mission.unit_by_id(game.selected_id)).title == "EVAC" and grid.evac_label28.visible, "real mission shows evac after free")
	await capture("after-evac-844x390")
	game.mission.prisoner.freed = false; game.mission.objective_state.phase = "primary"
	for i in 2: await process_frame
	var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
	var reach: Dictionary = game.mission.reach_tiles(actor, 1)
	var destination := Vector2i(-1, -1)
	for tile in reach.costs:
		if tile != Shot.pos(actor) and str(game.mission.decision_preview27(int(actor.id), tile).get("cover", "none")) in ["full", "half"]:
			destination = tile; break
	if destination.x < 0:
		for tile in reach.costs:
			if tile != Shot.pos(actor) and tile.distance_to(Shot.pos(actor)) >= 2.0:
				destination = tile; break
	check(destination.x >= 0, "visible move destination exists")
	if destination.x >= 0:
		game.action = "move"; game.preview_tile = destination
		game._refresh_highlights(); game._refresh()
		for i in 3: await process_frame
		check(grid.route_markers_current24.size() <= 1, "real preview contains at most one risk marker")
		check(grid.cover_focus_text36.visible and grid.cover_focus_text36.text.contains("COVER"), "destination cover is focal")
		check(grid.cover_full33.material_override.albedo_color.a < 0.5 and grid.reach_view28.multimesh.mesh.size.y == 1.0, "general cover glyphs dimmed and border batched")
		if DisplayServer.get_name() != "headless": check(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)) <= 150, "move preview within W33 draw budget")
		await capture("after-preview-844x390")
	var live_enemy: Dictionary = game.mission.living("enemy")[0]
	actor.x = 4; actor.y = 20
	live_enemy.x = 8; live_enemy.y = 20; live_enemy.awake = true; live_enemy.spotted = true
	for x in range(3, 9): game.mission.set_tile(Vector2i(x, 20), ".")
	game._refresh_figures()
	game.preview_tile = Vector2i(6, 20)
	game.pivot = Vector3(5, 0, 18); game._update_camera()
	game._refresh_highlights(); game._refresh()
	for i in 3: await process_frame
	var live_risk: Dictionary = Controls.move_preview(game.mission, actor, game.preview_tile)
	check(not live_risk.is_empty() and grid.route_markers_current24.size() == 1 and grid.route_markers_current24[0].tile == live_risk.first_danger_tile, "live preview marks exactly first LoS tile")
	await capture("after-danger-844x390")
	live_enemy.awake = false
	for i in 2: await process_frame
	check(grid.route_markers_current24.is_empty(), "live safe preview clears threat marker")
	game.pivot = old_pivot; game._update_camera()
	game.action = "overwatch"; game.preview_tile = Vector2i(-1, -1)
	game.selected_id = int(game.mission.living("player")[2].id)
	game._refresh_highlights(); game._refresh()
	var armed: Dictionary = game.mission.unit_by_id(game.selected_id)
	armed.overwatch = true; armed.ammo = 4
	var enemy: Dictionary = game.mission.living("enemy")[0]
	enemy.x = int(armed.x) + 4; enemy.y = int(armed.y)
	enemy.awake = true; enemy.spotted = true
	for x in range(int(armed.x) + 1, int(enemy.x) + 1): game.mission.set_tile(Vector2i(x, int(armed.y)), ".")
	game._refresh_figures()
	for i in 5: await process_frame
	print("LANE BOUNDS: ", grid.overwatch_lane36.mesh.get_aabb())
	check(grid.overwatch_lane36.visible, "armed watcher displays directional lane")
	var marker_root: Node3D = game.terrain.get_child(0).get("marker_root")
	var old_arcs := 0
	var hidden_arcs := 0
	for visual in marker_root.get_children():
		if not visual is MeshInstance3D or not visual.mesh is ImmediateMesh: continue
		var center: Vector3 = visual.mesh.get_aabb().get_center()
		if Vector2(center.x, center.z).distance_to(Vector2(armed.x, armed.y)) > 0.25: continue
		old_arcs += 1
		if not visual.visible: hidden_arcs += 1
	if DisplayServer.get_name() != "headless": check(old_arcs == hidden_arcs, "old broad overwatch circle hidden")
	if DisplayServer.get_name() != "headless": check(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)) <= 150, "overwatch lane within W33 draw budget")
	await create_timer(2.0).timeout
	await capture("after-overwatch-844x390")
	root.size = Vector2i(390, 844); root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	for i in 3: await process_frame
	if DisplayServer.get_name() != "headless": check(cue.size == cue.get_viewport_rect().size and cue.size.x < cue.size.y, "objective cue fits portrait")
	await capture("after-390x844")
	print("W36_ROUTE: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	quit(1 if failures else 0)
