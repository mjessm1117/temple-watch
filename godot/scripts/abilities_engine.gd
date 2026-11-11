extends RefCounted
class_name AbilityEngine

const Combat = preload("res://scripts/combat_abilities.gd")
const Bonds = preload("res://scripts/combat_bonds.gd")
const Shot = preload("res://scripts/shot.gd")
const Rules12 = preload("res://scripts/rules12_actions.gd")
const Chains = preload("res://scripts/ability_chains.gd")

static func cost(def: Dictionary, u: Dictionary) -> int:
	return Rules12.cost(def, u)

static func range_of(def: Dictionary, u: Dictionary) -> float:
	var base := float(u.get("range", 0)) if str(def.get("range")) == "weapon" else float(def.get("range", 0))
	return base + (1.0 if int(def.get("focus", 0)) > 0 and Chains.has_tag(u, "ATTUNED") else 0.0)

static func reason(m: RefCounted, u: Dictionary, id: String) -> String:
	if u.is_empty() or not m.abilities.has(id): return "Unavailable"
	if str(u.get("side", "")) != "player" or str(u.get("status", "ok")) == "down" or int(u.get("hp", 0)) <= 0: return "Downed"
	if Chains.has_tag(u, "LIFTED"): return "Lifted"
	if m.result != "" or m.phase != "player": return "Mission inactive"
	if id != "medpac" and id != "revive" and id != "free" and id != "move" and id != "interact" and id not in u.get("kit", []): return "Not in kit"
	var def: Dictionary = m.abilities[id]
	var combat_reason := Combat.reason(m, u, id, def)
	if combat_reason != "": return combat_reason
	if int(u.get("ap", 0)) < cost(def, u) or (int(u.get("ap", 0)) == 0 and cost(def, u) > 0): return "Need %d AP" % maxi(1, cost(def, u))
	if int(u.get("focus_left", 0)) < int(def.get("focus", 0)) and not Chains.has_tag(u, "ATTUNED"): return "Need %d Focus" % int(def.focus)
	var charge := str(def.get("charges", ""))
	if charge != "" and int(u.get(charge, 0)) <= 0: return "No charges"
	var ready: Dictionary = u.get("cooldowns", {})
	if int(ready.get(id, 0)) > m.turn: return "Cooldown %d" % (int(ready[id]) - m.turn)
	if id == "free" and bool(m.prisoner.freed): return "Already free"
	if id == "free" and max(abs(int(u.x) - int(m.prisoner.x)), abs(int(u.y) - int(m.prisoner.y))) > 1: return "Move adjacent"
	if id == "meditate" and int(u.get("focus_left", 0)) >= int(u.get("focus", 0)): return "Focus full"
	if id == "masterAction" and bool(u.get("master_action_used", false)): return "Already used"
	if id == "rally":
		var need := false
		for ally in m.living("player"):
			if Shot.distance(Shot.pos(u), Shot.pos(ally)) <= range_of(def, u) and (bool(ally.get("stunned", false)) or bool(ally.get("disarmed", false))): need = true
		if not need: return "No ally needs Rally"
	if str(def.get("target", "")) in ["ally_injured", "ally_down", "ally_bond", "ally_other", "enemy", "enemy_droid", "enemy_creature", "enemy_subdue"] and targets(m, u, id).is_empty(): return "No valid target"
	if str(def.get("target", "")) in ["tile_console", "tile_scan", "tile_wall", "tile_relay", "tile_reward"] and tiles(m, u, id).is_empty(): return "No target tile"
	return ""

