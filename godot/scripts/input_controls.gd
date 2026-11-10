extends RefCounted

const Shot = preload("res://scripts/shot.gd")
const Ability = preload("res://scripts/abilities_engine.gd")

static func move_preview(m: RefCounted, unit: Dictionary, dest: Vector2i) -> Dictionary:
	if unit.is_empty() or int(unit.get("ap", 0)) <= 0: return {}
	var route: Dictionary = m.paths(unit, int(unit.mob) * 2)
	if not route.costs.has(dest) or dest == Shot.pos(unit): return {}
	var cost: int = int(route.costs[dest])
	var ap_cost: int = 1 if cost <= int(unit.mob) else 2
	if int(unit.ap) < ap_cost: return {}
	var shields: Dictionary = {}
	for entry in [["N", Vector2i.UP], ["E", Vector2i.RIGHT], ["S", Vector2i.DOWN], ["W", Vector2i.LEFT]]:
		shields[entry[0]] = Shot.cover(m, dest, dest + entry[1] * 2)
	var flanks: Array[String] = []
	var probe: Dictionary = unit.duplicate()
	probe.x = dest.x; probe.y = dest.y
	for enemy in m.living("enemy"):
		if not bool(enemy.awake) and not bool(enemy.get("spotted", false)): continue
		var shot_info: Dictionary = Shot.calculate(m, enemy, probe)
		if bool(shot_info.flanked) and bool(shot_info.los) and bool(shot_info.range_ok): flanks.append(str(enemy.name))
	return {"ap": ap_cost, "tiles": cost, "prev": route.prev, "shields": shields, "flanks": flanks}

static func valid_targets(m: RefCounted, unit: Dictionary, mode: String) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	if mode not in ["shoot", "strike", "push"]:
		if Ability.reason(m, unit, mode) != "": return targets
		return Ability.targets(m, unit, mode)
	if unit.is_empty() or mode not in ["shoot", "strike", "push"] or m.phase != "player" or m.result != "": return targets
	if mode not in unit.get("kit", []): return targets
	if int(unit.ap) < int(m.abilities[mode].ap): return targets
	if mode == "shoot" and int(unit.get("ammo", 1)) <= 0: return targets
	if mode == "push" and int(unit.get("focus_left", 0)) < int(m.abilities.push.focus): return targets
	if mode == "push" and int(unit.get("focus", 0)) <= 0: return targets
	for target in m.living("enemy"):
		if not bool(target.awake) and not bool(target.get("spotted", false)): continue
		if mode == "strike" and max(abs(int(unit.x) - int(target.x)), abs(int(unit.y) - int(target.y))) > 1: continue
		if mode == "push" and Shot.distance(Shot.pos(unit), Shot.pos(target)) > float(m.abilities.push.range): continue
		var info: Dictionary = Shot.calculate(m, unit, target, mode == "strike")
		if not bool(info.los) or (mode != "push" and not bool(info.range_ok)): continue
		targets.append(target)
	targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da: float = Shot.distance(Shot.pos(unit), Shot.pos(a))
		var db: float = Shot.distance(Shot.pos(unit), Shot.pos(b))
		return int(a.id) < int(b.id) if is_equal_approx(da, db) else da < db)
	return targets

static func next_squad(m: RefCounted, current_id: int, direction: int = 1, only_ready: bool = false) -> int:
	var squad: Array[Dictionary] = m.living("player")
	if squad.is_empty(): return -1
	var index := -1
	for i in range(squad.size()):
		if int(squad[i].id) == current_id: index = i
	for offset in range(1, squad.size() + 1):
		var candidate: Dictionary = squad[posmod(index + offset * direction, squad.size())]
		if not only_ready or int(candidate.ap) > 0: return int(candidate.id)
	return -1

static func near_unit(game, point: Vector2, candidates: Array[Dictionary]) -> Dictionary:
	if not preload("res://scripts/phone_layout.gd").narrow(preload("res://scripts/phone_layout.gd").window_size()): return {}
	var closest := 28.0
	var picked: Dictionary = {}
	for unit in candidates:
		var distance := unit_screen_distance(game, point, unit)
		if distance < closest: closest = distance; picked = unit
	return picked

