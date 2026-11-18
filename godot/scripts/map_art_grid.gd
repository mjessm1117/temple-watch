extends Node3D
const Read33 = preload("res://scripts/w33d_readability.gd")
const Shot33 = preload("res://scripts/shot.gd")
## Render the HUD's rule-owned range borders as one visible instanced grid.
## Source nodes remain intact for the HUD's existing refresh/clear contract.
var source: Node3D
var dirty := true
var game: Node
var view: MultiMeshInstance3D
var focus := Vector2i(-999,-999)
var route_destination24 := Vector2i(-999, -999)
var route_unit24 := -1
var route_signature36 := ""
var move_controls24: Control
var hover_view24: MultiMeshInstance3D
var hover_source24: Node3D
var hover_dirty24 := true
var route_markers_current24: Array = []
var danger_view26: MultiMeshInstance3D
var danger_tiles26: Dictionary = {}
var danger_key26 := ""
var reach_view28: MultiMeshInstance3D
var reach_key28 := ""
var reach_edges28 := 0
var ap_label28: Label3D
var evac_label28: Label3D
var objective_cue36: Control
var objective_label36: Label3D
var overwatch_lane36: MeshInstance3D
var overwatch_key36 := ""
var evac_batches_hidden28 := 0
var cover_full33: MultiMeshInstance3D
var cover_half33: MultiMeshInstance3D
var cover_focus36: MeshInstance3D
var cover_focus_text36: Label3D
var silhouette33: MeshInstance3D
var silhouette_tick33 := 0.0

static func focus_alpha(position: Vector3, selected: Vector2i) -> float:
	var d := Vector2(position.x-selected.x,position.z-selected.y).length()
	return lerpf(0.65,1.0,1.0-smoothstep(2.0,7.0,d))

func bind(original: Node3D, owner_game: Node = null) -> void:
	game = owner_game
	source = original; source.visible = false
	source.child_entered_tree.connect(changed); source.child_exiting_tree.connect(changed)
	view = MultiMeshInstance3D.new(); add_child(view)
	var mat := StandardMaterial3D.new(); mat.vertex_color_use_as_albedo = true; mat.albedo_color = Color.WHITE
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	view.material_override = mat; view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	reach_view28 = MultiMeshInstance3D.new(); reach_view28.name = "MoveReach28"; add_child(reach_view28)
	reach_view28.material_override = mat
	reach_view28.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cover_full33 = _cover_view33("FullCover33", true)
	cover_half33 = _cover_view33("HalfCover33", false)
	for quiet in [cover_full33, cover_half33]:
		var quiet_mat: StandardMaterial3D = quiet.material_override.duplicate()
		quiet_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		quiet_mat.albedo_color = Color(1, 1, 1, 0.38)
		quiet.material_override = quiet_mat
	cover_focus36 = MeshInstance3D.new(); cover_focus36.name = "DestinationCover36"; add_child(cover_focus36)
	cover_focus36.material_override = Read33.shield_material()
	cover_focus36.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cover_focus36.visible = false
	cover_focus_text36 = Label3D.new(); cover_focus_text36.name = "DestinationCoverText36"; add_child(cover_focus_text36)
	cover_focus_text36.font_size = 30; cover_focus_text36.pixel_size = 0.014
	cover_focus_text36.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cover_focus_text36.outline_size = 9; cover_focus_text36.outline_modulate = Color("102337")
	cover_focus_text36.visible = false
	silhouette33 = MeshInstance3D.new(); silhouette33.name = "OccludedUnit33"; add_child(silhouette33)
	silhouette33.mesh = Read33.silhouette_mesh(); silhouette33.material_override = Read33.shield_material()
	silhouette33.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; silhouette33.visible = false
	if is_instance_valid(game) and game.get("input_controls") != null:
		var busy_input := preload("res://scripts/w24_command_busy_input.gd").new()
		busy_input.game = game; game.add_child(busy_input)
	hover_view24 = MultiMeshInstance3D.new(); hover_view24.name = "RouteBatch24"; add_child(hover_view24)
	hover_view24.material_override = mat
	hover_view24.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	danger_view26 = MultiMeshInstance3D.new(); danger_view26.name = "EnemySight26"; get_parent().add_child(danger_view26)
	danger_view26.material_override = mat
	danger_view26.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ap_label28 = Label3D.new(); ap_label28.name = "MoveCost28"; add_child(ap_label28)
	ap_label28.font_size = 48; ap_label28.pixel_size = 0.018
	ap_label28.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ap_label28.outline_size = 10; ap_label28.outline_modulate = Color("152435")
	ap_label28.visible = false
	evac_label28 = Label3D.new(); evac_label28.name = "EvacMarker28"; add_child(evac_label28)
	evac_label28.text = "EVAC"; evac_label28.font_size = 40; evac_label28.pixel_size = 0.018
	evac_label28.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	evac_label28.modulate = Color("b8f6d7"); evac_label28.outline_size = 10
	evac_label28.outline_modulate = Color("102337"); evac_label28.visible = false
	objective_label36 = Label3D.new(); objective_label36.name = "ObjectiveWorld36"; get_parent().add_child(objective_label36)
	objective_label36.font_size = 38; objective_label36.pixel_size = 0.018
	objective_label36.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	objective_label36.modulate = Color("ffe09b"); objective_label36.outline_size = 10
	objective_label36.outline_modulate = Color("102337"); objective_label36.visible = false
	overwatch_lane36 = MeshInstance3D.new(); overwatch_lane36.name = "OverwatchLane36"; get_parent().add_child(overwatch_lane36)
	var lane_mat := StandardMaterial3D.new()
	lane_mat.vertex_color_use_as_albedo = true
	lane_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lane_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lane_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	lane_mat.no_depth_test = true
	overwatch_lane36.material_override = lane_mat
	overwatch_lane36.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	overwatch_lane36.visible = false

