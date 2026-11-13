extends SceneTree
const Mission = preload("res://scripts/mission.gd")
const Combat = preload("res://scripts/combat_mission.gd")
const Shot = preload("res://scripts/shot.gd")
const Presentation = preload("res://scripts/enemy_presentation.gd")
const Card = preload("res://scripts/w31e_enemy_card.gd")

var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func fixture() -> Node3D:
	var game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.animate_headless = true
	game.set_process(false)
	game.action_camera = true
	return game

func _card_and_cues(game: Node3D) -> void:
	var enemies: Array[Dictionary] = game.mission.living("enemy")
	var first: Dictionary = enemies[0]
	var second: Dictionary = enemies[1]
	game.playing_enemy_events = true
	await Presentation.show_event(game, {"kind":"reload", "actor":int(first.id), "reason27":"Flanking your Jedi"})
	var card: PanelContainer = Card.current(game)
	check(card != null and card.get_node("CardLines/ActorIntent").text.contains(str(first.name).to_upper()) and card.get_node("CardLines/ActorIntent").text.contains(str(first.class_name).to_upper()), "card names actor and class")
	check(card != null and card.get_node("CardLines/ActorIntent").text.contains("FLANKING") and card.get_node("CardLines/IntentDescription").text == "Flanking your Jedi", "card shows and describes intent")
	Card.result(game, int(first.id), "HIT")
	check(card.get_node("CardLines/ActionResult").text == "HIT", "card shows result")
	await Presentation.show_event(game, {"kind":"reload", "actor":int(first.id), "reason27":"Holding cover"})
	check(Card.current(game) == card, "actor keeps one card across actions")
	await Presentation.show_event(game, {"kind":"reload", "actor":int(second.id), "reason27":"Overwatch on lane"})
	check(Card.current(game) != card and int(Card.current(game).get_meta("actor_id")) == int(second.id), "next actor replaces card")
	game.cam.skip_requested = true
	await Presentation.show_event(game, {"kind":"reload", "actor":int(first.id), "reason27":"Flanking"})
	check(Card.current(game) == null, "skip clears and suppresses card")
	game.cam.skip_requested = false
	var dead := first.duplicate(); dead.hp = 0
	check(Card.show_actor(game, dead, "Flanking") == null, "dead actor has no card")
	game.playing_enemy_events = false
	first.overwatch = true
	game.hud_controls._refresh_cues31()
	check(game.hud_controls.cue_overwatch31.visible and game.hud_controls.cue_overwatch31.tooltip_text.contains("1 enemies"), "Overwatch count persists")
	first.overwatch = false
	game.mission.pressure_state["pending"] = [{"turn":game.mission.turn + 2, "at":[2, 2], "kinds":["trooper"]}]
	game.hud_controls._refresh_cues31()
	check(game.hud_controls.cue_reinforcement31.visible and game.hud_controls.cue_reinforcement31.tooltip_text == "Reinforcements incoming", "incoming wave cue persists")
	game.mission.pressure_state["pending"] = []
	game.mission.reinforcement_marker = Vector2i(-1, -1)
	game.hud_controls._refresh_cues31()
	check(not game.hud_controls.cue_overwatch31.visible and not game.hud_controls.cue_reinforcement31.visible, "resolved cues clear")
	# Find a real cover geometry where a ranged enemy has the player flanked.
	var player: Dictionary = game.mission.living("player")[0]
	var found := false
	for y in range(2, int(game.mission.spec.height) - 2):
		if found: break
		for x in range(2, int(game.mission.spec.width) - 2):
			var tile := Vector2i(x, y)
			if not game.mission.passable(tile) or game.mission.occupied(tile): continue
			var probe := player.duplicate(); probe.x = x; probe.y = y
			for offset in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
				var at: Vector2i = tile + offset
				if not game.mission.passable(at) or game.mission.occupied(at): continue
				var shooter := first.duplicate(); shooter.x = at.x; shooter.y = at.y; shooter.range = 20.0
				var info: Dictionary = Shot.calculate(game.mission, shooter, probe, false)
				if bool(info.flanked) and bool(info.los) and bool(info.range_ok):
					player.x = x; player.y = y; first.x = at.x; first.y = at.y; first.range = 20.0; first.awake = true
					found = true
					break
			if found: break
	game.hud_controls._refresh_cues31()
	check(found and game.hud_controls.cue_flank31.visible, "flanked Jedi shows flank cue")
	first.awake = false
	game.hud_controls._refresh_cues31()
	check(not game.hud_controls.cue_flank31.visible, "flank cue clears when threat ends")