static func unit_screen_distance(game, point: Vector2, unit: Dictionary) -> float:
	var tile := Shot.pos(unit)
	var center: Vector2 = game.camera.unproject_position(Vector3(tile.x, Shot.elevation(game.mission, tile) * 0.7 + 1.0, tile.y))
	return center.distance_to(point)

var g

func handle_event(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
			g.camera_tween = g.create_tween()
			g.camera_tween.tween_property(g, "zoom", g.zoom + (-2.5 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 2.5), 0.25).set_trans(Tween.TRANS_SINE)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			g.drag_button = MOUSE_BUTTON_MIDDLE if event.pressed else 0
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and (g.action != "move" or g.preview_tile.x >= 0): g._cancel_order(); return
			g.drag_button = MOUSE_BUTTON_RIGHT if event.pressed else 0
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if g.cam.preview_active and g.cam.preview_tween != null and g.cam.preview_tween.is_running():
				g.cam.skip_preview_transition(); return
			if g.cinematic: g._skip_cinematic()
			var p: Vector2i = g._screen_tile(event.position)
			var nearby_player := near_unit(g, event.position, g.mission.living("player"))
			if not nearby_player.is_empty() and p.x >= 0 and Shot.pos(nearby_player) != p: nearby_player = {}
			var nearby_attack_target: Dictionary = {}
			if g.action in ["shoot", "strike", "push"]:
				nearby_attack_target = near_unit(g, event.position, valid_targets(g.mission, g.mission.unit_by_id(g.selected_id), g.action))
				if not nearby_attack_target.is_empty() and not nearby_player.is_empty():
					if unit_screen_distance(g, event.position, nearby_player) < unit_screen_distance(g, event.position, nearby_attack_target): nearby_attack_target = {}
					else: nearby_player = {}
			if g.action not in ["move", "shoot", "strike", "push", "free", "overwatch", "hunker"]:
				var def: Dictionary = g.mission.abilities.get(g.action, {})
				if str(def.get("target", "")).begins_with("ally") or str(def.get("target", "")).begins_with("enemy"):
					var targets := valid_targets(g.mission, g.mission.unit_by_id(g.selected_id), g.action)
					var nearby_target := near_unit(g, event.position, targets)
					if not nearby_target.is_empty() and not nearby_player.is_empty():
						if unit_screen_distance(g, event.position, nearby_player) < unit_screen_distance(g, event.position, nearby_target): nearby_target = {}
						else: nearby_player = {}
					for target in targets:
						if (not nearby_target.is_empty() and int(target.id) == int(nearby_target.id)) or (nearby_target.is_empty() and nearby_player.is_empty() and Shot.pos(target) == p):
							if g.target_id == int(target.id): g._use_ability(int(target.id))
							else: g.target_id = int(target.id); g._refresh_highlights(); g._show_shot()
							return
				elif p in Ability.tiles(g.mission, g.mission.unit_by_id(g.selected_id), g.action):
					if g.preview_tile == p: g._use_ability(-1, p)
					else: g.preview_tile = p; g._refresh_highlights(); g._show_shot()
					return
			if not nearby_player.is_empty(): g._select(int(nearby_player.id)); return
			for u in g.mission.living("player"):
				if nearby_attack_target.is_empty() and Shot.pos(u) == p: g._select(int(u.id)); return
			if g.action == "move" and g.selected_id >= 0:
				var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
				var enemies: Array[Dictionary] = []
				if "shoot" in actor.get("kit", []): enemies = valid_targets(g.mission, actor, "shoot")
				var tapped_enemy: Dictionary = near_unit(g, event.position, enemies)
				if tapped_enemy.is_empty():
					for enemy in enemies:
						if Shot.pos(enemy) == p: tapped_enemy = enemy; break
				if not tapped_enemy.is_empty():
					g._choose_action("shoot")
					g.target_id = int(tapped_enemy.id)
					g._frame_target(); g._refresh_highlights(); g._show_shot(); g._refresh()
					return
			if g.action == "move":
				var preview: Dictionary = move_preview(g.mission, g.mission.unit_by_id(g.selected_id), p)
				if preview.is_empty(): return
				if g.preview_tile == p: g._move_selected(p)
				else:
					g.preview_tile = p
					g._refresh_highlights()
			elif g.action == "free":
				if p.x >= 0 and g.mission.free_prisoner(g.selected_id): g._after_action(); g._refresh()
			elif g.action in ["shoot", "strike", "push"]:
				var targets := valid_targets(g.mission, g.mission.unit_by_id(g.selected_id), g.action)
				var nearby_target := nearby_attack_target
				for target in targets:
					if (not nearby_target.is_empty() and int(target.id) == int(nearby_target.id)) or (nearby_target.is_empty() and nearby_player.is_empty() and Shot.pos(target) == p):
						if g.target_id == int(target.id) and g.hud_controls.phone == null: g._attack(g.target_id, g.action)
						else: g.target_id = int(target.id); g._frame_target(); g._refresh_highlights(); g._show_shot(); g._refresh()
						return
	elif event is InputEventMouseMotion:
		if g.drag_button == MOUSE_BUTTON_MIDDLE:
			if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
			g.yaw -= event.relative.x * 0.008; g.pitch += event.relative.y * 0.008; g._update_camera()
		elif g.drag_button == MOUSE_BUTTON_RIGHT:
			if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
			var right: Vector3 = g.camera.global_basis.x
			var forward: Vector3 = -g.camera.global_basis.z; forward.y = 0; forward = forward.normalized()
			g.pivot += (-right * event.relative.x + forward * event.relative.y) * g.zoom * 0.0015
			g._update_camera()
		else:
			var p: Vector2i = g._screen_tile(event.position)
			if p != g.hovered: g.hovered = p; g._refresh_highlights(); g._show_shot()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE: g._skip_activity()
		elif event.keycode == KEY_ESCAPE: g._cancel_order()
		elif event.keycode == KEY_TAB:
			if g.action != "move" and g.action != "free": g._cycle_target(-1 if event.shift_pressed else 1)
			else:
				var id: int = next_squad(g.mission, g.selected_id, -1 if event.shift_pressed else 1)
				if id >= 0: g._select(id)
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if g.action in ["shoot", "strike", "push"]:
				if g.target_id >= 0: g._attack(g.target_id, g.action)
			elif g.action != "move" and g.action != "free":
				if g.target_id >= 0: g._use_ability(g.target_id)
				elif g.preview_tile.x >= 0: g._use_ability(-1, g.preview_tile)
			elif g.action == "move" and g.preview_tile.x >= 0: g._move_selected(g.preview_tile)
			else: g._request_end_turn()
		elif event.keycode == KEY_Q:
			if g.action in ["shoot", "strike", "push"]: g._cycle_target(-1)
			else: g._rotate_camera(-PI / 2.0)
		elif event.keycode == KEY_E:
			if g.action in ["shoot", "strike", "push"]: g._cycle_target(1)
			else: g._rotate_camera(PI / 2.0)
		elif event.keycode == KEY_C: g._recenter()
		elif event.keycode == KEY_R: g.get_tree().reload_current_scene()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_7:
			g._choose_action(["move", "shoot", "strike", "push", "interact" if g.mission.modern else "free", "overwatch", "hunker"][event.keycode - KEY_1])
		elif event.keycode >= KEY_F1 and event.keycode <= KEY_F12:
			var extra: Array = []
			var unit: Dictionary = g.mission.unit_by_id(g.selected_id)
			var shared: Array = ["revive"] if str(unit.get("class_name", "")) == "Medic" else ["medpac", "revive"]
			for id in shared + unit.get("kit", []):
				if id not in ["move", "shoot", "strike", "push", "free", "overwatch", "hunker"] and id not in extra: extra.append(id)
			var index: int = event.keycode - KEY_F1
			if index < extra.size(): g._choose_action(str(extra[index]))