func changed(_child: Node) -> void: dirty = true

func _cover_view33(label: String, full: bool) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new(); node.name = label; add_child(node)
	node.material_override = Read33.shield_material()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = Read33.shield_mesh(full, 0.52); mm.instance_count = 0; node.multimesh = mm
	return node

func _process(_delta: float) -> void:
	_ensure_objective36()
	if is_instance_valid(game):
		var aiming: bool = game.action not in ["move", "free", "overwatch", "hunker", "interact"]
		var moving: bool = game.action == "move"
		visible = not game.cinematic and is_instance_valid(game.mission) and game.mission.phase == "player" and (moving or aiming)
		view.visible = not moving
	if is_instance_valid(game) and is_instance_valid(game.mission):
		var unit: Dictionary = game.mission.unit_by_id(game.selected_id)
		if not unit.is_empty():
			var selected := Vector2i(int(unit.x),int(unit.y))
			if selected != focus: focus = selected; dirty = true
		if game.get("hud_controls") != null and game.hud_controls.phone != null:
			for ally in game.mission.living("player"):
				var ally_view: Node3D = game.views.get(int(ally.id))
				if ally_view != null:
					var ring: MeshInstance3D = ally_view.get("ring")
					if ring != null: ring.visible = int(ally.id) == game.selected_id
	_update_danger26()
	silhouette_tick33 += _delta
	if silhouette_tick33 >= 0.12: silhouette_tick33 = 0.0; _update_silhouette33()
	if evac_label28 != null: evac_batches_hidden28 = preload("res://scripts/w28e_evac_marker.gd").apply(game, evac_label28)
	_update_overwatch36()
	_update_reach28()
	style_hover()
	_refresh_hover24()
	update_route24()
	if not dirty or not is_instance_valid(source): return
	dirty = false
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true
	var mesh := BoxMesh.new(); mesh.size = Vector3.ONE; mm.mesh = mesh
	mm.instance_count = source.get_child_count()
	var index := 0
	for child in source.get_children():
		if not child is MeshInstance3D or not child.mesh is BoxMesh: continue
		var size: Vector3 = child.mesh.size
		var fill := size.x > 0.7 and size.z > 0.7
		size.y = 0.02 if fill else 0.04
		var transform: Transform3D = child.transform*Transform3D(Basis.from_scale(size),Vector3.ZERO)
		mm.set_instance_transform(index,transform)
		var tint: Color = child.material_override.albedo_color
		tint.a = 0.06 if fill else 0.82
		if focus.x > -900:
			tint.a *= focus_alpha(child.position,focus)
		mm.set_instance_color(index,tint); index += 1
	mm.visible_instance_count = index; view.multimesh = mm

