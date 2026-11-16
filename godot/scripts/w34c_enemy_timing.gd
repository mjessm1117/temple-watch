extends RefCounted
## Enemy presentation timing and visibility; combat decisions stay in the mission.
const MIN_DRAMA := 0.8
const MOVE_SPEED := 1.5
const QUIET_WAIT_SCALE := 0.5

static func move_speed_scale() -> float:
	return float(preload("res://scripts/campaign/strat_preferences.gd").get_value("speed")) * RescueSettings.enemy_speed() * MOVE_SPEED

static func on_screen(game: Node3D, point: Vector3) -> bool:
	if game.camera == null or game.camera.is_position_behind(point + Vector3.UP): return false
	var screen: Vector2 = game.camera.unproject_position(point + Vector3.UP)
	var size: Vector2 = game.get_viewport().get_visible_rect().size
	return screen.x >= 0.0 and screen.y >= 0.0 and screen.x <= size.x and screen.y <= size.y

static func visible_move(game: Node3D, from: Vector3, points: Array[Vector3]) -> bool:
	if on_screen(game, from): return true
	for point in points:
		if on_screen(game, point): return true
	return false
