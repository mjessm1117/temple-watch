extends "res://scripts/mission.gd"
## Combat extension stays separate from the missions lane's objective implementation.
const Round = preload("res://scripts/combat_round.gd")
const Concealment = preload("res://scripts/combat_concealment.gd")
const Bonds = preload("res://scripts/combat_bonds.gd")
var combat_initialized := false
var presentation_active := false
var defer_resolution := false
var resolving_reaction := false
var squad_concealed := false
var bond_pairs: Dictionary = {}
var momentum := 0
var squad_uses: Dictionary = {}
var identity: RefCounted
var mercy_events: Array = []
var action_serial := 0

static func adopt(source: RefCounted, campaign_state: Dictionary = {}) -> RefCounted:
	if source.get("combat_initialized") == true: return source
	var extended = load("res://scripts/combat_mission.gd").new()
	for property in source.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			extended.set(property.name, source.get(property.name))
	extended.setup_combat(campaign_state)
	return extended

func setup_combat(campaign_state: Dictionary = {}) -> void:
	if modern:
		abilities.rewardSafe = {"name":"Safe hack", "target":"tile_reward", "effect":"reward_hack", "ap":1, "range":4}
		abilities.rewardRisky = {"name":"Risky hack", "target":"tile_reward", "effect":"reward_hack", "ap":1, "range":4}
		abilities.relayAttack = {"name":"Fire at relay", "target":"tile_relay", "effect":"relay_attack", "ap":2, "range":"weapon", "ammo_cost":1}
	identity = preload("res://scripts/tactical_identity.gd").new(campaign_state)
	squad_concealed = bool(spec.get("concealed", spec.get("concealment", false)))
	for u in units:
		if float(u.range) >= 2.0:
			u.clip = int(u.get("clip", 4)); u.ammo = int(u.get("ammo", u.clip))
		if str(u.side) == "player":
			u.concealed = squad_concealed
			if not "interact" in u.kit: u.kit.append("interact")
			if u.has("ammo") and not "reload" in u.kit: u.kit.append("reload")
			if str(u.class_name) in ["Guardian", "Consular"]:
				for skill in ["pull", "breach"]:
					if skill not in u.kit: u.kit.append(skill)
			if modern:
				u.kit.append_array(["rewardSafe","rewardRisky"])
				if u.has("ammo"): u.kit.append("relayAttack")
			u.grenades = int(u.get("grenades", 1))
			u.med_beacon = 1
		if str(u.side) == "enemy":
			u.aim = int(u.aim) + int(difficulty.get("combat_enemy_aim", 0))
	preload("res://scripts/combat_loadout.gd").setup(self, campaign_state)
	Bonds.setup(self, campaign_state)
	if squad_concealed: Concealment.observe(self)
	combat_initialized = true

func break_concealment(reason: String) -> void:
	super.break_concealment(reason)
	squad_concealed = false

func _spawn(kind: String, x: int, y: int, group: int) -> void:
	super._spawn(kind, x, y, group)
	var u: Dictionary = units.back()
	if float(u.range) >= 2.0: u.clip = int(u.get("clip",4)); u.ammo = int(u.clip)
	if combat_initialized and str(u.side) == "enemy":
		u.aim = int(u.aim) + int(difficulty.get("combat_enemy_aim",0)) + int(spec.get("sith_mods",{}).get("enemyAim",0))
		u.hp = int(u.hp) + int(spec.get("sith_mods",{}).get("enemyHp",0)); u.max_hp = u.hp

func shot(id: int, target_id: int, mode: String = "shoot") -> bool:
	var u := unit_by_id(id)
	if mode == "shoot" and (int(u.get("ammo", 1)) <= 0 or bool(u.get("disarmed", false))): return false
	return super.shot(id, target_id, mode)

