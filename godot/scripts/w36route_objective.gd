extends Control
## One objective cue: world label in view, edge arrow and tile count out of view.
const Maps = preload("res://scripts/map_catalog.gd")
const Shot = preload("res://scripts/shot.gd")
var game: Node
var world_label: Label3D
var evac_label: Label3D
var cue: Dictionary = {}

static func target(m: RefCounted, selected: Dictionary = {}) -> Dictionary:
	if m == null or m.result != "": return {}
	var evac: bool = str(m.objective_state.get("phase", "primary")) == "evac" or (not m.modern and bool(m.prisoner.get("freed", false)))
	var tiles: Array = []
	var title := "OBJECTIVE"
	if evac:
		for point in m.spec.get("evac", []): tiles.append(Maps.point(point))
		title = "EVAC"
	elif bool(m.prisoner.get("active", true)) and m.in_bounds(Shot.pos(m.prisoner)) and not bool(m.prisoner.get("freed", false)):
		tiles.append(Shot.pos(m.prisoner))
		title = "MIRA" if str(m.prisoner.get("name", "")).contains("Mira") else str(m.prisoner.get("name", "OBJECTIVE")).to_upper()
	elif m.has_method("interactables"):
		tiles = m.interactables()
	if tiles.is_empty(): return {}
	var origin: Vector2i = Shot.pos(selected) if not selected.is_empty() else tiles[0]
	var chosen: Vector2i = tiles[0]
	for tile in tiles:
		if origin.distance_to(tile) < origin.distance_to(chosen): chosen = tile
	return {"tile": chosen, "title": title, "distance": maxi(absi(chosen.x-origin.x), absi(chosen.y-origin.y))}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.mission) or not is_instance_valid(game.camera): return
	self.size = get_viewport_rect().size
	var selected: Dictionary = game.mission.unit_by_id(game.selected_id)
	var next: Dictionary = target(game.mission, selected)
	if next.is_empty() or game.cinematic:
		cue = {}
		if world_label != null: world_label.visible = false
		queue_redraw()
		return
	var tile: Vector2i = next.tile
	var at := Vector3(tile.x, Shot.elevation(game.mission, tile) * 0.7 + 2.5, tile.y)
	var point: Vector2 = game.camera.unproject_position(at)
	var size: Vector2 = get_viewport_rect().size
	var margins := Vector2(66.0, 82.0)
	var safe := Rect2(Vector2(margins.x, margins.y), Vector2(size.x - 2.0 * margins.x, size.y - margins.y - (130.0 if size.x > size.y else 190.0)))
	var on_screen: bool = not game.camera.is_position_behind(at) and safe.has_point(point)
	world_label.visible = on_screen and (str(next.title) != "EVAC" or evac_label == null or not evac_label.is_visible_in_tree())
	world_label.position = at
	world_label.text = str(next.title)
	world_label.modulate = Color("b8f6d7") if next.title == "EVAC" else Color("ffe09b")
	if on_screen:
		cue = {}
	else:
		var center := safe.get_center()
		var direction := (point - center).normalized()
		if game.camera.is_position_behind(at): direction = -direction
		if direction.length_squared() < 0.01: direction = Vector2.UP
		var hit := center + direction * minf((safe.size.x * 0.5 - 8.0) / maxf(absf(direction.x), 0.01), (safe.size.y * 0.5 - 8.0) / maxf(absf(direction.y), 0.01))
		if size.x < size.y: hit = Vector2(size.x * 0.56, 108.0)
		elif game.action == "move" and game.preview_tile.x >= 0: hit = Vector2(size.x - 116.0, size.y * 0.55)
		next["point"] = hit
		next["direction"] = direction
		cue = next
	queue_redraw()

func _draw() -> void:
	if cue.is_empty(): return
	var point: Vector2 = cue.point
	var direction: Vector2 = cue.direction
	var tint := Color("b8f6d7") if cue.title == "EVAC" else Color("ffe09b")
	var arrow := ("^^" if direction.y < 0.0 else "vv") if absf(direction.y) >= absf(direction.x) else ("<<" if direction.x < 0.0 else ">>")
	var label := "%s %s %d TILES" % [arrow, cue.title, int(cue.distance)]
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var text_at := point - direction * 22.0 - Vector2(width * 0.5, -5.0)
	text_at.x = clampf(text_at.x, 8.0, size.x - width - (8.0 if size.x < size.y else 74.0))
	if size.x < size.y: text_at.x = maxf(text_at.x, size.x * 0.43)
	text_at.y = clampf(text_at.y, 75.0, size.y - 130.0)
	draw_string(font, text_at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, tint)
