extends SceneTree
const Mission = preload("res://scripts/mission.gd")
const Pressure = preload("res://scripts/mission_pressure.gd")
const Villain = preload("res://scripts/villain11_battle.gd")
const Marker = preload("res://scripts/reinforcement_marker.gd")
const Plate = preload("res://scripts/enemy11_plate.gd")
const Settings = preload("res://scripts/settings.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func run() -> void:
	Settings.difficulty = "normal"
	var rescue: RefCounted = Mission.new(17)
	var legacy: Dictionary = Pressure.threat_summary(rescue)
	check(legacy.pending_groups.size() == 0, "rescue hides unannounced wave")
	rescue.turn = int(rescue.spec.reinforcement.announce_turn)
	rescue.reinforcement_announced = true
	legacy = Pressure.threat_summary(rescue)
	check(legacy.pending_groups.size() == 1, "rescue has one scheduled wave")
	check(int(legacy.pending_groups[0].count) == int(rescue.difficulty.reinforcement_size), "rescue count follows difficulty")
	check(legacy.pending_groups[0].entry_pos == Vector2i(int(rescue.spec.reinforcement.units[0][1]), int(rescue.spec.reinforcement.units[0][2])), "rescue entry is real spawn tile")
	check(int(legacy.pending_groups[0].turns) == int(rescue.spec.reinforcement.drop_turn) - rescue.turn, "rescue wave clock")
	check(int(legacy.objective_risk) == 0 and legacy.villain.is_empty(), "rescue has no relay or villain")
	var group: Array = []
	for enemy in rescue.living("enemy"):
		if int(enemy.group) == 0: group.append(enemy)
	var reveal: Dictionary = Pressure.reveal_info(rescue, group)
	check(int(reveal.count) == group.size() and group.size() >= 2, "rescue reveal counts actual group")
	check(reveal.types.size() >= 1 and str(reveal.threat_line).contains(str(group.size())), "rescue reveal names types and count")
	var plate := Plate.new()
	root.add_child(plate)
	plate.show_reveal(rescue, group)
	check(plate.label.text.contains(str(group.size())) and plate.label.text.contains(str(reveal.types[0])), "plate shows group type and exact count")
	check(plate.panel.position.x >= 12.0 and plate.panel.position.y >= 12.0 and plate.panel.position.x + plate.panel.custom_minimum_size.x <= root.size.x - 12.0 and plate.label.get_theme_font_size("font_size") >= 14, "plate respects phone edge and text size")
	plate.queue_free()
	var relay: RefCounted = Mission.new(17, "res://data/maps/relay.json")
	var summary: Dictionary = Pressure.threat_summary(relay)
	check(summary.pending_groups.size() == 1 and int(summary.pending_groups[0].turns) == 2, "gate wave gives two setup turns")
	check(int(summary.pending_groups[0].count) == relay.spec.wave_roster[0].size(), "gate wave count matches roster")
	check(summary.pending_groups[0].types.size() >= 1, "gate wave reports enemy types")
	var marker_parent := Node3D.new()
	root.add_child(marker_parent)
	var marker := Marker.new()
	marker_parent.add_child(marker)
	await process_frame
	marker.show_tile(summary.pending_groups[0].entry_pos, relay)
	check(marker.visible and marker.shown_tile == summary.pending_groups[0].entry_pos, "gate marker uses wave entry")
	check(marker.wave_label.text.contains(str(summary.pending_groups[0].count)), "gate marker displays count")
	var target: Vector2i = Vector2i(int(relay.spec.objective.points[0][0]), int(relay.spec.objective.points[0][1]))
	var attacker: Dictionary = relay.living("enemy")[0]
	for enemy in relay.living("enemy"):
		if enemy != attacker: enemy.spotted = false; enemy.detected = false
	attacker.x = target.x + 1; attacker.y = target.y
	attacker.awake = true; attacker.spotted = true
	check(int(Pressure.threat_summary(relay).objective_risk) == 2, "gate objective forecasts two damage from one attacker")
	var player: Dictionary = relay.living("player")[0]
	attacker.x = int(player.x) + 1; attacker.y = int(player.y)
	check(Pressure.threat_summary(relay).exposed_units.has(int(player.id)), "known firing lane exposes real player id")
	marker_parent.queue_free()
	var caves: RefCounted = Mission.new(17, "res://data/maps/r_caves.json")
	Villain.setup(caves, {"villain_present":true,"villain_name":"Darth Bane","villain_intro_line":"Bane enters.","villain_retreat_line":"Bane leaves.","villain_start_bark":"Bane enters.","villain_end_bark":"Bane leaves."})
	var villain: Dictionary = Pressure.threat_summary(caves).villain
	check(villain.name == "Darth Bane" and villain.status == "arriving" and villain.line == "Bane enters.", "named arrival state and intro")
	Villain.mark_present(caves)
	check(Pressure.threat_summary(caves).villain.status == "present", "villain becomes present")
	var rival: Dictionary = caves.units.filter(func(u): return bool(u.get("villain11", false)))[0]
	Villain.on_damage(caves, rival)
	rival.hp = 1
	Villain.on_damage(caves, rival)
	villain = Pressure.threat_summary(caves).villain
	check(villain.status == "retreating" and villain.line == "Bane leaves.", "retreat state has separate line")
	print("THREAT22: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
