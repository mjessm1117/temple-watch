extends RefCounted
## Touch movement is explicitly previewed, then committed on a second tap.
const Shot = preload("res://scripts/shot.gd")
const InputControls = preload("res://scripts/input_controls.gd")

static func unit_at(game: Node, point: Vector2, radius: float = 34.0) -> Dictionary:
	var found: Dictionary = {}
	var nearest := radius
	for unit in game.mission.living("player"):
		var distance: float = InputControls.unit_screen_distance(game, point, unit)
		if distance < nearest:
			nearest = distance
			found = unit
	return found

static func tile_at(game: Node, point: Vector2, actor: Dictionary, route: Dictionary) -> Vector2i:
	var picked: Vector2i = game._screen_tile(point)
	var best := Vector2i(-1, -1)
	var distance := 48.0 # A 10 mm target on a compact landscape map.
	for tile in route.get("costs", {}):
		if tile == Shot.pos(actor) or int(route.costs[tile]) > int(actor.mob) * int(actor.ap): continue
		var center: Vector2 = game.camera.unproject_position(Vector3(tile.x, Shot.elevation(game.mission, tile) * 0.7 + 0.2, tile.y))
		var delta: float = point.distance_to(center)
		if delta < distance:
			distance = delta
			best = tile
	if best.x >= 0: return best
	return picked if InputControls.valid_move_tile24(route, actor, picked) else Vector2i(-1, -1)

static func tap(game: Node, point: Vector2) -> bool:
	if game.action != "move" or game.mission.phase != "player" or game.player_attack_pending or game.playing_enemy_events: return false
	for enemy in game.mission.living("enemy"):
		if bool(enemy.get("spotted", false)) or bool(enemy.get("detected", false)) or bool(enemy.get("awake", false)):
			if InputControls.unit_screen_distance(game, point, enemy) < 28.0: return false
	var unit := unit_at(game, point)
	if not unit.is_empty() and (InputControls.unit_screen_distance(game, point, unit) < 10.0 or game._screen_tile(point) == Shot.pos(unit)):
		if int(unit.id) == game.selected_id:
			game._cancel_order()
		else:
			game._select(int(unit.id))
		return true
	var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
	if actor.is_empty(): return true
	var route: Dictionary = game.mission.paths(actor, int(actor.mob) * 2)
	var tile := tile_at(game, point, actor, route)
	if tile.x < 0:
		game._cancel_order()
		return true
	if tile == game.preview_tile:
		var from := Shot.pos(actor)
		game._move_selected(tile)
		if OS.has_feature("web") and Shot.pos(actor) != from:
			print("W28E_MOVE_COMMITTED ", from, " -> ", Shot.pos(actor), " ap=", int(actor.ap))
	else:
		game.preview_tile = tile
		game.hovered = Vector2i(-1, -1)
		game._refresh_highlights()
		if OS.has_feature("web"): print("W28E_MOVE_PREVIEW ", tile)
	return true
