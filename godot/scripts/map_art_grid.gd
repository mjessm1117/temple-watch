extends Node3D
## Render the HUD's rule-owned range borders as one visible instanced grid.
## Source nodes remain intact for the HUD's existing refresh/clear contract.
var source: Node3D
var dirty := true
var game: Node
var view: MultiMeshInstance3D
var focus := Vector2i(-999,-999)
var route_destination24 := Vector2i(-999, -999)
var route_unit24 := -1
var move_controls24: Control
var hover_view24: MultiMeshInstance3D
var hover_source24: Node3D
var hover_dirty24 := true
var route_markers_current24: Array = []
var danger_view26: MultiMeshInstance3D
var danger_tiles26: Dictionary = {}
var danger_key26 := ""

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
	if is_instance_valid(game) and game.get("input_controls") != null:
		var busy_input := preload("res://scripts/w24_command_busy_input.gd").new()
		busy_input.game = game; game.add_child(busy_input)
	hover_view24 = MultiMeshInstance3D.new(); hover_view24.name = "RouteBatch24"; add_child(hover_view24)
	hover_view24.material_override = mat
	hover_view24.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	danger_view26 = MultiMeshInstance3D.new(); danger_view26.name = "EnemySight26"; get_parent().add_child(danger_view26)
	danger_view26.material_override = mat
	danger_view26.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func changed(_child: Node) -> void: dirty = true

func _process(_delta: float) -> void:
	if is_instance_valid(game):
		var aiming: bool = game.action not in ["move", "free", "overwatch", "hunker", "interact"]
		var moving: bool = game.action == "move" and (game.hovered.x >= 0 or game.preview_tile.x >= 0)
		visible = not game.cinematic and is_instance_valid(game.mission) and game.mission.phase == "player" and (moving or aiming)
	if is_instance_valid(game) and is_instance_valid(game.mission):
		var unit: Dictionary = game.mission.unit_by_id(game.selected_id)
		if not unit.is_empty():
			var selected := Vector2i(int(unit.x),int(unit.y))
			if selected != focus: focus = selected; dirty = true
	_update_danger26()
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
		mm.set_instance_transform(meshes.size() + i, Transform3D(Basis.from_scale(Vector3(0.62, 0.08, 0.62) if height < 0.3 else Vector3(0.25, 0.7, 0.25)), at))
		mm.set_instance_color(meshes.size() + i, marker.color)
	hover_view24.multimesh = mm
	hover_view24.visible = mm.instance_count > 0

func _hover_changed24(_node: Node) -> void:
	hover_dirty24 = true

func update_route24() -> void:
	if not is_instance_valid(game) or game.get("input_controls") == null or not is_instance_valid(game.mission): return
	if move_controls24 == null and is_instance_valid(game.overlay): _build_controls24()
	var destination: Vector2i = (game.hovered if game.hovered.x >= 0 else game.preview_tile) if game.action == "move" else Vector2i(-1, -1)
	var selected: int = game.selected_id
	if move_controls24 != null:
		move_controls24.visible = game.action == "move" and game.preview_tile.x >= 0 and not game.cinematic
	if destination == route_destination24 and selected == route_unit24: return
	route_destination24 = destination; route_unit24 = selected
	route_markers_current24.clear()
	hover_dirty24 = true
	if destination.x < 0 or not game.mission.has_method("route_threat24"): return
	var actor: Dictionary = game.mission.unit_by_id(selected)
	if actor.is_empty(): return
	var decision: Dictionary = preload("res://scripts/input_controls.gd").move_preview(game.mission, actor, destination)
	if decision.is_empty(): return
	var previous: Dictionary = decision.get("prev", {})
	var path: Array = [destination]
	var cursor := destination
	while previous.has(cursor):
		cursor = previous[cursor]
		path.push_front(cursor)
	var risk: Dictionary = game.mission.route_threat24(path, selected)
	route_markers_current24 = route_markers24(risk, path, danger_tiles26)
	_refresh_hover24()
	if game.preview_tile == destination and game.has_method("preview_route24"): game.preview_route24(path)

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
	if not is_instance_valid(game) or not is_instance_valid(game.mission) or danger_view26 == null: return
	var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
	var active: bool = game.mission.phase == "player" and game.action == "move" and not actor.is_empty()
	danger_view26.visible = active
	if not active: return
	var key := "%d:%d:%d:%d:%d" % [game.mission.turn, game.selected_id, game.mission.terrain_revision, int(actor.x), int(actor.y)]
	for enemy in game.mission.living("enemy"):
		key += ":%d,%d,%d,%d" % [int(enemy.id), int(enemy.x), int(enemy.y), int(bool(enemy.get("awake", false)))]
	if key == danger_key26: return
	danger_key26 = key
	danger_tiles26 = danger_tiles_for26(game.mission, actor)
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true
	mm.mesh = BoxMesh.new(); mm.instance_count = danger_tiles26.size()
	var i := 0
	for tile in danger_tiles26:
		var at := Vector3(tile.x, preload("res://scripts/shot.gd").elevation(game.mission, tile) * 0.7 + 0.105, tile.y)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(0.79, 0.018, 0.79)), at))
		mm.set_instance_color(i, Color(1.0, 0.19, 0.15, 0.12))
		i += 1
	danger_view26.multimesh = mm
	if route_destination24.x >= 0: route_destination24 = Vector2i(-999, -999)

func _build_controls24() -> void:
	move_controls24 = preload("res://scripts/w24_command_move_controls.gd").new()
	move_controls24.game = game
	move_controls24.name = "MoveConfirm24"
	move_controls24.anchor_left = 0.5; move_controls24.anchor_right = 0.5
	move_controls24.anchor_top = 0.54; move_controls24.anchor_bottom = 0.54
	move_controls24.offset_left = -98; move_controls24.offset_right = 98
	move_controls24.offset_top = -22; move_controls24.offset_bottom = 22
	game.overlay.add_child(move_controls24)
	move_controls24.visible = false