func _ensure_objective36() -> void:
	if objective_cue36 != null or not is_instance_valid(game) or game.get("overlay") == null: return
	objective_cue36 = preload("res://scripts/w36route_objective.gd").new()
	objective_cue36.name = "ObjectiveCue36"
	objective_cue36.set("game", game); objective_cue36.set("world_label", objective_label36)
	objective_cue36.set("evac_label", evac_label28)
	game.overlay.add_child(objective_cue36)

func _exit_tree() -> void:
	if is_instance_valid(objective_cue36): objective_cue36.queue_free()
	if is_instance_valid(objective_label36): objective_label36.queue_free()
	if is_instance_valid(overwatch_lane36): overwatch_lane36.queue_free()

func style_hover() -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.hover_highlights): return
	for node in game.hover_highlights.get_children():
		if not node is MeshInstance3D or node.has_meta("gfx13_styled"): continue
		node.set_meta("gfx13_styled",true)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if node.mesh is BoxMesh and node.material_override is StandardMaterial3D:
			var size: Vector3 = node.mesh.size
			if is_instance_valid(game) and game.action == "move" and game.preview_tile.x >= 0 and is_equal_approx(size.x, 0.34) and is_equal_approx(size.z, 0.34):
				node.mesh.size = Vector3(0.62, size.y, 0.62)
			if size.y > 0.065 or size.y < 0.035: continue
			# Existing route dots and line remain rule-owned; only their material changes.
			var mat: StandardMaterial3D = node.material_override
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.emission_enabled = true
			mat.emission = Color("71e4ff")
			mat.emission_energy_multiplier = 0.65

func _refresh_hover24() -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.hover_highlights): return
	if hover_source24 != game.hover_highlights:
		hover_source24 = game.hover_highlights
		hover_source24.visible = false
		hover_source24.child_entered_tree.connect(_hover_changed24)
		hover_source24.child_exiting_tree.connect(_hover_changed24)
		hover_dirty24 = true
	if not hover_dirty24: return
	hover_dirty24 = false
	var meshes: Array[MeshInstance3D] = []
	for child in hover_source24.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh and child.material_override is StandardMaterial3D: meshes.append(child)
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true
	mm.mesh = BoxMesh.new(); mm.instance_count = meshes.size() + route_markers_current24.size()
	for i in range(meshes.size()):
		var child: MeshInstance3D = meshes[i]
		var hover_size: Vector3 = child.mesh.size
		if is_equal_approx(hover_size.x, 0.15) and is_equal_approx(hover_size.y, 0.06):
			hover_size.x = 0.055; hover_size.y = 0.035
		var transform: Transform3D = child.transform * Transform3D(Basis.from_scale(hover_size), Vector3.ZERO)
		mm.set_instance_transform(i, transform)
		mm.set_instance_color(i, child.material_override.albedo_color)
	for i in range(route_markers_current24.size()):
		var marker: Dictionary = route_markers_current24[i]
		var p: Vector2i = marker.tile
		var height: float = marker.height
		var at := Vector3(p.x, preload("res://scripts/shot.gd").elevation(game.mission, p) * 0.7 + height, p.y)
		mm.set_instance_transform(meshes.size() + i, Transform3D(Basis.from_scale(Vector3(0.44, 0.18, 0.44) if str(marker.get("kind", "")) == "first_threat" else Vector3(0.62, 0.08, 0.62) if height < 0.3 else Vector3(0.25, 0.7, 0.25)), at))
		mm.set_instance_color(meshes.size() + i, marker.color)
	hover_view24.multimesh = mm
	hover_view24.visible = mm.instance_count > 0

func move_preview_state28() -> Dictionary:
	if not is_instance_valid(game) or game.action != "move" or game.preview_tile.x < 0: return {"tile": Vector2i(-1, -1), "cost": 0, "confirmed": false}
	var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
	var preview: Dictionary = preload("res://scripts/input_controls.gd").move_preview(game.mission, actor, game.preview_tile)
	return {"tile": game.preview_tile, "cost": int(preview.get("ap", 0)), "confirmed": false}

