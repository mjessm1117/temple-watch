extends RefCounted
## Both live actor playback and synchronous simulation use the mission lifecycle.
static func begin(m: RefCounted) -> void:
	m.begin_enemy_turn()

static func finish(m: RefCounted) -> void:
	m.finish_enemy_turn()
	m.tick_combat_status()
