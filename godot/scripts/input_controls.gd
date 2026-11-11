extends RefCounted

const Shot = preload("res://scripts/shot.gd")
const Ability = preload("res://scripts/abilities_engine.gd")
const Phone = preload("res://scripts/phone_layout.gd")

const DEFAULT_BINDINGS := {"move": [KEY_1], "shoot": [KEY_2], "strike": [KEY_3], "push": [KEY_4], "interact": [KEY_5], "free": [KEY_5], "overwatch": [KEY_6, KEY_Y], "hunker": [KEY_7], "ability8": [KEY_8], "ability9": [KEY_9], "ability10": [KEY_0], "reload": [KEY_R], "end_turn": [KEY_END, KEY_BACKSPACE], "confirm": [KEY_ENTER, KEY_KP_ENTER], "cancel": [KEY_ESCAPE], "next_unit": [KEY_TAB], "rotate_left": [KEY_Q], "rotate_right": [KEY_E], "recenter": [KEY_C]}

static func bindings24() -> Dictionary:
	var result: Dictionary = DEFAULT_BINDINGS.duplicate(true)
	var cfg := ConfigFile.new()
	if cfg.load("user://controls24.cfg") != OK: return result
	var overrides: Variant = cfg.get_value("controls", "keymap", {})
	if not overrides is Dictionary: return result
	for action in overrides:
		if not result.has(action): continue
		var keys: Array = overrides[action] if overrides[action] is Array else [overrides[action]]
		var parsed: Array[int] = []
		for key in keys:
			var code: int = int(key) if key is int else OS.find_keycode_from_string(str(key))
			if code > 0 and code not in parsed: parsed.append(code)
		if not parsed.is_empty(): result[action] = parsed
	return result

static func confirm_move24(touch: bool) -> bool:
	var cfg := ConfigFile.new()
	if cfg.load("user://controls24.cfg") != OK: return touch
	return bool(cfg.get_value("controls", "confirm_move", touch))

static func magnet_tile24(game, point: Vector2, actor: Dictionary, route: Dictionary = {}) -> Vector2i:
	if actor.is_empty() or int(actor.get("ap", 0)) <= 0: return Vector2i(-1, -1)
	if route.is_empty(): route = game.mission.paths(actor, int(actor.mob) * 2)
	var best := Vector2i(-1, -1)
	var distance := 28.0
	for tile in route.costs:
		if tile == Shot.pos(actor) or int(route.costs[tile]) > int(actor.mob) * int(actor.ap): continue
		var center: Vector2 = game.camera.unproject_position(Vector3(tile.x, Shot.elevation(game.mission, tile) * 0.7 + 0.15, tile.y))
		var d := point.distance_to(center)
		if d < distance: distance = d; best = tile
	return best

static func valid_move_tile24(route: Dictionary, actor: Dictionary, tile: Vector2i) -> bool:
	if actor.is_empty() or tile == Shot.pos(actor) or not route.get("costs", {}).has(tile): return false
	var cost: int = int(route.costs[tile])
	return cost <= int(actor.mob) * int(actor.ap)

static func extra_abilities24(unit: Dictionary) -> Array[String]:
	var extra: Array[String] = []
	var shared: Array = ["revive"] if str(unit.get("class_name", "")) == "Medic" else ["medpac", "revive"]
	for id in shared + unit.get("kit", []):
		if id not in ["move", "shoot", "strike", "push", "free", "interact", "overwatch", "hunker"] and id not in extra: extra.append(str(id))
	return extra

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
	var seen_by: Array[String] = []
	var probe: Dictionary = unit.duplicate()
	probe.x = dest.x; probe.y = dest.y
	for enemy in m.living("enemy"):
		if not bool(enemy.get("spotted", false)) and not bool(enemy.get("detected", false)): continue
		var shot_info: Dictionary = Shot.calculate(m, enemy, probe)
		if bool(shot_info.los) and bool(shot_info.range_ok):
			seen_by.append(str(enemy.name))
			if bool(shot_info.flanked): flanks.append(str(enemy.name))
	return {"ap": ap_cost, "tiles": cost, "prev": route.prev, "shields": shields, "flanks": flanks, "seen_by": seen_by}

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

static func selection_at24(game, point: Vector2) -> Dictionary:
	var players: Array[Dictionary] = game.mission.living("player")
	var near := near_unit(game, point, players)
	if not near.is_empty(): return near
	var tile: Vector2i = game._screen_tile(point)
	for unit in players:
		if Shot.pos(unit) == tile: return unit
	return {}

var g
var queued_selection24 := -1
var busy_connected24 := false
var right_start24 := Vector2.ZERO
var right_moved24 := false

func _busy24() -> bool:
	if not g.has_method("is_input_busy24"): return false
	return bool(g.is_input_busy24())

func connect_busy24() -> void:
	if not busy_connected24 and g.has_signal("input_busy_changed24"):
		g.input_busy_changed24.connect(_busy_changed24)
		busy_connected24 = true

