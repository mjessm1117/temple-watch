extends RefCounted
## Physical window size decides whether the phone layout is used.

static func window_size() -> Vector2i:
	var physical := DisplayServer.window_get_size()
	if physical.x > 0 and physical.y > 0: return physical
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.size if tree != null else Vector2i.ZERO

static func narrow(size: Vector2i) -> bool:
	# A 1366×768 desktop window also has a short side below 900.
	return mini(size.x, size.y) > 0 and mini(size.x, size.y) < 900 and maxi(size.x, size.y) < 1200

static func battle_board_fraction(size: Vector2) -> float:
	# Conservative area budget for the scaled top, tray and two collapsed cards.
	var covered := size.x * (42.0 + 64.0) * 1.2 + minf(size.x, 436.0 * 1.2) * 38.0 * 1.2
	return 1.0 - covered / maxf(1.0, size.x * size.y)
