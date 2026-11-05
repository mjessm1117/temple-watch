extends RefCounted
const Shot = preload("res://scripts/shot.gd")

static func _point(m: RefCounted, tile: Vector2i, height: float = 0.0) -> Vector3:
	return Vector3(tile.x, Shot.elevation(m, tile) * 0.7 + height, tile.y)

static func drain(game: Node3D) -> void:
	decorate(game)
	while not game.mission.action_events.is_empty():
		var event: Dictionary = game.mission.action_events.pop_front()
		await show_event(game, event)
	decorate(game)
	for id in game.presentation_routes:
		var u: Dictionary = game.mission.unit_by_id(int(id))
		var view: Node3D = game.views.get(int(id))
		if view == null or int(u.get("hp",0)) <= 0: continue
		if not game.cam.skip_requested:
			view.travel(game.presentation_routes[id])
			while view.motion != null and view.motion.is_running() and not game.cam.skip_requested: await game.get_tree().process_frame
		if view.motion != null and view.motion.is_running(): view.motion.kill()
		view.position = _point(game.mission, Shot.pos(u))
	game.presentation_routes.clear()

static func play(game: Node3D, events: Array[Dictionary], _sequence: int) -> void:
	for event in events: await show_event(game, event)

static func show_event(game: Node3D, event: Dictionary) -> void:
	var actor: Node3D = game.views.get(int(event.actor))
	var kind := str(event.kind)
	if kind == "intent":
		var a: Dictionary = game.mission.unit_by_id(int(event.actor))
		var t: Dictionary = game.mission.unit_by_id(int(event.target))
		if int(a.get("hp", 0)) <= 0 or int(t.get("hp", 0)) <= 0: return
		if bool(event.get("reaction", false)):
			game.phase_banner.text = "REACTION FIRE"; game.phase_banner.visible = true
			var victim: Node3D = game.views.get(int(event.target))
			if victim != null:
				if victim.motion != null and victim.motion.is_running(): victim.motion.kill()
				victim.position = _point(game.mission, event.to)
		await game.cam.frame(_point(game.mission, event.from), _point(game.mission, event.to), str(event.mode))
		game.cam.trace.append("resolve_%d" % int(event.actor))
		event = game.mission.resolve_intent(event)
		if event.is_empty(): return
		game.mission.action_events.erase(event)
		kind = str(event.kind)
	elif kind in ["attack", "push"] and not bool(event.get("framed", false)):
		await game.cam.frame(_point(game.mission, event.from), _point(game.mission, event.to), str(event.get("mode", "push")))
	match kind:
		"objective_attack", "vip_attack":
			var to := _point(game.mission,event.to,1.0)
			if actor != null: game.fx.bolt(actor.position+Vector3.UP,to,true,false)
			game.fx.float_text(to,"-%d" % int(event.damage),Color("ffad8d"))
			await game.cam.wait(0.3)
		"reinforcement":
			game._refresh_figures()
			game.fx.float_text(_point(game.mission,event.at,1.8),"REINFORCEMENTS",Color("ffad8d"))
			await game.cam.wait(0.3)
		"activation":
			game.cam.finish()
			game._refresh_figures()
			actor = game.views.get(int(event.actor))
			if actor != null: actor.position = _point(game.mission, event.at)
			game.phase_banner.text = "PATROL ALERTED"
			await game.cam.frame(_point(game.mission, event.at), _point(game.mission, event.at), "reveal")
			await game.cam.wait(0.15)
		"move":
			game.cam.finish()
			if actor == null:
				game._refresh_figures(); actor = game.views.get(int(event.actor))
			if actor != null:
				actor.position = _point(game.mission, event.from)
				var points: Array[Vector3] = []
				var stop: Vector2i = event.to
				for queued in game.mission.action_events:
					if queued.kind == "intent" and bool(queued.get("reaction",false)) and int(queued.target) == int(event.actor): stop = queued.to; break
				var remainder: Array[Vector3] = []
				var past := false
				for p in event.get("path", [event.to]):
					if past: remainder.append(_point(game.mission,p))
					else: points.append(_point(game.mission,p))
					if p == stop: past = true
				if not remainder.is_empty(): game.presentation_routes[int(event.actor)] = remainder
				if not game.cam.skip_requested:
					game._glide_to(_point(game.mission, event.to), 0.35)
					actor.travel(points)
					while actor.motion != null and actor.motion.is_running() and not game.cam.skip_requested: await game.get_tree().process_frame
				if actor.motion != null and actor.motion.is_running(): actor.motion.kill()
				actor.position = _point(game.mission, stop)
		"attack", "push":
			await impact(game, event)
		"overwatch", "reload":
			if actor != null:
				await game.cam.frame(actor.position, actor.position, "reveal")
				game.fx.float_text(actor.position + Vector3.UP * 1.7, kind.to_upper(), Color("f2ba47"))
				if kind == "reload": actor.act("reload")
			await game.cam.wait(0.2)
	game.cam.finish()
	decorate(game)