func _update_reach28() -> void:
	if reach_view28 == null or not is_instance_valid(game) or not is_instance_valid(game.mission): return
	var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
	var active: bool = game.action == "move" and game.mission.phase == "player" and game.mission.result == "" and not actor.is_empty() and int(actor.get("ap", 0)) > 0
	reach_view28.visible = active
	cover_full33.visible = active; cover_half33.visible = active
	if not active: cover_focus36.visible = false; cover_focus_text36.visible = false
	if not active: return
	var key := "%d:%d:%d:%d:%d" % [game.selected_id, int(actor.x), int(actor.y), int(actor.ap), int(game.mission.terrain_revision)]
	if key == reach_key28: return
	reach_key28 = key
	var one: Dictionary = game.mission.reach_tiles(actor, 1)
	var all: Dictionary = game.mission.reach_tiles(actor, mini(2, int(actor.ap)))
	var marks: Dictionary = Read33.cover_marks(game.mission, all.costs)
	_set_cover33(cover_full33, marks.full)
	_set_cover33(cover_half33, marks.half)
	var edges: Array = []
	for tile in all.costs:
		if tile == Vector2i(int(actor.x), int(actor.y)): continue
		var blue: bool = one.costs.has(tile)
		for entry in [[Vector2i.LEFT, Vector3(-0.45, 0, 0)], [Vector2i.RIGHT, Vector3(0.45, 0, 0)], [Vector2i.UP, Vector3(0, 0, -0.45)], [Vector2i.DOWN, Vector3(0, 0, 0.45)]]:
			var next: Vector2i = tile + entry[0]
			if all.costs.has(next) and one.costs.has(next) == blue: continue
			edges.append({"tile": tile, "offset": entry[1], "horizontal": entry[0].x == 0, "blue": blue})
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true
	mm.mesh = BoxMesh.new(); mm.instance_count = edges.size()
	for i in range(edges.size()):
		var edge: Dictionary = edges[i]
		var tile: Vector2i = edge.tile
		var height: float = preload("res://scripts/shot.gd").elevation(game.mission, tile) * 0.7 + 0.25
		var size := Vector3(0.90, 0.035, 0.055) if edge.horizontal else Vector3(0.055, 0.035, 0.90)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(size), Vector3(tile.x, height, tile.y) + edge.offset))
		mm.set_instance_color(i, Color(0.34, 0.76, 0.92, 0.34) if edge.blue else Color(0.94, 0.72, 0.31, 0.34))
	reach_edges28 = edges.size()
	reach_view28.multimesh = mm

func _set_cover33(node: MultiMeshInstance3D, positions: Array) -> void:
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = node.multimesh.mesh; mm.instance_count = positions.size()
	for i in positions.size(): mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[i]))
	node.multimesh = mm

func _update_silhouette33() -> void:
	if silhouette33 == null or not is_instance_valid(game) or not is_instance_valid(game.mission): return
	var active_camera: Camera3D = game.get("camera")
	if not is_instance_valid(active_camera): return
	var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
	if actor.is_empty(): silhouette33.visible = false; return
	var tile := Vector2i(int(actor.x), int(actor.y))
	var at := Vector3(tile.x, Shot33.elevation(game.mission, tile) * 0.7, tile.y)
	silhouette33.position = at + Vector3.UP * 1.35
	var art: Node = game.terrain.get_child(0) if game.terrain.get_child_count() > 0 else null
	var records: Array = art.batch.records if art != null and art.get("batch") != null else []
	silhouette33.visible = visible and Read33.occluded(game.mission, active_camera.global_position, at, records)

func _hover_changed24(_node: Node) -> void:
	hover_dirty24 = true

