extends SceneTree
const Combat = preload("res://scripts/combat_mission.gd")
const Shot = preload("res://scripts/shot.gd")
const Hud = preload("res://scripts/hud_controls.gd")
const Grid = preload("res://scripts/map_art_grid.gd")
const Decision = preload("res://scripts/w27b_decision_preview.gd")
class WaveStub extends RefCounted:
	func wave_entry27(_m: RefCounted) -> Dictionary:
		return {"entry_tiles":[Vector2i(5, 5)]}
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; print("FAIL: ", label)
func run() -> void:
	var m = Combat.new(17)
	m.setup_combat()
	for y in range(1, 14):
		for x in range(1, 14): m.set_tile(Vector2i(x, y), ".")
	var actor: Dictionary = m.living("player")[0]
	actor.x = 2; actor.y = 5; actor.ap = 2; actor.concealed = false
	for enemy in m.living("enemy"):
		enemy.x = 12; enemy.y = 12; enemy.awake = false; enemy.overwatch = false
	var watcher: Dictionary = m.living("enemy")[0]
	watcher.x = 9; watcher.y = 5; watcher.awake = true; watcher.overwatch = true; watcher.ammo = 4; watcher.spotted = true
	var sleeper: Dictionary = m.living("enemy")[1]
	sleeper.x = 8; sleeper.y = 6; sleeper.group = 99; sleeper.awake = false
	m.set_tile(Vector2i(3, 5), "c")
	m.set_tile(Vector2i(1, 4), "c")
	var begin := Time.get_ticks_usec()
	var preview: Dictionary = m.decision_preview27(int(actor.id), Vector2i(6, 5))
	var elapsed_ms := float(Time.get_ticks_usec() - begin) / 1000.0
	check(preview.path.size() >= 4 and preview.path[0].distance_to(Shot.pos(actor)) <= 1.5 and preview.path.back() == Vector2i(6, 5), "one ordered path")
	check(Hud.move_color(1) != Hud.move_color(2), "blue one-action and yellow dash perimeter colors")
	var source: String = FileAccess.get_file_as_string("res://scripts/hud_controls.gd")
	check(not source.contains("var tile: MeshInstance3D = g._box(g.range_highlights"), "range draws perimeter without terrain fill")
	var ow: Dictionary = {}
	var last_index := -1
	var reveal := false
	var flank := false
	for event in preview.events:
		var index: int = preview.path.find(event.tile)
		check(index >= last_index and index >= 0, "route events stay in traversal order")
		last_index = index
		if event.kind == "overwatch" and ow.is_empty(): ow = event
		if event.kind == "reveal": reveal = true
		if event.kind == "flank": flank = true
	check(not ow.is_empty() and ow.source == Shot.pos(watcher) and int(ow.source_id) == int(watcher.id), "first danger identifies overwatch source")
	check(reveal, "staged sleeper reveals along route")
	check(flank, "route marks tile where position becomes flanked")
	var markers: Array = Grid.route_markers27(preview.events)
	check(not markers.is_empty() and markers[0].tile == preview.events[0].tile, "first route danger has board marker")
	check(markers.any(func(marker: Dictionary) -> bool: return marker.tile == ow.source), "overwatch source gets board marker")
	check(preview.has("cover") and preview.has("height") and preview.has("flank") and preview.has("odds_delta"), "destination modifiers populated")
	check(Decision._entry_tiles(WaveStub.new()).has(Vector2i(5, 5)), "guarded wave entry hook reads landing tiles")
	check(str(preview.cover) in ["none", "half", "full"] and preview.height is int and preview.flank is int and preview.odds_delta is int, "destination modifier types")
	m.set_tile(Vector2i(7, 5), "c")
	var covered: Dictionary = m.decision_preview27(int(actor.id), Vector2i(6, 5))
	check(covered.cover == "half", "cover shield follows threat direction")
	check(m.intent_explain27({"kind":"move", "actor":int(watcher.id)}) != "", "move reason")
	check(m.intent_explain27({"kind":"attack", "actor":int(watcher.id), "target":int(actor.id)}) == "Firing at %s" % actor.name, "shoot reason names target")
	check(m.intent_explain27({"kind":"overwatch", "actor":int(watcher.id)}) != "", "overwatch reason")
	check(m.intent_explain27({"kind":"attack", "actor":int(watcher.id), "target":int(actor.id), "flanked":true}) == "Flanking %s" % actor.name, "flank reason takes priority")
	check(elapsed_ms < 100.0, "844x390 proxy decision preview under 100 ms (%.1f ms)" % elapsed_ms)
	print("TACTICS27: %d checks, %d failures, preview %.1f ms" % [checks, failures, elapsed_ms])
	quit(1 if failures else 0)