static func targets(m: RefCounted, u: Dictionary, id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if u.is_empty() or not m.abilities.has(id): return out
	var def: Dictionary = m.abilities[id]
	var kind := str(def.get("target", ""))
	var radius := range_of(def, u)
	if kind.begins_with("ally"):
		for t in m.units:
			if str(t.get("side", "")) != "player": continue
			if Shot.distance(Shot.pos(u), Shot.pos(t)) > radius: continue
			if kind == "ally_down" and str(t.get("status", "ok")) != "down": continue
			if kind == "ally_injured" and str(t.get("status", "ok")) != "down" and int(t.hp) >= int(t.max_hp): continue
			if kind in ["ally", "ally_other", "ally_bond"] and int(t.hp) <= 0: continue
			if kind in ["ally_other", "ally_bond"] and (int(t.id) == int(u.id) or int(t.ap) >= Rules12.ACTIONS_PER_TURN): continue
			if kind == "ally_bond":
				if t not in Bonds.partners(m, u): continue
				if bool(m.bond_pairs[u.bondmates[int(t.id)]].get("aid_used", false)): continue
			if id == "stabilize" and bool(t.get("stable", false)): continue
			out.append(t)
	elif kind.begins_with("enemy"):
		for t in m.living("enemy"):
			if Chains.has_tag(u, "TAUNTED") and int(Chains.tags(u).get("TAUNTED", -1)) != int(t.id): continue
			if preload("res://scripts/enemy11_tactics.gd").hidden(m,t): continue
			if not bool(t.get("awake", false)) and not bool(t.get("spotted", false)): continue
			if Shot.distance(Shot.pos(u), Shot.pos(t)) > radius: continue
			if kind == "enemy_creature" and not bool(t.get("horror", false)) and not "creature" in t.get("tags", []): continue
			if id == "backup" and Combat.best_helper(m, u, t).is_empty(): continue
			if id == "bondStrike" and not _bond_can_shoot(m, u, t): continue
			if kind == "enemy_droid" and not bool(t.get("droid", false)): continue
			if id == "mindTrick" and (str(t.get("class_name", "")) == "Sith Warrior" or bool(t.get("droid", false))): continue
			if kind == "enemy_subdue" and bool(t.get("no_capture", false)): continue
			if kind == "enemy_subdue" and int(t.hp) * 2 > int(t.max_hp) and not bool(t.get("stunned", false)): continue
			if not bool(def.get("no_los", false)) and not Shot.los(m, Shot.pos(u), Shot.pos(t)): continue
			out.append(t)
	return out

static func tiles(m: RefCounted, u: Dictionary, id: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not m.abilities.has(id): return out
	var def: Dictionary = m.abilities[id]
	var kind := str(def.get("target", ""))
	if kind == "tile_interact": return Combat.interactables(m, u)
	if kind == "tile_relay":
		if m.modern and m.spec.family == "destroy_relay" and m.objective_state.phase == "primary":
			for p in m.interactables():
				if Shot.distance(Shot.pos(u),p) <= float(u.range) and Shot.los(m,Shot.pos(u),p): out.append(p)
		return out
	if kind == "tile_reward":
		for y in range(int(u.y)-4,int(u.y)+5):
			for x in range(int(u.x)-4,int(u.x)+5):
				var p := Vector2i(x,y)
				if not preload("res://scripts/mission_hack.gd").options(m,u,p).is_empty(): out.append(p)
		return out
	if kind not in ["tile", "tile_console", "tile_wall", "tile_scan", "tile_area"]: return out
	for y in range(int(m.spec.height)):
		for x in range(int(m.spec.width)):
			var p := Vector2i(x, y)
			if Shot.distance(Shot.pos(u), p) > range_of(def, u): continue
			if kind == "tile_console" and m.tile(p) not in ["k", "D"]: continue
			if kind == "tile_scan" and m.tile(p) != "q": continue
			if kind == "tile_wall" and not m._destructible(p): continue
			if kind == "tile_area" and m.tile(p) == "#": continue
			if kind == "tile" and (not m.passable(p) or m.occupied(p)): continue
			if id == "leap" and p == Shot.pos(u): continue
			if id not in ["leap", "hack", "collapse", "scan"] and not Shot.los(m, Shot.pos(u), p): continue
			out.append(p)
	return out

static func use(m: RefCounted, actor_id: int, id: String, target_id: int = -1, tile: Vector2i = Vector2i(-1, -1)) -> bool:
	var u: Dictionary = m.unit_by_id(actor_id)
	if reason(m, u, id) != "": return false
	var def: Dictionary = m.abilities[id].duplicate(true)
	if u.get("legacy_power", {}).has(id):
		var factor := float(u.legacy_power[id])
		for key in ["heal", "revive", "shield", "defense", "aim", "enemy_aim", "amount", "damage_mod", "next_strike_aim", "cover_damage", "collision_damage"]:
			if def.has(key): def[key] = roundi(float(def[key]) * factor)
		if def.get("damage") is Array:
			def.damage = [maxi(1, roundi(float(def.damage[0]) * factor)), maxi(1, roundi(float(def.damage[1]) * factor))]
	if id in ["rewardSafe","rewardRisky"]: return bool(m.hack(u,tile,"safe" if id == "rewardSafe" else "risky").get("ok",false))
	var target_kind := str(def.get("target", ""))
	var t: Dictionary = {}
	if target_kind.begins_with("ally") or target_kind.begins_with("enemy"):
		for option in targets(m, u, id):
			if int(option.id) == target_id: t = option; break
		if t.is_empty(): return false
	if target_kind.begins_with("tile") and tile not in tiles(m, u, id): return false
	if str(def.effect) == "interact": return Combat.interact(m, u, tile)
	var was_concealed := bool(u.get("concealed", false))
	var ghost_used := bool(u.get("ghost_used", false))
	var spend := cost(def, u)
	var attuned := int(def.get("focus", 0)) > 0 and Chains.has_tag(u, "ATTUNED")
	if attuned: Chains.consume(m, u, "ATTUNED")
	u.ap = int(u.ap) - spend
	u.focus_left = int(u.get("focus_left", 0)) - (0 if attuned else int(def.get("focus", 0)))
	var charge := str(def.get("charges", ""))
	if charge != "": u[charge] = int(u.get(charge, 0)) - 1
	if int(def.get("cooldown", 0)) > 0:
		var cds: Dictionary = u.get("cooldowns", {})
		cds[id] = m.turn + int(def.cooldown) + 1
		u.cooldowns = cds
	if int(def.get("ammo_cost", 0)) > 0 and u.has("ammo"): u.ammo = int(u.ammo) - int(def.ammo_cost)
	var effect := str(def.get("effect", ""))
	u.active_ability = id
	if effect in Combat.EFFECTS: Combat.effect(m, u, t, tile, id, def)
	match effect:
		"heal": _heal(m, u, t, def)
		"attack": _attack(m, u, t, def, id)
		"status": _status(m, u, t, def)
		"buff": _buff(m, u, t, def)
		"area_buff":
			for ally in m.living("player"):
				if max(abs(int(ally.x) - tile.x), abs(int(ally.y) - tile.y)) <= int(def.get("radius", 1)): _buff(m, u, ally, def)
		"aura":
			for ally in m.living("player"):
				if Shot.distance(Shot.pos(u), Shot.pos(ally)) <= range_of(def, u):
					if bool(def.get("clear_status", false)): ally.erase("stunned"); ally.erase("disarmed")
					else: _buff(m, u, ally, def); ally.battle_med_source = int(u.id)
			if id == "battleMed": u.battle_med_source = int(u.id)
			for enemy in m.living("enemy"):
				if Shot.distance(Shot.pos(u), Shot.pos(enemy)) <= range_of(def, u): enemy.debuff_aim = int(def.get("enemy_aim", 0)); enemy.debuff_until = m.turn + 1
		"focus": u.focus_left = mini(int(u.focus), int(u.focus_left) + int(def.get("amount", 0)) + (1 if "wildBond" in u.get("passives", []) else 0))
		"ap": u.ap = mini(Rules12.ACTIONS_PER_TURN, int(u.ap) + int(def.get("amount", 0)))
		"master_action": u.ap = int(u.ap) + 1; u.master_action_used = true
		"leap":
			m.action_events.append({"kind":"leap", "actor":actor_id, "from":Shot.pos(u), "to":tile})
			u.x = tile.x; u.y = tile.y; u.leap_aim = int(def.get("next_strike_aim", 0)); m._wake_groups(); m._enemy_reaction_fire(u)
		"area_attack":
			for enemy in m.living("enemy"):
				if max(abs(int(enemy.x) - int(u.x)), abs(int(enemy.y) - int(u.y))) <= 1: _attack(m, u, enemy, def, id)
		"hack":
			for y in range(int(m.spec.height)):
				for x in range(int(m.spec.width)):
					var p := Vector2i(x, y)
					if m.tile(p) in ["D", "k"]: m.set_tile(p, "_"); m.terrain_revision += 1
		"scan": m.set_tile(tile, "Q"); m.terrain_revision += 1; m.clues += 1; u.data = true
		"collapse":
			m.set_tile(tile, "r"); m.terrain_revision += 1
			for enemy in m.living("enemy"):
				if max(abs(int(enemy.x) - tile.x), abs(int(enemy.y) - tile.y)) <= 1: m.apply_damage(enemy, int(def.damage[0]), u)
		"capture":
			var capture_chance := int(def.get("stunned_chance", 85)) if bool(t.get("stunned", false)) else int(def.get("chance", 60))
			if m.rng.randi_range(1, 100) <= capture_chance:
				u.captures = int(u.get("captures", 0)) + 1
				t.hp = 0; t.status = "captured"; m.message("%s captures %s." % [u.name, t.name])
		"guard": u.guard = true; u.guard_until = m.turn + 1; u.guard_power = float(u.get("legacy_power", {}).get(id, 1.0))
		"overwatch": u.overwatch = true
		"hunker": u.hunkered = true
		"displace": _displace(m, u, t, def)
		_: pass
	if def.has("chain") or def.has("effects"): Chains.resolve(m, u, t, tile, def)
	if m.has_method("setup_combat") and (effect in ["attack", "area_attack", "status", "displace", "blast", "wave", "breach", "collapse", "backup", "bond_strike"]):
		var ghost_triggered := not ghost_used and bool(u.get("ghost_used", false))
		u.concealed = was_concealed
		preload("res://scripts/combat_concealment.gd").break_squad(m, u)
		if ghost_triggered: u.concealed = true
	if int(def.get("darkness", 0)) > 0: u.darkness = int(u.get("darkness", 0)) + int(def.darkness)
	m.message("%s uses %s." % [u.name, def.name])
	m.ability_uses[id] = int(m.ability_uses.get(id, 0)) + 1
	if bool(def.get("ends_turn", false)): u.ap = 0
	u.erase("active_ability")
	m._check_lose()
	return true

static func _heal(m: RefCounted, u: Dictionary, t: Dictionary, def: Dictionary) -> void:
	var before := int(t.hp)
	if str(t.get("status", "ok")) == "down":
		if t.has("rid") and u.has("rid"): m.saved_by[str(t.rid)] = str(u.rid)
		t.status = "ok"; t.hp = mini(int(t.max_hp), int(def.get("revive", 2))); t.ap = 0; t.wounded = true
	else: t.hp = mini(int(t.max_hp), int(t.hp) + int(def.get("heal", 0)))
	m.action_events.append({"kind": "heal", "actor": int(u.id), "target": int(t.id), "amount": int(t.hp) - before, "revived": before == 0})

static func _attack(m: RefCounted, u: Dictionary, t: Dictionary, def: Dictionary, id: String) -> void:
	var melee := bool(def.get("melee", false))
	var probe: Dictionary = u.duplicate()
	if def.has("range") and str(def.range) != "weapon": probe.range = def.range
	var info: Dictionary = Shot.calculate(m, probe, t, melee, int(def.get("aim_mod", 0)) + (int(u.get("leap_aim", 0)) if melee else 0))
	var chance := int(def.get("chance", info.hit))
	if bool(def.get("ignore_cover", false)) and not def.has("chance"): chance = mini(100, chance + int(info.cover))
	var was_alive := int(t.hp) > 0
	var damage_range: Array = def.get("damage", u.damage) if typeof(def.get("damage")) == TYPE_ARRAY else u.damage
	for i in range(int(def.get("shots", 1))):
		if int(t.hp) <= 0: break
		if m.rng.randi_range(1, 100) > chance:
			if bool(def.get("follow_hit", false)): break
			continue
		var damage: int = m.rng.randi_range(int(damage_range[0]), int(damage_range[1])) + int(def.get("damage_mod", 0))
		if int(def.get("crit_mod", 0)) > 0 and m.rng.randi_range(1, 100) <= int(info.crit) + int(def.crit_mod): damage += 2
		var dealt: int = m.apply_damage(t, maxi(1, damage - int(t.get("armor", 0))), u)
		if dealt > 0 and melee and bool(t.get("counter",{}).get("melee_interrupts_siphon",false)): t.siphon_stopped = m.turn+1
	if bool(def.get("pierce", false)):
		var direction := Shot.pos(t) - Shot.pos(u)
		for other in m.living("enemy"):
			if int(other.id) == int(t.id): continue
			var delta := Shot.pos(other) - Shot.pos(t)
			if delta.x * direction.y == delta.y * direction.x and delta.x * direction.x + delta.y * direction.y > 0 and Shot.distance(Shot.pos(u), Shot.pos(other)) <= range_of(def, u):
				if m.rng.randi_range(1, 100) <= chance: m.apply_damage(other, m.rng.randi_range(int(damage_range[0]), int(damage_range[1])), u)
				break
	if melee: u.leap_aim = 0
	if was_alive and int(t.hp) <= 0 and "ghost" in u.get("passives", []) and not bool(u.get("ghost_used", false)):
		u.concealed = true; u.ghost_used = true

static func _status(m: RefCounted, u: Dictionary, t: Dictionary, def: Dictionary) -> void:
	if m.rng.randi_range(1, 100) > int(def.get("chance", 100)): return
	var status := str(def.status)
	t[status] = true
	t[status + "_until"] = m.turn + 1
	if status == "stunned": t.ap = 0; t.overwatch = false
	if status == "suppressed": t.debuff_aim = int(def.get("aim", -30)); t.debuff_until = m.turn + 1; t.suppressed_by = int(u.id)
	if status == "marked": t.marked_by = int(u.id); t.marked_aim = int(def.get("ally_aim", 15))

static func _buff(m: RefCounted, _u: Dictionary, t: Dictionary, def: Dictionary) -> void:
	if def.has("defense"): t.buff_defense = int(def.defense); t.buff_until = m.turn + int(def.get("duration", 1))
	if def.has("aim"): t.buff_aim = int(def.aim); t.buff_until = m.turn + int(def.get("duration", 1))
	if def.has("shield"): t.shield = int(t.get("shield", 0)) + int(def.shield)

static func _displace(m: RefCounted, u: Dictionary, t: Dictionary, def: Dictionary) -> void:
	if m.rng.randi_range(1, 100) > int(def.get("chance", 100)): return
	var step := Vector2i(signi(int(t.x) - int(u.x)), signi(int(t.y) - int(u.y)))
	if bool(def.get("pull", false)): step = -step
	for i in range(int(def.get("distance", 2))):
		if bool(def.get("pull", false)) and Shot.distance(Shot.pos(u), Shot.pos(t)) <= 1.5: break
		var q: Vector2i = Shot.pos(t) + step
		if not m.passable(q) or m.occupied(q, int(t.id)):
			m.apply_damage(t, int(def.get("collision_damage", 3)), u)
			if m.in_bounds(q): m.damage_cover(q, 4, {"kind":"force_displace", "actor":int(u.id)})
			break
		t.x = q.x; t.y = q.y

static func _bond_can_shoot(m: RefCounted, u: Dictionary, t: Dictionary) -> bool:
	for p in Bonds.partners(m, u):
		var bond: Dictionary = m.bond_pairs[u.bondmates[int(p.id)]]
		if int(bond.lvl) < 4 or bool(bond.get("strike_used", false)) or int(p.get("ammo", 1)) <= 0: continue
		var info := Shot.calculate(m, p, t)
		if bool(info.los) and bool(info.range_ok): return true
	return false
