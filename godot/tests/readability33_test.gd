extends SceneTree
const Read33 = preload("res://scripts/w33d_readability.gd")
const Shot = preload("res://scripts/shot.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Art = preload("res://scripts/map_presentation.gd")
var checks := 0
var failures := 0

class Tactics33:
	extends RefCounted
	func w33b_tile_tactics(_tile: Vector2i) -> Dictionary:
		return {"overwatch": 2, "flanked_by": 3}

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func tap(game: Node, point: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0; event.position = point; event.pressed = down
		game.cam.touch.handle(event)

func luminance(color: Color) -> float:
	var c := [color.r, color.g, color.b]
	for i in 3: c[i] = c[i] / 12.92 if c[i] <= 0.04045 else pow((c[i] + 0.055) / 1.055, 2.4)
	return c[0] * 0.2126 + c[1] * 0.7152 + c[2] * 0.0722

func contrast(a: Color, b: Color) -> float:
	var top := maxf(luminance(a), luminance(b))
	var bottom := minf(luminance(a), luminance(b))
	return (top + 0.05) / (bottom + 0.05)

func run() -> void:
	Phone.test_touch = 1; Phone.test_mobile = 1; Phone.test_scale = 1
	root.size = Vector2i(844, 390); root.content_scale_size = root.size
	var flow: Node = root.get_node("CampaignFlow")
	flow.save_path = "user://readability33-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	var game: Node = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 8: await process_frame
	var grid: Node = game.highlights.get_node_or_null("MapArtGrid")
	if grid == null:
		for child in game.highlights.get_children():
			if child.has_method("move_preview_state28"): grid = child
	check(grid != null, "range grid exists")
	if grid == null: quit(1); return
	var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
	var reach: Dictionary = game.mission.reach_tiles(actor, mini(2, int(actor.ap)))
	var expected: Dictionary = Read33.cover_marks(game.mission, reach.costs)
	check(expected.full.size() > 0 and expected.half.size() > 0, "fixture has reachable full and half cover")
	check(grid.cover_full33.visible and grid.cover_half33.visible, "selected unit shows standing cover marks")
	check(grid.cover_full33.multimesh.instance_count == expected.full.size(), "full cover marks match reachable tiles")
	check(grid.cover_half33.multimesh.instance_count == expected.half.size(), "half cover marks match reachable tiles")
	var themes: Dictionary = Maps.read("res://data/maps/themes.json")
	for name in themes:
		var theme: Dictionary = themes[name]
		for floor_color in [Color(theme.surface.base), Color(theme.surface.secondary)]:
			check(maxf(contrast(floor_color, Read33.FULL), contrast(floor_color, Read33.INK)) >= 3.0, "%s full shield floor contrast" % name)
			check(maxf(contrast(floor_color, Read33.HALF), contrast(floor_color, Read33.INK)) >= 3.0, "%s half shield floor contrast" % name)
	check(Read33.shield_mesh(true).surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == Read33.shield_mesh(false).surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size(), "preview and range share shield geometry")
	check(Read33.tile_threat(Tactics33.new(), Vector2i.ZERO, {}).overwatch == 2, "lane B overwatch is used")
	check(Read33.tile_threat(Tactics33.new(), Vector2i.ZERO, {}).flanked_by == 3, "lane B flank count is used")
	check(Read33.warning_text(Read33.tile_threat(Tactics33.new(), Vector2i.ZERO, {})).contains("OVERWATCH 2  ·  WOULD BE FLANKED BY 3"), "lane B warnings fit one preview line")
	var fallback: Dictionary = Read33.tile_threat(RefCounted.new(), Vector2i.ZERO, {"overwatch": 1, "flanked_by": 2})
	check(fallback.overwatch == 1 and fallback.flanked_by == 2, "missing lane B uses preview data")
	check(Read33.warning_text(fallback).contains("OVERWATCH 1  ·  WOULD BE FLANKED BY 2"), "fallback warnings fit one preview line")
	var preview_tile := Vector2i(int(actor.x), int(actor.y))
	var row: String = game.mission.board[preview_tile.y]
	game.mission.board[preview_tile.y] = row.substr(0, preview_tile.x) + "M" + row.substr(preview_tile.x + 1)
	var lips: Array = Art.tier2_lips33(game.mission)
	check(lips.any(func(lip): return absf(lip.at.x-preview_tile.x) < 0.6 and absf(lip.at.z-preview_tile.y) < 0.6), "tier-2 tile creates a lip")
	game.hud_controls._update_preview_card26(preview_tile, actor)
	check(game.hud_controls.preview_text26.text.begins_with("▲"), "tier-2 preview has height triangle")
	game.mission.board[preview_tile.y] = row
	check(not grid.evac_label28.visible, "EVAC hidden in primary phase")
	game.mission.objective_state.phase = "evac"
	for i in 2: await process_frame
	check(grid.evac_label28.visible, "EVAC shown in evac phase")
	for size in [Vector2i(956,440),Vector2i(844,390),Vector2i(390,844)]:
		root.size = size; root.content_scale_size = size; DisplayServer.window_set_size(size)
		await process_frame
		grid.evac_label28.visible = false
		preload("res://scripts/w28e_evac_marker.gd").apply(game,grid.evac_label28)
		var label_point: Vector2 = game.camera.unproject_position(grid.evac_label28.global_position)
		var nearest := INF
		for ally in game.mission.living("player"):
			var ally_tile := Vector2i(int(ally.x), int(ally.y))
			var ally_point: Vector2 = game.camera.unproject_position(Vector3(ally.x, Shot.elevation(game.mission,ally_tile)*0.7+1.2, ally.y))
			nearest = minf(nearest, label_point.distance_to(ally_point))
		check(nearest > 44.0, "%s EVAC label clears squad silhouettes" % size)
	root.size = Vector2i(844,390); root.content_scale_size = root.size; DisplayServer.window_set_size(root.size)
	await process_frame
	var tile := Vector2i(int(actor.x), int(actor.y))
	check(grid.silhouette33.material_override.no_depth_test and grid.silhouette33.mesh.get_surface_count() == 1, "occluded silhouette is one x-ray draw")
	var wall := tile + Vector2i.UP
	var wall_row: String = game.mission.board[wall.y]
	game.mission.board[wall.y] = wall_row.substr(0, wall.x) + "#" + wall_row.substr(wall.x + 1)
	var camera_position: Vector3 = game.camera.global_position
	game.camera.global_position = Vector3(tile.x, 1.0, tile.y - 2)
	grid._update_silhouette33()
	check(Read33.occluded(game.mission, game.camera.global_position, Vector3(tile.x, 0, tile.y)), "wall detected on camera ray")
	check(Read33.occluded(game.mission, Vector3(tile.x, 1.0, tile.y-2), Vector3(tile.x, 0, tile.y), [{"role":"cover","bounds":AABB(Vector3(tile.x-0.2,0,tile.y-1.2),Vector3(0.4,2,0.4))}]), "cover prop detected on camera ray")
	check(grid.silhouette33.visible, "selected unit x-ray appears behind wall")
	game.camera.global_position = camera_position
	game.mission.board[wall.y] = wall_row
	var glyph_draws := int(grid.cover_full33.multimesh.instance_count > 0) + int(grid.cover_half33.multimesh.instance_count > 0) + 1 + int(grid.silhouette33.visible)
	check(glyph_draws <= 4 and glyph_draws <= 10, "shields, lip and x-ray fit draw budget")
	var chosen := Vector2i(-1, -1)
	var point := Vector2.ZERO
	var safe: Rect2 = game.cam._map_rect28().grow(-48)
	for candidate in reach.costs:
		if candidate == tile: continue
		var projected: Vector2 = game.camera.unproject_position(Vector3(candidate.x, Shot.elevation(game.mission,candidate)*0.7+0.2,candidate.y))
		if safe.has_point(projected): chosen = candidate; point = projected; break
	if chosen.x >= 0:
		var old: Vector2i = tile
		tap(game, point)
		check(game.preview_tile == chosen and Shot.pos(actor) == old, "first tap previews without moving")
		tap(game, point)
		check(Shot.pos(actor) == chosen, "second tap commits move")
	else: check(false, "visible move target exists")
	print("readability33_test: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	quit(1 if failures else 0)