func _chain_hint(game: Node3D) -> void:
	var actor: Dictionary = game.mission.living("player")[0]
	var mode := ""
	var tag := ""
	for id in actor.get("kit", []):
		var def: Dictionary = game.mission.abilities.get(id, {})
		if str(def.get("target", "")) != "self": continue
		for entry in def.get("chain", {}).get("consume", []):
			if entry is Dictionary and str(entry.get("target", "target")) == "self":
				mode = str(id); tag = str(entry.get("tag", "")); break
		if mode != "": break
	if mode == "":
		check(false, "fixture has a self chain ability")
		return
	actor.combo_tags = {tag:int(actor.id)}
	actor.ap = 2; actor.focus_left = 99
	game.selected_id = int(actor.id)
	game.hud_controls.chain_hint_turn31 = -1
	game._refresh()
	var button: Button = game.action_buttons[mode]
	if game.hud_controls.bar != null: button = game.hud_controls.bar.copies[mode]
	var pulsed: bool = game.hud_controls.chain_hint_turn31 == game.mission.turn
	check(pulsed and game.mission.ability_reason(int(actor.id), mode) == "" and button.visible and button.has_meta("w31e_hint_pulse") and button.get_node_or_null("W31EChainHintPulse") != null, "available chain ability button pulses in tray")
	game._refresh()
	check(game.hud_controls.chain_hint_turn31 == game.mission.turn, "chain hint stays once per turn")

func _bench(game: Node3D) -> void:
	game.mission = Combat.adopt(Mission.new(2201))
	game.mission.rng.seed = 2201
	game.playing_enemy_events = true
	game.mission.presentation_active = true
	var enemies: Array[Dictionary] = game.mission.living("enemy")
	var player: Dictionary = game.mission.living("player")[0]
	var events: Array[Dictionary] = []
	for i in range(4):
		var enemy: Dictionary = enemies[i]
		enemy.awake = true; enemy.spotted = true
		var from := Shot.pos(enemy)
		var to := from + Vector2i(1, 0)
		if game.mission.tile(to) == "#": to = from + Vector2i(-1, 0)
		enemy.x = to.x; enemy.y = to.y
		events.append({"kind":"move", "actor":int(enemy.id), "from":from, "to":to, "path":[to]})
	var shooter: Dictionary = enemies[0]
	events.append({"kind":"attack", "actor":int(shooter.id), "target":int(player.id), "from":Shot.pos(shooter), "to":Shot.pos(player), "mode":"shoot", "enemy":true, "outcome":"hits", "damage":2, "killed":false})
	game._refresh_figures()
	var started := Time.get_ticks_msec()
	await Presentation.play(game, events, 0)
	var elapsed := Time.get_ticks_msec() - started
	print("E31 FEELCAM22 BENCH: %d ms" % elapsed)
	check(elapsed <= 602, "FEELCAM22 four moves and one attack stays within 602ms")
	Card.clear(game, true)
	game.playing_enemy_events = false

func run() -> void:
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	var game: Node3D = await fixture()
	await _card_and_cues(game)
	_chain_hint(game)
	game.queue_free()
	for i in 4: await process_frame
	var bench_game: Node3D = await fixture()
	await _bench(bench_game)
	bench_game.queue_free()
	for i in 4: await process_frame
	print("E31 RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