func update_route24() -> void:
	if not is_instance_valid(game) or game.get("input_controls") == null or not is_instance_valid(game.mission): return
	if move_controls24 == null and is_instance_valid(game.overlay): _build_controls24()
	var destination: Vector2i = game.preview_tile if game.action == "move" else Vector2i(-1, -1)
	var selected: int = game.selected_id
	if move_controls24 != null:
		move_controls24.visible = game.action == "move" and game.preview_tile.x >= 0 and not game.cinematic
		_place_controls28()
	ap_label28.visible = destination.x >= 0 and not game.cinematic
	if destination.x < 0 or game.cinematic:
		cover_focus36.visible = false; cover_focus_text36.visible = false
	var state: Array = [destination, selected, game.mission.terrain_revision]
	for unit in game.mission.living("player") + game.mission.living("enemy"):
		state.append([unit.id, unit.x, unit.y, unit.hp, unit.ap, unit.get("awake", false), unit.get("overwatch", false), unit.get("ammo", 1)])
	var signature := str(hash(state))
	if destination == route_destination24 and selected == route_unit24 and signature == route_signature36:
		if destination.x >= 0 and not game.cinematic:
			cover_focus_text36.visible = true
			cover_focus36.visible = cover_focus36.mesh != null
		return
	route_destination24 = destination; route_unit24 = selected; route_signature36 = signature
	route_markers_current24.clear()
	hover_dirty24 = true
	if destination.x < 0 or not game.mission.has_method("decision_preview27"): return
	var actor: Dictionary = game.mission.unit_by_id(selected)
	if actor.is_empty(): return
	var decision: Dictionary = game.mission.decision_preview27(selected, destination)
	var path: Array = decision.get("path", [])
	if path.is_empty(): ap_label28.visible = false; return
	var cover: String = str(decision.get("cover", "none"))
	var cover_at := Vector3(destination.x, Shot33.elevation(game.mission, destination) * 0.7 + 1.8, destination.y)
	cover_focus36.visible = cover in ["full", "half"]
	cover_focus36.mesh = Read33.shield_mesh(cover == "full", 1.55) if cover_focus36.visible else null
	cover_focus36.position = cover_at
	cover_focus_text36.visible = true
	cover_focus_text36.text = "FULL COVER" if cover == "full" else "HALF COVER" if cover == "half" else "NO COVER"
	cover_focus_text36.modulate = Color("e9fbff") if cover == "full" else Color("ffde81") if cover == "half" else Color("ff8b74")
	cover_focus_text36.position = cover_at - Vector3.UP * 1.45
	ap_label28.text = "%d AP" % int(decision.get("ap", 1))
	ap_label28.modulate = Color("69d9ff") if int(decision.get("ap", 1)) == 1 else Color("ffd05a")
	ap_label28.position = Vector3(destination.x, preload("res://scripts/shot.gd").elevation(game.mission, destination) * 0.7 + 0.9, destination.y)
	if game.mission.phase == "player" and not game.playing_enemy_events:
		var move: Dictionary = preload("res://scripts/input_controls.gd").move_preview(game.mission, actor, destination)
		route_markers_current24 = first_threat_markers36(move)
	_refresh_hover24()
	# Keep the preview tile under the finger for the confirming tap on phones.
	if game.preview_tile == destination and not preload("res://scripts/phone_layout.gd").narrow(Vector2i(game.get_viewport().get_visible_rect().size)) and game.has_method("preview_route24"):
		game.preview_route24(path)

static func route_markers27(events: Array) -> Array:
	var markers: Array = []
	var first_overwatch := -1
	for i in range(events.size()):
		if str(events[i].get("kind", "")) == "overwatch": first_overwatch = i; break
	for i in range(events.size()):
		var event: Dictionary = events[i]
		var kind := str(event.get("kind", ""))
		var color := Color("ff655a") if kind in ["overwatch", "flank"] else Color("f7d66b")
		markers.append({"tile":event.tile, "color":color, "height":0.18 if i == 0 or i == first_overwatch else 0.48})
		if i == first_overwatch and event.get("source") is Vector2i:
			markers.append({"tile":event.source, "color":Color("ff655a"), "height":0.48})
	return markers

static func first_threat_markers36(preview: Dictionary) -> Array:
	var tile: Vector2i = preview.get("first_danger_tile", Vector2i(-1, -1))
	return [{"tile": tile, "color": Color("ff6a4f"), "height": 0.19, "kind": "first_threat"}] if tile.x >= 0 else []

static func route_markers24(risk: Dictionary, path: Array, danger: Dictionary = {}) -> Array:
	var markers: Array = []
	for entry in risk.get("overwatch_tiles", []):
		var tile: Vector2i = entry.get("tile", Vector2i(-1, -1)) if entry is Dictionary else entry
		if tile in path: markers.append({"tile": tile, "color": Color("ff655a"), "height": 0.18})
	for entry in risk.get("reveal_tiles", []):
		var tile: Vector2i = entry.get("tile", Vector2i(-1, -1)) if entry is Dictionary else entry
		if tile in path: markers.append({"tile": tile, "color": Color("f7d66b"), "height": 0.48})
	for tile in path:
		if tile is Vector2i and int(danger.get(tile, 0)) > 0:
			markers.append({"tile": tile, "color": Color(1.0, 0.48, 0.10, 0.42), "height": 0.12})
	return markers