func _apply_attack(a: Dictionary, t: Dictionary, info: Dictionary, mode: String) -> void:
	if int(a.hp) <= 0 or int(t.hp) <= 0: return
	if mode == "shoot" and int(a.get("ammo", 1)) <= 0: return
	if defer_resolution:
		action_events.append({"kind":"intent", "actor":int(a.id), "target":int(t.id), "mode":mode, "info":info.duplicate(true), "reaction":resolving_reaction, "from":Shot.pos(a), "to":Shot.pos(t)})
		return
	if mode == "shoot" and a.has("ammo"): a.ammo = int(a.ammo) - 1
	var was_concealed := bool(a.get("concealed", false))
	var ghost_used := bool(a.get("ghost_used", false))
	var armor := int(t.get("armor", 0))
	var before := int(t.hp)
	var old_phase := phase
	# Base resolution emits the full attack result in enemy phase. Capture it in either phase.
	phase = "enemy"
	super._apply_attack(a, t, info, mode)
	phase = old_phase
	if not action_events.is_empty():
		action_events.back().reaction = resolving_reaction
		action_events.back().armor_lost = armor - int(t.get("armor", 0))
	if int(t.hp) < before and mode == "strike" and bool(t.get("counter",{}).get("melee_interrupts_siphon",false)): t.siphon_stopped = turn+1
	if a.get("rival","") == "veyra" and int(t.hp) == before: a.buff_defense = -10; a.buff_until = turn+2
	if int(t.hp) < before and str(a.side) == "player" and str(t.side) == "enemy": momentum = mini(10, momentum + 1 + (1 if int(t.hp) <= 0 else 0))
	if str(a.side) == "player":
		var ghost_triggered := not ghost_used and bool(a.get("ghost_used", false))
		a.concealed = was_concealed
		Concealment.break_squad(self, a)
		if ghost_triggered: a.concealed = true

func resolve_intent(event: Dictionary) -> Dictionary:
	var old_defer := defer_resolution
	defer_resolution = false
	resolving_reaction = bool(event.get("reaction", false))
	var a := unit_by_id(int(event.actor))
	var t := unit_by_id(int(event.target))
	var destination := Shot.pos(t)
	if resolving_reaction: t.x = event.to.x; t.y = event.to.y
	var count := action_events.size()
	if event.mode == "push": push(int(a.id), int(t.id))
	else: _apply_attack(a, t, event.info, str(event.mode))
	if resolving_reaction and int(t.hp) > 0: t.x = destination.x; t.y = destination.y
	resolving_reaction = false
	defer_resolution = old_defer
	return action_events[count] if action_events.size() > count else {}

func push(id: int, target_id: int) -> bool:
	if defer_resolution:
		var a := unit_by_id(id)
		var t := unit_by_id(target_id)
		if a.is_empty() or t.is_empty(): return false
		action_events.append({"kind":"intent", "actor":id, "target":target_id, "mode":"push", "from":Shot.pos(a), "to":Shot.pos(t)})
		return true
	var a := unit_by_id(id)
	var t := unit_by_id(target_id)
	var old := Shot.pos(t) if not t.is_empty() else Vector2i.ZERO
	var hp := int(t.get("hp", 0))
	var success := false
	if str(a.get("class_name", "")) in ["Guardian", "Consular", "Sith Warrior"]: success = super.push(id, target_id)
	else: success = Ability.use(self, id, "push", target_id)
	if not success: return false
	if phase != "enemy": action_events.append({"kind":"push", "actor":id, "target":target_id, "from":Shot.pos(a), "to":old, "destination":Shot.pos(t), "damage":hp-int(t.hp), "killed":int(t.hp)<=0})
	if str(a.side) == "player": Concealment.break_squad(self, a)
	return true

func move(id: int, dest: Vector2i) -> bool:
	var u := unit_by_id(id)
	if u.is_empty() or bool(u.get("rooted", false)): return false
	var reach := paths(u, int(u.mob) * 2)
	if not reach.costs.has(dest): return false
	var old := Shot.pos(u)
	var route: Array[Vector2i] = []
	var cursor := dest
	while cursor != old and reach.prev.has(cursor):
		route.push_front(cursor); cursor = reach.prev[cursor]
	# Base move owns escorts and mission hooks; reactions below inspect the entire route.
	u.combat_route = route
	u.dashing = int(reach.costs[dest]) > int(u.mob)
	var event_start := action_events.size()
	var ok := super.move(id, dest)
	if ok:
		for i in range(event_start, action_events.size()):
			if action_events[i].kind == "move" and int(action_events[i].actor) == id:
				action_events[i].path = route
		if str(u.side) == "enemy" and squad_concealed:
			for p in living("player"): Concealment.detect_path(self, p)
	u.erase("combat_route"); u.erase("dashing")
	return ok

func _wake_groups() -> void:
	if squad_concealed:
		Concealment.observe(self)
		return
	super._wake_groups()

func _reaction_fire(mover: Dictionary) -> void:
	_reactions(mover, "player")

func _enemy_reaction_fire(mover: Dictionary) -> void:
	if bool(mover.get("concealed", false)):
		Concealment.detect_path(self, mover)
		if bool(mover.get("concealed", false)): return
	_reactions(mover, "enemy")

