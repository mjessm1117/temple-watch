extends SceneTree
const Mission = preload("res://scripts/combat_mission.gd")
const Base = preload("res://scripts/mission.gd")
const Shot = preload("res://scripts/shot.gd")
const Targeting = preload("res://scripts/combat_targeting.gd")
const InputControls = preload("res://scripts/input_controls.gd")
const HudControls = preload("res://scripts/hud_controls.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(reason)

func arena() -> RefCounted:
	var m := Mission.adopt(Base.new(7))
	for y in range(1, 25):
		for x in range(1, 25): m.set_tile(Vector2i(x,y), "_")
	var squad: Array = m.living("player")
	var enemy: Dictionary = m.living("enemy")[0]
	m.units.assign([squad[0], squad[1], squad[2], squad[3], enemy])
	for i in range(4): squad[i].x = 2; squad[i].y = 2 + i * 2
	enemy.x = 6; enemy.y = 6; enemy.awake = true; enemy.spotted = true
	return m

func run() -> void:
	var game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(game)
	await process_frame
	game.demo_mode = true; game.set_process(false)
	var m: RefCounted = arena(); game.mission = m
	var actor: Dictionary = m.units[2]; var enemy: Dictionary = m.units[4]
	game.selected_id = int(actor.id); game.action = "move"; game._refresh()
	var plate = game.hud_controls.night.vitals_label
	check(plate.text.contains("FOCUS %d" % int(actor.focus_left)), "plate restores focus from unit")
	check(plate.text.contains("MEDPACS %d" % int(actor.medpacs)), "plate restores medpacs from unit")
	check(plate.text.contains("AMMO %d/%d" % [int(actor.ammo), int(actor.clip)]), "plate restores ammo from unit")
	check(plate.text.contains("MOMENTUM %d/10" % int(m.momentum)), "plate restores mission momentum")
	check(not plate.text.contains("WILL"), "legacy unit without will hides field")
	actor.will = 4; game._refresh()
	check(plate.text.contains("WILL 4"), "unit with will shows numeric field")
	actor.erase("will"); game._refresh()
	check(plate.text.contains("HP ") and plate.text.contains("AP ") and plate.text.contains("BOND"), "plate keeps HP, AP and bond")
	var old_set: Array[String] = ["move", "shoot", "strike", "push", "free", "overwatch", "hunker"]
	for id in m.abilities:
		if id not in old_set: old_set.append(id)
	var actual_set: Array[String] = []
	for id in game.action_buttons: actual_set.append(id)
	old_set.sort(); actual_set.sort()
	check(actual_set == old_set, "inline bar set equals old base actions plus techniques menu")
	var expected: Array[String] = ["move"]
	for id in actor.get("kit", []):
		if m.abilities.has(id) and id not in expected: expected.append(id)
	for id in ["medpac", "revive"]:
		if m.abilities.has(id) and id not in expected: expected.append(id)
	for id in expected:
		check(game.action_buttons.has(id) and game.action_buttons[id].visible, "selected unit ability visible: " + id)
	var shoot: Button = game.action_buttons["shoot"]
	check(int(shoot.get("cost")) == int(m.abilities.shoot.ap), "button cost matches ability definition")
	actor.ap = 0; game._refresh()
	check(shoot.disabled and shoot.tooltip_text != "", "unusable ability has reason")
	actor.ap = 3; actor.cooldowns["shoot"] = m.turn + 2; game._refresh()
	check(int(shoot.get("cooldown")) == 2, "cooldown overlay has turns left")
	actor.cooldowns.erase("shoot")
	for width in [1366, 1920]:
		root.size = Vector2i(width, 768 if width == 1366 else 1080)
		await process_frame
		for member in m.living("player"):
			game.selected_id = int(member.id); game._refresh(); await process_frame
			for id in game.action_buttons:
				var button: Button = game.action_buttons[id]
				if button.visible:
					check(button.get_global_rect().end.x <= width + 1, "%d bar fits %s for %s" % [width, id, member.name])
					check(button.get_parent() is HFlowContainer, "%s is reachable without horizontal scroll" % id)
	game.selected_id = int(actor.id); game._refresh()
	check(game.action_buttons["free"].display_name == "Free Mira", "full Free Mira label")
	check(game.action_buttons["interact"].display_name == "Interact", "full Interact label")
	for id in ["free", "interact"]:
		var button: Button = game.action_buttons[id]
		var label_width: float = ThemeDB.fallback_font.get_string_size(button.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		check(label_width <= button.size.x - 47, id + " label fits drawn width")
	game.action = "shoot"; game.target_id = int(enemy.id); game._refresh()
	for fixture in ["open", "cover", "flank", "height"]:
		m.set_tile(Vector2i(5,6), "_"); actor.x = 2; actor.y = 6; enemy.x = 6; enemy.y = 6
		if fixture == "cover": m.set_tile(Vector2i(5,6), "c")
		if fixture == "flank": m.set_tile(Vector2i(5,6), "c"); actor.x = 9
		if fixture == "height": m.set_tile(Vector2i(2,6), "^")
		var data: Dictionary = Targeting.shot_breakdown(m, actor, enemy)
		var real: Dictionary = Shot.calculate(m, actor, enemy)
		var total := 0
		for item in data.aim_lines: total += int(item[1])
		game._show_shot()
		game.hud_controls.night.refresh_target()
		var summary: String = game.hud_controls.night.target_details.text
		var damage: Dictionary = Shot.damage_preview(actor, enemy)
		check(summary.contains("CRIT %d–%d" % [int(damage.critical[0]), int(damage.critical[1])]), fixture + " critical damage range")
		check(summary.contains("GRAZE %d–%d" % [int(damage.graze[0]), int(damage.graze[1])]), fixture + " graze damage range")
		check(summary.contains("SHRED %d on hit" % int(damage.shred)), fixture + " shred")
		check(summary.contains("AMMO %d/%d · %d AP" % [int(actor.ammo), int(actor.clip), int(m.abilities.shoot.ap)]), fixture + " ammo and AP")
		check(int(data.hit) == int(real.hit) and game.hit_big_label.text.begins_with("%d%%" % int(real.hit)), fixture + " displayed hit matches combat result")
		check(total == int(real.hit), fixture + " breakdown sums to hit chance")
		check(int(data.crit) == int(real.crit), fixture + " crit matches combat result")
	m.set_tile(Vector2i(2,6), "_"); m.set_tile(Vector2i(5,6), "_")
	actor.x = 2; actor.y = 2; enemy.x = 6; enemy.y = 6
	var other: Dictionary = enemy.duplicate(true); other.id = 100; other.x = 7; other.y = 6; m.units.append(other)
	game.target_id = -1; game._cycle_target(1)
	var first: int = game.target_id; game._cycle_target(1)
	check(first == int(enemy.id) and game.target_id == 100, "target cycle follows sorted visible enemy ids")
	game._cycle_target(-1); check(game.target_id == first, "reverse cycle returns to prior target")
	game.action = "move"; game.target_id = -1
	var walk: Dictionary = InputControls.move_preview(m, actor, Vector2i(3,2))
	var dash: Dictionary = InputControls.move_preview(m, actor, Vector2i(2 + int(actor.mob) + 1,2))
	check(int(walk.ap) == 1 and HudControls.move_color(int(walk.ap)) == Color("60b9ff"), "one AP movement is blue")
	check(int(dash.ap) == 2 and HudControls.move_color(int(dash.ap)) == Color("ffd16a"), "dash movement is yellow")
	check(HudControls.move_fill(1).a >= 0.5 and HudControls.move_fill(2).a >= 0.5, "move tile fill alpha is visible")
	var shields_node := Node3D.new(); game.add_child(shields_node)
	game.hud_controls._shield(shields_node, Vector2i(3, 2), Vector2i.UP, true)
	game.hud_controls._shield(shields_node, Vector2i(3, 2), Vector2i.RIGHT, false)
	check(shields_node.get_child_count() == 2, "destination draws both cover shield types")
	check(shields_node.get_child(0).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 9, "full cover shield has solid fill")
	check(shields_node.get_child(1).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 30, "half cover shield has outline")
	m.set_tile(Vector2i(4,3), "c"); enemy.x = 6; enemy.y = 4
	var exposed: Dictionary = InputControls.move_preview(m, actor, Vector2i(4,4))
	check(not exposed.is_empty() and not exposed.flanks.is_empty(), "visible enemy flanking destination triggers warning")
	check(int(exposed.shields.N) == 20, "destination shows half cover shield")
	m.phase = "enemy"; await process_frame
	check(game.hud_controls.night.phase_text.text == "ENEMY ACTIVITY", "enemy banner appears")
	m.phase = "player"; await process_frame
	check(game.hud_controls.night.phase_text.text == "JEDI TURN", "Jedi banner appears")
	actor.hunkered = true; game._refresh()
	check(game.hud_controls.night.status_row.get_child_count() > 0 and game.hud_controls.night.status_row.get_child(0).tooltip_text == "Hunkered", "status icon explains its effect")
	game._request_end_turn()
	check(game.end_turn_armed and game.warning_label.text.contains("still"), "end turn asks when actions remain")
	var esc := InputEventKey.new(); esc.keycode = KEY_ESCAPE; esc.pressed = true
	game.hud_controls.night._unhandled_input(esc)
	check(game.hud_controls.night.pause_back.visible, "Esc opens pause menu from idle")
	game.hud_controls.night._unhandled_input(esc)
	check(not game.hud_controls.night.pause_back.visible, "Esc resumes from pause menu")
	game.queue_free(); await process_frame
	print("HUD NIGHT1 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
