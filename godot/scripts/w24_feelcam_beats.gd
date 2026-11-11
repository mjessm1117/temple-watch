extends RefCounted
## Presentation only. Rules and damage remain with the mission.

static func cue(game: Node3D, kind: String, point: Vector3, power: float = 1.0) -> void:
	if game.fx != null and game.fx.has_method("impact24_cue"):
		game.fx.call("impact24_cue", kind, point, power)

static func nudge(view: Node3D, direction: Vector3, dodge: bool = false) -> void:
	if view == null or not is_instance_valid(view) or view.model == null: return
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	if flat.length_squared() < 0.01: flat = Vector3.RIGHT
	var origin: Vector3 = view.model.position
	var tween := view.create_tween()
	tween.tween_property(view.model, "position", origin + flat * (0.42 if dodge else 0.16), 0.07).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(view.model, "position", origin, 0.16 if dodge else 0.12).set_trans(Tween.TRANS_SINE)

static func impact(game: Node3D, event: Dictionary, from: Vector3, to: Vector3, victim: Node3D) -> void:
	var damage := int(event.get("damage", 0))
	var direction := to - from
	if damage > 0:
		# Bolt, saber, and Force already emit the ordinary contact cue in fx.gd.
		if str(event.get("outcome", "")) == "crits": cue(game, "crit", to, 1.2)
		if game.fx != null and game.fx.has_method("hit_stop") and not game.cam.skip_requested: game.fx.hit_stop(0.055)
		nudge(victim, direction)
		if bool(event.get("killed", false)): cue(game, "kill", to, 1.0)
	elif str(event.get("mode", "")) != "push":
		var near := to + Vector3(-direction.z, 0.0, direction.x).normalized() * 0.45
		cue(game, "miss_near", near)
		nudge(victim, near - to, true)
	clutch(game, event, to)

static func clutch(game: Node3D, event: Dictionary, point: Vector3) -> void:
	if game.clutch_turn24 == int(game.mission.turn): return
	var target: Dictionary = game.mission.unit_by_id(int(event.get("target", -1)))
	var text24 := ""
	if bool(event.get("cover_broken", false)) or str(event.get("kind", "")) == "cover_break": text24 = "COVER BROKEN"
	elif str(target.get("side", "")) == "player" and int(event.get("damage", 0)) > 0:
		if int(target.get("hp", 0)) == 1: text24 = "STILL STANDING  •  1 HP"
		elif game.mission.living("player").size() == 1: text24 = "LAST UNIT STANDING"
	if text24 == "": return
	game.clutch_turn24 = int(game.mission.turn)
	game.phase_banner.text = text24
	game.phase_banner.visible = true
	if game.fx != null and game.fx.has_method("float_text"): game.fx.float_text(point + Vector3.UP * 0.8, text24, Color("ffe39b"))
	if game.fx != null and game.fx.has_method("hit_stop") and not game.cam.skip_requested: game.fx.hit_stop(0.065)

static func leap(game: Node3D, actor_id: int, start: Vector3, finish: Vector3) -> void:
	var view: Node3D = game.views.get(actor_id)
	if view == null or not is_instance_valid(view): return
	view.position = start
	view.face(finish)
	var tween := view.create_tween()
	tween.tween_method(func(t: float) -> void:
		if is_instance_valid(view): view.position = start.lerp(finish, t) + Vector3.UP * sin(t * PI) * maxf(1.6, start.distance_to(finish) * 0.24), 0.0, 1.0, 0.26).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	if not is_instance_valid(view): return
	view.position = finish
	cue(game, "leap_land", finish)
