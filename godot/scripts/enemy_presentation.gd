extends RefCounted
const Shot = preload("res://scripts/shot.gd")
const Events = preload("res://scripts/feelcam22_events.gd")
const Pressure = preload("res://scripts/mission_pressure.gd")
const FeelBeats24 = preload("res://scripts/w24_feelcam_beats.gd")

static func _point(m: RefCounted, tile: Vector2i, height: float = 0.0) -> Vector3:
	return Vector3(tile.x, Shot.elevation(m, tile) * 0.7 + height, tile.y)

static func drain(game: Node3D) -> void:
	decorate(game)
	while not game.mission.action_events.is_empty():
		var event: Dictionary = game.mission.action_events.pop_front()
		if str(event.kind) != "move": await flush_quiet(game)
		await show_event(game, event)
	decorate(game)
	if not game.presentation_routes.is_empty(): await flush_quiet(game)
	for id in game.presentation_routes:
		var u: Dictionary = game.mission.unit_by_id(int(id))
		var view: Node3D = game.views.get(int(id))
		if view == null or int(u.get("hp",0)) <= 0: continue
		if not game.cam.skip_requested:
			var meta24: Dictionary = game.presentation_route_meta24.get(id, {})
			if view.has_method("travel24"): view.travel24(game.presentation_routes[id], bool(meta24.get("dash", false)), meta24.get("segments", []))
			else: view.travel(game.presentation_routes[id])
			while view.motion != null and view.motion.is_running() and not game.cam.skip_requested: await game.get_tree().process_frame
		if view.motion != null and view.motion.is_running(): view.motion.kill()
		view.position = _point(game.mission, Shot.pos(u))
	game.presentation_routes.clear()
	game.presentation_route_meta24.clear()

static func flush_quiet(game: Node3D) -> void:
	for view in game.quiet_motions:
		if not is_instance_valid(view): continue
		while view.motion != null and view.motion.is_running() and not game.cam.skip_requested:
			await game.get_tree().process_frame
		if view.motion != null and view.motion.is_running(): view.motion.kill()
		if game.quiet_targets.has(view.unit_id): view.position = game.quiet_targets[view.unit_id]
	game.quiet_motions.clear()
	game.quiet_targets.clear()

static func play(game: Node3D, events: Array[Dictionary], _sequence: int) -> void:
	for event in events:
		if str(event.kind) != "move": await flush_quiet(game)
		await show_event(game, event)
	await flush_quiet(game)