static func danger_tiles_for26(m: RefCounted, actor: Dictionary) -> Dictionary:
	var result := {}
	if actor.is_empty(): return result
	var reachable: Dictionary = m.reach_tiles(actor, mini(2, int(actor.get("ap", 0))))
	for tile in reachable.costs:
		if not m.in_bounds(tile): continue
		var seen: int = int(preload("res://scripts/input_controls.gd").sight26(m, actor, tile).seen_by)
		if seen > 0: result[tile] = seen
	return result

func _update_danger26() -> void:
	if danger_view26 != null: danger_view26.visible = false

func _update_overwatch36() -> void:
	if overwatch_lane36 == null or not is_instance_valid(game) or not is_instance_valid(game.mission): return
	var active: bool = game.mission.result == "" and not game.cinematic
	overwatch_lane36.visible = active
	if not active: return
	var signature: Array = [game.mission.terrain_revision]
	var watchers: Array = []
	for unit in game.mission.living("player") + game.mission.living("enemy"):
		signature.append([unit.id, unit.x, unit.y, unit.hp, unit.get("overwatch", false), unit.get("spotted", false), unit.get("ammo", 1)])
		if bool(unit.get("overwatch", false)) and (str(unit.side) == "player" or bool(unit.get("spotted", false))): watchers.append(unit)
	var key := str(hash(signature))
	if key != overwatch_key36:
		overwatch_key36 = key
		overwatch_lane36.mesh = preload("res://scripts/w36route_overwatch.gd").mesh(game.mission)
	overwatch_lane36.visible = overwatch_lane36.mesh != null and overwatch_lane36.mesh.get_surface_count() > 0
	var terrain_node: Node = game.get("terrain")
	var art: Node = terrain_node.get_child(0) if terrain_node != null and terrain_node.get_child_count() > 0 else null
	if art == null or art.get("marker_root") == null: return
	for visual in art.marker_root.get_children():
		if not visual is MeshInstance3D or not visual.mesh is ImmediateMesh: continue
		var fill_material: Material = visual.mesh.surface_get_material(0)
		if fill_material is StandardMaterial3D:
			var tint: Color = fill_material.albedo_color
			if tint.g > tint.r and tint.g > tint.b: continue
		var bounds: AABB = visual.mesh.get_aabb()
		var center := Vector2(bounds.get_center().x, bounds.get_center().z)
		for watcher in watchers:
			var radius: float = minf(float(watcher.range), 8.0)
			if center.distance_to(Vector2(watcher.x, watcher.y)) < 0.25 and absf(bounds.size.x - radius * 2.0) < 0.5:
				visual.visible = false
				break

func _build_controls24() -> void:
	move_controls24 = preload("res://scripts/w24_command_move_controls.gd").new()
	move_controls24.game = game
	move_controls24.name = "MoveConfirm24"
	move_controls24.anchor_left = 0.0; move_controls24.anchor_right = 0.0
	move_controls24.anchor_top = 0.0; move_controls24.anchor_bottom = 0.0
	move_controls24.offset_left = -98; move_controls24.offset_right = 98
	move_controls24.offset_top = 0; move_controls24.offset_bottom = 44
	game.overlay.add_child(move_controls24)
	move_controls24.visible = false

func _place_controls28() -> void:
	if move_controls24 == null: return
	var size: Vector2 = game.get_viewport().get_visible_rect().size
	var free := Rect2(Vector2(0, size.y * 0.12), Vector2(size.x, size.y * 0.63))
	if game.has_method("hud_safe_rect28"):
		var supplied: Variant = game.call("hud_safe_rect28")
		if supplied is Rect2 and supplied.has_area(): free = supplied
	elif game.get("hud_controls") != null and game.hud_controls.phone != null and game.hud_controls.phone.has_method("hud_safe_rect28"):
		var supplied: Variant = game.hud_controls.phone.call("hud_safe_rect28")
		if supplied is Rect2 and supplied.has_area(): free = supplied
	var center := free.get_center().x
	var top := minf(free.end.y - 50.0, size.y - 56.0)
	move_controls24.offset_left = center - 98.0
	move_controls24.offset_right = center + 98.0
	move_controls24.offset_top = top
	move_controls24.offset_bottom = top + 44.0
