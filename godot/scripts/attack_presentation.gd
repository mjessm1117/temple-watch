extends RefCounted

static func play(game: Node3D, event: Dictionary) -> void:
	var actor: Node3D = game.views.get(int(event.actor))
	var target: Node3D = game.views.get(int(event.target))
	if actor != null: actor.face(event.to); actor.act("cast" if event.mode == "push" else "swing" if event.mode == "strike" else "shoot")
	if target != null:
		target.face(event.from)
		if int(event.damage) > 0 and not bool(event.killed): target.act("hit")
		if event.mode == "push" and bool(event.moved): target.stagger_to(event.destination)
	if event.mode == "push": game.fx.shockwave(event.from, event.to); game.sound.play("push")
	elif event.mode == "strike": game.fx.saber(event.from, event.to); game.sound.play("saber")
	else: game.fx.bolt(event.from, event.to, false, int(event.damage) == 0); game.sound.play("shot")
	var travel := 0.16 if event.mode == "strike" else 0.28 if event.mode == "push" else clampf(event.from.distance_to(event.to) / 38.0, 0.11, 0.31)
	await game.get_tree().create_timer(travel).timeout
	if not is_instance_valid(game): return
	var damage: int = int(event.damage)
	var outcome: String = str(event.outcome)
	var word := "MISS" if damage == 0 and event.mode != "push" else "CRIT %d" % damage if "crits" in outcome else "GRAZE %d" % damage if "grazes" in outcome else "-%d" % damage if damage > 0 else "PUSH"
	game.fx.float_text(event.to + Vector3.UP * 0.6, word, Color("ffca70") if "CRIT" in word else Color("a8eaff") if "GRAZE" in word else Color("ffffff"), "CRIT" in word)
	if bool(event.armor_lost): game.fx.float_text(event.to + Vector3.UP * 0.15, "ARMOR -1", Color("f0c68b"))
	if damage > 0: game.sound.play("hit")
	if damage > 0 and ("crits" in outcome or bool(event.killed)): game.fx.hit_stop()
	if bool(event.killed): game._shake(0.16); game.sound.play("death")
	elif "crits" in outcome: game._shake(0.12)
	await game.get_tree().create_timer(0.18, true, false, true).timeout
	if not is_instance_valid(game): return
	game.player_attack_pending = false
	game._after_action()
	game._refresh()
