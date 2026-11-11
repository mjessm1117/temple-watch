extends SceneTree
const Combat = preload("res://scripts/combat_mission.gd")
const PreviewInput = preload("res://scripts/input_controls.gd")
const Hud = preload("res://scripts/hud_controls.gd")
const Grid = preload("res://scripts/map_art_grid.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; print("FAIL: ", label)
func run() -> void:
	check(Hud.MOVE_RANGE_FILL_ALPHA26 <= 0.1, "move fill alpha")
	var m = Combat.new(17)
	m.setup_combat()
	for y in range(1, 14):
		for x in range(1, 14): m.set_tile(Vector2i(x, y), ".")
	var actor: Dictionary = m.living("player")[0]
	actor.x = 4; actor.y = 5; actor.ap = 2
	for enemy in m.living("enemy"):
		enemy.x = 12; enemy.y = 12; enemy.awake = false
	var watcher: Dictionary = m.living("enemy")[0]
	watcher.x = 8; watcher.y = 5; watcher.awake = true
	var tile := Vector2i(6, 5)
	var sight: Dictionary = PreviewInput.sight26(m, actor, tile)
	check(int(sight.seen_by) == 1, "awake enemy LOS flags tile")
	var danger: Dictionary = Grid.danger_tiles_for26(m, actor)
	check(danger.has(tile), "enemy-visible tile receives danger tint flag")
	var markers: Array = Grid.route_markers24({}, [tile], danger)
	check(markers.size() == 1 and markers[0].color.r > markers[0].color.g, "visible route tile gets orange tint")
	var preview: Dictionary = PreviewInput.preview26(m, tile, int(actor.id))
	for key in ["cover_pct", "flanked", "seen_by", "hit_pct_vs_nearest", "route_safe"]:
		check(preview.has(key), "preview26 key " + key)
	check(int(preview.seen_by) == 1 and not bool(preview.route_safe), "preview26 danger")
	watcher.awake = false
	check(int(PreviewInput.sight26(m, actor, tile).seen_by) == 0, "sleeping enemy excluded")
	print("PREVIEW26: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
