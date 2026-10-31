extends RefCounted

const Shot = preload("res://scripts/shot.gd")

static func _point(mission: RefCounted, tile: Vector2i, height: float = 0.0) -> Vector3:
	return Vector3(tile.x, Shot.elevation(mission, tile) * 0.7 + height, tile.y)

static func play(game: Node3D, events: Array[Dictionary], sequence: int) -> void:
	for event in events:
		if not is_instance_valid(game) or sequence != game.enemy_frame_sequence: return
		var actor: Node3D = game.views.get(int(event.actor))
		match str(event.kind):
			"activation":
				game._glide_to(_point(game.mission, event.at), 0.2)
				await game.get_tree().create_timer(0.25).timeout
			"move":
				var destination: Vector3 = _point(game.mission, event.to)
				if actor != null:
					actor.position = _point(game.mission, event.from)
					actor.travel([destination])
				game._glide_to(destination, 0.2)
				await game.get_tree().create_timer(0.3).timeout
			"attack":
				var from: Vector3 = _point(game.mission, event.from, 1.15)
				var to: Vector3 = _point(game.mission, event.to, 1.1)
				game._glide_to((from + to) * 0.5, 0.22)
				await game.get_tree().create_timer(0.25).timeout
				if not is_instance_valid(game) or sequence != game.enemy_frame_sequence: return
				if actor != null: actor.face(to); actor.act("swing" if event.mode == "strike" else "shoot")
				if event.mode == "strike": game.fx.saber(from, to); game.sound.play("saber")
				else: game.fx.bolt(from, to, bool(event.enemy), int(event.damage) == 0); game.sound.play("shot")
				await game.get_tree().create_timer(0.16 if event.mode == "strike" else clampf(from.distance_to(to) / 38.0, 0.11, 0.31)).timeout
				if not is_instance_valid(game) or sequence != game.enemy_frame_sequence: return
				if int(event.damage) > 0:
					var victim: Node3D = game.views.get(int(event.target))
					if victim != null: victim.act("hit")
					game.fx.float_text(to + Vector3.UP * 0.6, "-%d" % int(event.damage), Color("ffad8d"))
					game.sound.play("hit")
					game._shake(0.07)
					if event.outcome == "crits" or bool(event.killed): game.fx.hit_stop()
				await game.get_tree().create_timer(0.12, true, false, true).timeout
			"push":
				var from: Vector3 = _point(game.mission, event.from, 1.1)
				var to: Vector3 = _point(game.mission, event.to, 1.1)
				game._glide_to((from + to) * 0.5, 0.2)
				await game.get_tree().create_timer(0.2).timeout
				if not is_instance_valid(game) or sequence != game.enemy_frame_sequence: return
				game.fx.shockwave(from, to); game.sound.play("push")
				var victim: Node3D = game.views.get(int(event.target))
				if victim != null: victim.stagger_to(_point(game.mission, event.destination))
				if int(event.damage) > 0:
					game.sound.play("hit")
					game.fx.float_text(to + Vector3.UP * 0.6, "-%d" % int(event.damage), Color("ffad8d"))
					if bool(event.killed): game.fx.hit_stop()
				await game.get_tree().create_timer(0.3).timeout
			"overwatch":
				if actor != null: game.fx.float_text(actor.position + Vector3.UP * 1.7, "OVERWATCH", Color("f2ba47"))
				await game.get_tree().create_timer(0.2).timeout
	if not is_instance_valid(game) or sequence != game.enemy_frame_sequence: return
	game.playing_enemy_events = false
	game.phase_banner.visible = false
	game._refresh()
	var active: Dictionary = game.mission.unit_by_id(game.selected_id)
	if not active.is_empty(): game._glide_to(_point(game.mission, Shot.pos(active)), 0.3)