func _reactions(mover: Dictionary, side: String) -> void:
	var end := Shot.pos(mover)
	var route: Array = mover.get("combat_route", [end])
	for q in route:
		mover.x = q.x; mover.y = q.y
		for watcher in living(side):
			if int(mover.hp) <= 0: break
			if str(watcher.side) == "enemy" and not bool(watcher.awake): continue
			var pinned := int(mover.get("suppressed_by", -1)) == int(watcher.id)
			var hold: bool = bool(watcher.get("hold_line", false)) and int(mover.id) not in watcher.get("ow_hit", [])
			if not bool(watcher.overwatch) and not pinned and not hold: continue
			if int(watcher.get("ammo", 1)) <= 0: continue
			var info := Shot.calculate(self, watcher, mover, false, -15)
			if not bool(info.los) or not bool(info.range_ok): continue
			watcher.overwatch = false
			watcher.ow_hit = watcher.get("ow_hit", []) + [int(mover.id)]
			mover.erase("suppressed_by")
			resolving_reaction = true
			_apply_attack(watcher, mover, info, "shoot")
			resolving_reaction = false
		if int(mover.hp) <= 0: return
	mover.x = end.x; mover.y = end.y

func overwatch(id: int) -> bool:
	if int(unit_by_id(id).get("ammo", 1)) <= 0: return false
	return super.overwatch(id)

func end_turn() -> void:
	if phase != "player" or result != "": return
	Round.begin(self)
	var fired: Dictionary = {}
	for e in living("enemy"):
		if result != "": break
		enemy_actor(e, fired)
	Round.finish(self)

func tick_combat_status() -> void:
	for u in units:
		if u.side == "enemy" and int(u.get("buff_until",0)) <= turn: u.erase("buff_aim"); u.erase("buff_defense")
		for status in ["disarmed", "rooted", "tricked"]:
			if int(u.get(status + "_until", 0)) <= turn: u.erase(status)
		u.erase("hold_line"); u.erase("ow_hit")
		if int(u.get("taunt_until", 0)) <= turn: u.erase("taunt")
		if str(u.side) == "player" and "wildBond" in u.get("passives", []): u.focus_left = maxi(int(u.focus_left), 0)

func enemy_actor(e: Dictionary, fired: Dictionary) -> void:
	preload("res://scripts/campaign/battle_sith.gd").before_actor(self,e)
	super.enemy_actor(e,fired)

func apply_damage(target: Dictionary, amount: int, source: Dictionary = {}) -> int:
	var alive := int(target.get("hp",0)) > 0
	var actual := super.apply_damage(target,amount,source)
	if actual > 0 and identity != null:
		identity.voice(self,target,"down" if int(target.hp) <= 0 else "hit")
		if alive and int(target.hp) <= 0 and not source.is_empty():
			identity.kill(self,source); identity.voice(self,source,"kill")
	return actual

func use_ability(id: int, ability_id: String, target_id: int = -1, target_tile: Vector2i = Vector2i(-1,-1)) -> bool:
	var before := {}
	for u in units: before[u.id] = {"hp":u.hp,"status":u.status,"stable":u.get("stable",false),"surrendered":u.get("surrendered",false)}
	var ok := super.use_ability(id,ability_id,target_id,target_tile)
	if not ok: return false
	action_serial += 1
	var actor := unit_by_id(id)
	if not actor.has("rid"): return true
	var mercy := false
	var points := 1
	for u in units:
		var old: Dictionary = before.get(u.id,{})
		if old.is_empty(): continue
		if u.side == "player" and (int(u.hp) > int(old.hp) or (not old.stable and u.get("stable",false))): mercy = true
		if u.side == "enemy" and old.status != "captured" and u.status == "captured":
			mercy = true
			if old.surrendered: points = 2
	if mercy: mercy_events.append({"unit_id":actor.rid,"action_id":"action_%d" % action_serial,"points":points})
	return true

func damage_cover(p: Vector2i, damage: int) -> String:
	var barrel: bool = spec.get("prop_overrides",{}).get(p,"") == "barrel" and tile(p) != "r"
	var after := super.damage_cover(p,damage)
	if barrel and after == "r":
		spec.prop_overrides.erase(p)
		for u in units:
			if int(u.hp) > 0 and maxi(absi(int(u.x)-p.x),absi(int(u.y)-p.y)) <= 1: apply_damage(u,3)
		for y in range(p.y-1,p.y+2):
			for x in range(p.x-1,p.x+2):
				if Vector2i(x,y) != p: damage_cover(Vector2i(x,y),3)
		message("Fuel barrel explodes: 3 damage in a 3×3 area.")
	return after
