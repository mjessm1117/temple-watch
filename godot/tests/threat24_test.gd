extends SceneTree
const Combat = preload("res://scripts/combat_mission.gd")
const Shot = preload("res://scripts/shot.gd")
const Pressure = preload("res://scripts/mission_pressure.gd")
const Settings = preload("res://scripts/settings.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; print("FAIL: ", label)
func run() -> void:
	Settings.difficulty = "normal"
	var dangerous := 0
	for n in range(12):
		var m = Combat.new(40 + n)
		m.setup_combat()
		for y in range(1, 14):
			for x in range(1, 14): m.set_tile(Vector2i(x,y), ".")
		var actor: Dictionary = m.living("player")[0]
		actor.x = 4; actor.y = 4 + n % 3; actor.concealed = false
		var watcher: Dictionary = m.living("enemy")[0]
		watcher.x = 8 + n % 2; watcher.y = 4; watcher.awake = true; watcher.overwatch = true; watcher.ammo = 4
		for enemy in m.living("enemy"):
			if int(enemy.id) != int(watcher.id): enemy.overwatch = false
		var path: Array = [Vector2i(5, 4 + n % 3), Vector2i(6, 4 + n % 3), Vector2i(7, 4 + n % 3)]
		if n % 2 == 0: path.append(Vector2i(8, 5 + n % 3))
		var preview: Dictionary = m.route_threat24(path, int(actor.id))
		m.defer_resolution = true
		actor.combat_route = path
		actor.x = path.back().x; actor.y = path.back().y
		m._enemy_reaction_fire(actor)
		var actual: Array = []
		for event in m.action_events:
			if str(event.get("kind", "")) == "intent" and bool(event.get("reaction", false)): actual.append(event.to)
		var predicted: Array = []
		for entry in preview.overwatch_tiles:
			for watcher_id in entry.watchers: predicted.append(entry.tile)
		if not predicted.is_empty(): dangerous += 1
		check(predicted == actual, "route %d preview matches reaction tiles" % n)
		check(preview.has("danger_index") and preview.has("reveal_tiles") and preview.has("flanked_end"), "route %d contract" % n)
	check(dangerous >= 10, "at least 10 routes trigger real overwatch")
	var reveal_m = Combat.new(17)
	reveal_m.setup_combat()
	for y in range(1, 14):
		for x in range(1, 14): reveal_m.set_tile(Vector2i(x, y), ".")
	var scout: Dictionary = reveal_m.living("player")[0]
	scout.x = 2; scout.y = 5; scout.concealed = false
	for enemy in reveal_m.living("enemy"):
		enemy.x = 11; enemy.y = 11; enemy.awake = false; enemy.spotted = false
	var hidden: Dictionary = reveal_m.living("enemy")[0]
	hidden.x = 7; hidden.y = 5
	var reveal_preview: Dictionary = reveal_m.route_threat24([Vector2i(3,5), Vector2i(4,5)], int(scout.id))
	check(not reveal_preview.reveal_tiles.is_empty() and reveal_preview.reveal_tiles[0].tile == Vector2i(3,5), "hidden group reveal marked on first sight tile")
	var ai_m = Combat.new(17)
	ai_m.setup_combat()
	for y in range(1, 10):
		for x in range(1, 10): ai_m.set_tile(Vector2i(x,y), ".")
	var ai_enemy: Dictionary = ai_m.living("enemy")[0]
	var ai_target: Dictionary = ai_m.living("player")[0]
	ai_enemy.x = 6; ai_enemy.y = 5; ai_enemy.awake = true; ai_enemy.ap = 2; ai_enemy.ammo = 4
	ai_target.x = 5; ai_target.y = 5; ai_target.concealed = false
	ai_m.phase = "enemy"; ai_m.defer_resolution = true
	preload("res://scripts/ai.gd").act(ai_m, ai_enemy, {})
	var reason_recorded := false
	for event in ai_m.action_events:
		if int(event.get("actor", -1)) == int(ai_enemy.id) and str(event.get("reason24", "")) != "": reason_recorded = true
	check(reason_recorded, "AI decision records reason on event")
	var mission = Combat.new(17)
	mission.setup_combat()
	var player: Dictionary = mission.living("player")[0]
	var segments: Array = mission.route_segments24([Shot.pos(player)+Vector2i.RIGHT], int(player.id))
	check(segments.size() == 1 and segments[0].has("kind") and segments[0].has("from"), "route segment metadata")
	var segment_start := Vector2i(3, 3)
	mission.set_tile(segment_start, ".")
	mission.set_tile(Vector2i(4, 3), "^")
	mission.set_tile(Vector2i(5, 3), "r")
	mission.set_tile(Vector2i(6, 3), "D")
	var typed: Array = preload("res://scripts/w24_threat_route.gd").segments(mission, [Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3)], segment_start)
	check([typed[0].kind, typed[1].kind, typed[2].kind] == ["climb", "vault", "door"], "climb vault door types from map")
	var wave: Dictionary = Pressure.next_reinforcement24(mission)
	mission.turn = int(mission.spec.reinforcement.announce_turn); mission.reinforcement_announced = true
	wave = Pressure.next_reinforcement24(mission)
	check(wave.has("count") and wave.has("turns") and wave.has("entry_tile"), "next reinforcement cue")
	var marker_parent := Node3D.new()
	root.add_child(marker_parent)
	var marker = preload("res://scripts/reinforcement_marker.gd").new()
	marker_parent.add_child(marker)
	await process_frame
	marker.show_tile(wave.entry_tile, mission)
	check(marker.visible and marker.wave_label.text.contains("ENTRY") and marker.wave_label.text.contains(str(wave.count)) and marker.wave_label.text.contains(str(wave.turns)), "entry marker shows count and turn")
	marker_parent.queue_free()
	var cover := Vector2i(6, 6)
	mission.set_tile(cover, "c")
	mission.damage_cover(cover, 4, {"kind":"force_push", "actor":int(player.id)})
	check(mission.action_events.back().kind == "cover_break" and mission.action_events.back().cause == "force_push" and int(mission.action_events.back().actor) == int(player.id), "cover cause event")
	check(mission.intent_reason24({"reason24":"Flanking"}) == "Flanking" and mission.intent_reason24({"reaction":true}) == "Overwatch", "decision reason API")
	var leap_actor: Dictionary = mission.living("player")[0]
	leap_actor.kit.append("leap")
	leap_actor.focus_left = 10; leap_actor.ap = 2
	var leap_from: Vector2i = Shot.pos(leap_actor)
	var leap_tiles: Array = preload("res://scripts/abilities_engine.gd").tiles(mission, leap_actor, "leap")
	var leap_to: Vector2i = leap_tiles[0] if not leap_tiles.is_empty() else leap_from
	check(mission.use_ability(int(leap_actor.id), "leap", -1, leap_to), "leap resolves")
	var leap_event: Dictionary = {}
	for event in mission.action_events:
		if str(event.get("kind", "")) == "leap": leap_event = event
	check(not leap_event.is_empty() and leap_event.from == leap_from and leap_event.to == leap_to, "leap event has start and end")
	print("THREAT24: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