static func show_event(game: Node3D, event: Dictionary) -> void:
	var actor: Node3D = game.views.get(int(event.get("actor", -1)))
	var kind := str(event.kind)
	if game.playing_enemy_events and kind in ["intent", "attack", "push", "move", "overwatch", "reload", "objective_attack", "vip_attack"]:
		var reason := str(event.get("intent_reason24", event.get("intent_reason", "")))
		if reason == "" and game.mission.has_method("intent_reason24"): reason = str(game.mission.call("intent_reason24", event))
		if reason != "": game.phase_banner.text = reason
		game.phase_banner.visible = true
		if reason != "" and actor != null and game.fx != null and game.fx.has_method("float_text"):
			game.fx.float_text(actor.position + Vector3.UP * 2.2, game.phase_banner.text, Color("ffe39b"))
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
		var intent_info: Dictionary = event.get("info", {})
		event = game.mission.resolve_intent(event)
		if event.is_empty(): return
		event.flanked = bool(intent_info.get("flanked", false))
		game.mission.action_events.erase(event)
		kind = str(event.kind)
	elif kind in ["attack", "push"] and not bool(event.get("framed", false)):
		await game.cam.frame(_point(game.mission, event.from), _point(game.mission, event.to), str(event.get("mode", "push")))
	match kind:
		"objective_attack", "vip_attack":
			game._refresh()
			var to := _point(game.mission,event.to,1.0)
			var from := actor.position + Vector3.UP if actor != null else _point(game.mission, event.get("from", event.to), 1.0)
			await game.cam.frame(from, to, "objective")
			game.fx.bolt(from, to, true, false)
			var hp := Events.objective_hp(game, kind)
			game.fx.float_text(to + Vector3.UP * 0.7, "GATE %d HP  -%d" % [hp, int(event.damage)] if kind == "objective_attack" else "VIP %d HP  -%d" % [hp, int(event.damage)], Color("ffad8d"))
			var source: Dictionary = game.mission.unit_by_id(int(event.actor))
			game.phase_banner.text = "%s HIT  •  %d HP  •  %s" % ["GATE" if kind == "objective_attack" else "VIP", hp, str(source.get("name", "ENEMY"))]
			game.phase_banner.visible = true
			Events.emit(game, "objective_hit", event, to, {"source_pos":from})
			Events.cue(game, "objective_hit")
			await game.cam.wait(0.25)
		"reinforcement":
			game._refresh_figures()
			game.fx.float_text(_point(game.mission,event.at,1.8),"REINFORCEMENTS",Color("ffad8d"))
			Events.emit(game, "reinforce", event, _point(game.mission,event.at))
			await game.cam.wait(0.3)
		"activation":
			game._refresh_figures()
			actor = game.views.get(int(event.actor))
			if actor != null: actor.position = _point(game.mission, event.at)
			var unit: Dictionary = game.mission.unit_by_id(int(event.actor))
			var group_id := int(unit.get("group", -1))
			if group_id != game.last_reveal_group:
				game.last_reveal_group = group_id
				var members: Array = []
				var center := Vector3.ZERO
				for enemy in game.mission.living("enemy"):
					if int(enemy.get("group", -2)) != group_id: continue
					members.append(enemy)
					center += _point(game.mission, Shot.pos(enemy))
				if not members.is_empty(): center /= float(members.size())
				var pressure_script: Script = Pressure
				var info: Dictionary = pressure_script.call("reveal_info", game.mission, members) if pressure_script.has_method("reveal_info") else {}
				game.phase_banner.text = str(info.get("title", "PATROL ALERTED"))
				game.phase_banner.visible = true
				await game.cam.frame(center, center, "reveal")
				Events.emit(game, "reveal", event, center, {"group":group_id, "count":members.size(), "title":game.phase_banner.text})
				Events.cue(game, "alert")
				Events.music(game, "contact")
				await game.cam.wait(0.12)
		"move":
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
				if not remainder.is_empty():
					game.presentation_routes[int(event.actor)] = remainder
					var remaining_segments24: Array = preload("res://scripts/w24_threat_route.gd").segments(game.mission, event.get("path", [event.to]), event.from).slice(points.size()) if game.mission.has_method("route_segments24") else []
					game.presentation_route_meta24[int(event.actor)] = {"dash":bool(event.get("dash24", false)), "segments":remaining_segments24}
				if not game.cam.skip_requested:
					var route24: Array = event.get("path", [event.to])
					var segments24: Array = preload("res://scripts/w24_threat_route.gd").segments(game.mission, route24, event.from) if game.mission.has_method("route_segments24") else []
					if actor.has_method("travel24"): actor.travel24(points, bool(event.get("dash24", false)), segments24.slice(0, points.size()))
					else: actor.travel(points)
					if not game.quiet_motions.has(actor): game.quiet_motions.append(actor)
					game.quiet_targets[int(event.actor)] = _point(game.mission, stop)
				else: actor.position = _point(game.mission, stop)
		"attack", "push":
			await impact(game, event)
		"overwatch", "reload":
			if actor != null:
				await game.cam.frame(actor.position, actor.position, "reveal")
				game.fx.float_text(actor.position + Vector3.UP * 1.7, kind.to_upper(), Color("f2ba47"))
				if kind == "reload": actor.act("reload")
			await game.cam.wait(0.2)
		"cover_break":
			FeelBeats24.clutch(game, event, _point(game.mission, event.get("at", Vector2i.ZERO)))
			FeelBeats24.cue(game, "cover_break", _point(game.mission, event.get("at", Vector2i.ZERO)))
	if kind != "move": game.cam.finish()
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
	# Keep the side rim and chest band on meshes already decorated for readability.
	if node is MeshInstance3D and not node.has_meta("gfx_rim"): node.material_overlay = overlay
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
	if damage > 0:
		Events.emit(game, "hit", event, to)
		Events.cue(game, "hit")
		Events.music(game, "contact")
		if bool(event.get("flanked", false)): Events.emit(game, "flank", event, to)
		if outcome == "crits": Events.emit(game, "crit", event, to); Events.cue(game, "crit")
		var target_data: Dictionary = game.mission.unit_by_id(int(event.target))
		if str(target_data.get("side", "")) == "player": Events.emit(game, "hurt", event, to)
		if bool(event.killed): Events.emit(game, "kill", event, to); Events.cue(game, "kill")
		if not game.villain_retreat_seen and str(game.mission.objective_state.get("villain_outcome", "")) == "retreated":
			game.villain_retreat_seen = true
			Events.emit(game, "villain_retreat", event, to)
	elif mode != "push": Events.emit(game, "miss", event, to)
	FeelBeats24.impact(game, event, from, to, victim)
	var word := "DEFLECT" if "deflected" in outcome else "MISS" if damage == 0 and mode != "push" else "KILL -%d" % damage if bool(event.get("killed", false)) else "CRIT %d" % damage if outcome == "crits" else "GRAZE %d" % damage if outcome == "grazes" else "-%d" % damage if damage > 0 else "PUSH"
	game.fx.float_text(to + Vector3.UP * 0.6, word, Color("ffca70") if outcome == "crits" or bool(event.get("killed", false)) else Color("a8eaff") if outcome == "grazes" else Color.WHITE, outcome == "crits" or bool(event.get("killed", false)))
	if int(event.get("armor_lost", 0)) > 0: game.fx.float_text(to + Vector3.UP * 0.15, "SHRED -%d" % int(event.armor_lost), Color("f0c68b"))
	if victim != null:
		if mode == "push": victim.stagger_to(_point(game.mission, event.destination))
		elif damage > 0: victim.act("hit")
		if bool(event.killed):
			var target: Dictionary = game.mission.unit_by_id(int(event.target))
			if str(target.side) == "player": victim.set_downed(true)
			else:
				if victim.has_method("fall24"): victim.call("fall24", -1, to - from)
				else: victim.fall()
				game.views.erase(int(event.target))
	if damage > 0: game.sound.play("hit")
	if not game.cam.skip_requested and (outcome == "crits" or bool(event.killed)) and not bool(event.get("killcam_played", false)):
		await game.cam.impact_beat(to)
	if victim != null and not bool(event.killed): victim.set_status(game.mission.unit_by_id(int(event.target)))
	if actor != null: actor.set_status(game.mission.unit_by_id(int(event.actor)))
	game.cam.trace.append("impact_%d" % int(event.actor))
	game._sync_terrain()
	await game.cam.wait(0.06 if bool(event.killed) or game.playing_enemy_events else 0.10)