static func decorate(game: Node3D) -> void:
	for u in game.mission.units:
		if not u.has("visual_tint") or int(u.get("hp",0)) <= 0: continue
		var view: Node3D = game.views.get(int(u.id))
		if view == null or view.has_meta("enemy11_tinted"): continue
		view.set_meta("enemy11_tinted",true)
		view.model.scale = Vector3.ONE * 1.2 * float(u.get("visual_scale",1.0))
		var overlay := StandardMaterial3D.new()
		overlay.albedo_color = Color(str(u.visual_tint),0.32)
		overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_tint(view.model,overlay)

static func _tint(node: Node, overlay: Material) -> void:
	if node is MeshInstance3D: node.material_overlay = overlay
	for child in node.get_children(): _tint(child,overlay)

static func impact(game: Node3D, event: Dictionary) -> void:
	var from := _point(game.mission, event.from, 1.15)
	var to := _point(game.mission, event.to, 1.1)
	var mode := str(event.get("mode", "push"))
	var actor: Node3D = game.views.get(int(event.actor))
	var victim: Node3D = game.views.get(int(event.target))
	if actor != null: actor.face(to); actor.act("cast" if mode == "push" else "swing" if mode == "strike" else "shoot")
	if mode == "push": game.fx.shockwave(from, to); game.sound.play("push")
	elif mode == "strike": game.fx.saber(from, to); game.sound.play("saber")
	else: game.fx.bolt(from, to, bool(event.get("enemy", false)), int(event.damage) == 0); game.sound.play("shot")
	await game.cam.wait(0.28 if mode == "push" else 0.16 if mode == "strike" else clampf(from.distance_to(to) / 38.0, 0.11, 0.31))
	var damage := int(event.damage)
	var outcome := str(event.get("outcome", ""))
	var word := "DEFLECT" if "deflected" in outcome else "MISS" if damage == 0 and mode != "push" else "CRIT %d" % damage if outcome == "crits" else "GRAZE %d" % damage if outcome == "grazes" else "-%d" % damage if damage > 0 else "PUSH"
	game.fx.float_text(to + Vector3.UP * 0.6, word, Color("ffca70") if outcome == "crits" else Color("a8eaff") if outcome == "grazes" else Color.WHITE, outcome == "crits")
	if int(event.get("armor_lost", 0)) > 0: game.fx.float_text(to + Vector3.UP * 0.15, "SHRED -%d" % int(event.armor_lost), Color("f0c68b"))
	if victim != null:
		if mode == "push": victim.stagger_to(_point(game.mission, event.destination))
		elif damage > 0: victim.act("hit")
		if bool(event.killed):
			var target: Dictionary = game.mission.unit_by_id(int(event.target))
			if str(target.side) == "player": victim.set_downed(true)
			else: victim.fall(); game.views.erase(int(event.target))
	if damage > 0: game.sound.play("hit")
	if not game.cam.skip_requested and (outcome == "crits" or bool(event.killed)): game.fx.hit_stop()
	if not game.cam.skip_requested and (outcome == "crits" or bool(event.killed)):
		await game.cam.impact_beat(to)
	if victim != null and not bool(event.killed): victim.set_status(game.mission.unit_by_id(int(event.target)))
	if actor != null: actor.set_status(game.mission.unit_by_id(int(event.actor)))
	game.cam.trace.append("impact_%d" % int(event.actor))
	game._sync_terrain()
	await game.cam.wait(0.18)