func _busy_changed24(busy: bool) -> void:
	if busy or queued_selection24 < 0: return
	var selected := queued_selection24
	queued_selection24 = -1
	var unit: Dictionary = g.mission.unit_by_id(selected)
	if not unit.is_empty() and int(unit.get("hp", 0)) > 0 and str(unit.get("side", "")) == "player": g._select(selected)

func _queue_selection24(id: int) -> void:
	if id >= 0: queued_selection24 = id

func handle_event(event: InputEvent) -> void:
	connect_busy24()
	if _busy24():
		if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
			_queue_selection24(next_squad(g.mission, g.selected_id, -1 if event.shift_pressed else 1))
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var unit := selection_at24(g, event.position)
			if not unit.is_empty(): _queue_selection24(int(unit.id))
		return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
			g.camera_tween = g.create_tween()
			g.camera_tween.tween_property(g, "zoom", g.zoom + (-2.5 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 2.5), 0.25).set_trans(Tween.TRANS_SINE)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			g.drag_button = MOUSE_BUTTON_MIDDLE if event.pressed else 0
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				right_start24 = event.position; right_moved24 = false
				g.drag_button = MOUSE_BUTTON_RIGHT
				return
			g.drag_button = 0
			if right_moved24: return
			if g.action == "move":
				var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
				var route: Dictionary = g.mission.paths(actor, int(actor.mob) * 2) if not actor.is_empty() else {}
				var tile := magnet_tile24(g, event.position, actor, route)
				if tile.x < 0: tile = g._screen_tile(event.position)
				if valid_move_tile24(route, actor, tile):
					if confirm_move24(false) and g.preview_tile != tile:
						g.preview_tile = tile; g._refresh_highlights()
					else: g._move_selected(tile)
					return
			if g.action != "move" or g.preview_tile.x >= 0: g._cancel_order()
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
				var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
				var route: Dictionary = g.mission.paths(actor, int(actor.mob) * 2) if not actor.is_empty() else {}
				var snapped := magnet_tile24(g, event.position, actor, route)
				if snapped.x >= 0: p = snapped
				if not valid_move_tile24(route, actor, p): return
				if g.preview_tile == p or (Phone.touch_device() and not confirm_move24(true)): g._move_selected(p)
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
			if event.position.distance_to(right_start24) > 6.0: right_moved24 = true
			if not right_moved24: return
			if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
			var right: Vector3 = g.camera.global_basis.x
			var forward: Vector3 = -g.camera.global_basis.z; forward.y = 0; forward = forward.normalized()
			g.pivot += (-right * event.relative.x + forward * event.relative.y) * g.zoom * 0.0015
			g._update_camera()
		else:
			var p: Vector2i = g._screen_tile(event.position)
			if p != g.hovered: g.hovered = p; g._refresh_highlights(); g._show_shot()
	elif event is InputEventKey and event.pressed and not event.echo:
		var binding := bindings24()
		var key: int = event.keycode
		if event.keycode == KEY_SPACE: g._skip_activity()
		elif key in binding.cancel: g._cancel_order()
		elif key in binding.next_unit:
			if g.action != "move" and g.action != "free": g._cycle_target(-1 if event.shift_pressed else 1)
			else:
				var id: int = next_squad(g.mission, g.selected_id, -1 if event.shift_pressed else 1)
				if id >= 0: g._select(id)
		elif key in binding.confirm:
			if g.action in ["shoot", "strike", "push"]:
				if g.target_id >= 0: g._attack(g.target_id, g.action)
			elif g.action != "move" and g.action != "free":
				if g.target_id >= 0: g._use_ability(g.target_id)
				elif g.preview_tile.x >= 0: g._use_ability(-1, g.preview_tile)
			elif g.action == "move" and g.preview_tile.x >= 0: g._move_selected(g.preview_tile)
			else: g._request_end_turn()
		elif key in binding.rotate_left:
			if g.action in ["shoot", "strike", "push"]: g._cycle_target(-1)
			else: g._rotate_camera(-PI / 2.0)
		elif key in binding.rotate_right:
			if g.action in ["shoot", "strike", "push"]: g._cycle_target(1)
			else: g._rotate_camera(PI / 2.0)
		elif key in binding.recenter: g._recenter()
		elif key in binding.end_turn: g._request_end_turn()
		elif key in binding.reload:
			var unit: Dictionary = g.mission.unit_by_id(g.selected_id)
			if "reload" in unit.get("kit", []): g._choose_action("reload")
		else:
			var actions := ["move", "shoot", "strike", "push", "interact" if g.mission.modern else "free", "overwatch", "hunker"]
			var handled := false
			var extra := extra_abilities24(g.mission.unit_by_id(g.selected_id))
			for i in range(actions.size()):
				var name: String = actions[i]
				if key in binding.get(name, []): g._choose_action(actions[i]); handled = true; break
			if not handled:
				for i in range(mini(3, extra.size())):
					if key in binding["ability%d" % (i + 8)]: g._choose_action(extra[i]); handled = true; break
			if not handled and key >= KEY_F1 and key <= KEY_F12:
				var index := key - KEY_F1
				if index < extra.size(): g._choose_action(extra[index])
