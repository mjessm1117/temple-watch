extends RefCounted

const Mission = preload("res://scripts/mission.gd")
const Ability = preload("res://scripts/abilities_engine.gd")
const Shot = preload("res://scripts/shot.gd")

static func arena(kind: String = "consular") -> RefCounted:
	var m = Mission.new(5)
	m.spec.width = 12; m.spec.height = 12
	m.board.clear()
	for y in range(12): m.board.append("............")
	m.units.clear()
	m.next_id = 0
	m._spawn(kind, 2, 2, -1)
	m._spawn("soldier", 2, 3, -1)
	m._spawn("trooper", 3, 2, -1)
	m.units[2].awake = true
	m.units[2].droid = true
	m.units[0].focus_left = 9
	m.units[0].focus = 9
	return m

static func run_checks(runner: SceneTree, assertion: Callable) -> void:
	var kinds := ["guardian", "consular", "soldier", "scout", "medic"]
	var total := 0
	for kind in kinds:
		var catalog: RefCounted = arena(kind)
		var kit: Array = catalog.units[0].kit
		assertion.call(kit.size() >= 5, "%s has an ability kit" % kind)
		for id_value in kit:
			var id := str(id_value)
			if id in ["shoot", "strike", "push", "overwatch", "hunker"]: continue
			var m: RefCounted = arena(kind)
			var u: Dictionary = m.units[0]
			var ally: Dictionary = m.units[1]
			var enemy: Dictionary = m.units[2]
			ally.hp = int(ally.max_hp) - 4
			if id in ["forceRevive", "reviveStim"]: ally.hp = 0; ally.status = "down"; ally.wounded = true
			if id == "meditate": u.focus_left = 0
			if id == "rally": ally.stunned = true
			if id == "hack": m.set_tile(Vector2i(4, 2), "k")
			if id == "scan": m.set_tile(Vector2i(3, 3), "q")
			if id == "collapse": m.set_tile(Vector2i(4, 2), "#")
			if id == "subdue": enemy.hp = 1
			if id == "sweep": enemy.x = 3; enemy.y = 2
			var def: Dictionary = m.abilities[id]
			if str(def.get("target", "")) == "enemy_droid": enemy.droid = true
			if id == "mindTrick": enemy.droid = false
			if def.has("chance"): def.chance = 100
			if str(def.get("effect", "")) == "attack": def.chance = 100
			var target_id := -1
			if str(def.get("target", "")).begins_with("ally"): target_id = int(ally.id)
			if str(def.get("target", "")).begins_with("enemy"): target_id = int(enemy.id)
			var tile := Vector2i(4, 2) if id in ["hack", "collapse"] else Vector2i(4, 4) if id == "leap" else Vector2i(3, 3)
			var ap_before := int(u.ap)
			var focus_before := int(u.focus_left)
			var charge := str(def.get("charges", ""))
			var charges_before := int(u.get(charge, 0)) if charge != "" else 0
			var used: bool = m.use_ability(int(u.id), id, target_id, tile)
			assertion.call(used, "%s resolves %s" % [kind, id])
			if used:
				assertion.call(int(u.ap) == ap_before - Ability.cost(def, {"ap": ap_before}) + (int(def.get("amount", 0)) if id == "runGun" else 0), "%s spends AP" % id)
				if id != "meditate": assertion.call(int(u.focus_left) == focus_before - int(def.get("focus", 0)), "%s spends Focus" % id)
				if charge != "": assertion.call(int(u.get(charge, 0)) == charges_before - 1, "%s spends charge" % id)
				if id == "leap": assertion.call(Shot.pos(u) == tile, "Force Leap changes position")
				if id == "collapse": assertion.call(m.tile(tile) == "r", "Collapse removes a wall")
				if id == "scan": assertion.call(m.tile(tile) == "Q" and m.clues == 1 and bool(u.get("data", false)), "Scan Clue records data")
				if id == "hackDroid": assertion.call(bool(enemy.get("stunned", false)), "Hack Droid stuns a droid")
				if id == "subdue": assertion.call(str(enemy.get("status", "")) == "captured", "Subdue captures weakened target")
				if id == "choke": assertion.call(int(u.get("darkness", 0)) == 2, "Choke costs Darkness")
				if id == "mark": assertion.call(bool(enemy.get("marked", false)), "Mark applies")
				if str(def.get("effect", "")) == "attack": assertion.call(int(enemy.hp) < int(enemy.max_hp), "%s deals damage" % id)
				if id == "suppress": assertion.call(bool(enemy.get("suppressed", false)) and int(enemy.get("debuff_aim", 0)) == -30, "Suppress pins and reduces aim")
				if id == "barrier": assertion.call(int(ally.get("buff_defense", 0)) == 40, "Force Barrier grants full cover defense")
				if id == "smoke": assertion.call(int(ally.get("buff_defense", 0)) == 20, "Smoke protects nearby ally")
				if id == "battleMed": assertion.call(int(u.get("buff_aim", 0)) == 10 and int(enemy.get("debuff_aim", 0)) == -10, "Battle Meditation shifts squad and enemy aim")
				if id == "runGun": assertion.call(int(u.ap) == ap_before + 1, "Run & Gun grants a free action")
				if id == "stun": assertion.call(bool(enemy.get("stunned", false)), "Stun applies")
				if id == "shieldDrone": assertion.call(int(ally.get("shield", 0)) == 4, "Shield Drone absorbs four")
				if id in ["forceRevive", "reviveStim"]: assertion.call(int(ally.hp) > 0 and bool(ally.wounded), "%s revives Wounded" % id)
			total += 1
	var m: RefCounted = arena("soldier")
	var actor: Dictionary = m.units[0]
	var injured: Dictionary = m.units[1]
	injured.hp = int(injured.max_hp) - 2
	assertion.call(m.use_ability(int(actor.id), "medpac", int(injured.id)), "medpac heals ally")
	assertion.call(int(injured.hp) == int(injured.max_hp), "healing caps at max HP")
	actor.ap = 3; injured.hp -= 3
	assertion.call(m.use_ability(int(actor.id), "medpac", int(injured.id)), "second medpac heals")
	assertion.call(int(actor.medpacs) == 0 and m.ability_reason(int(actor.id), "medpac") == "No charges", "medpac charges run out")
	var down: RefCounted = arena("soldier")
	var patient: Dictionary = down.units[1]
	down.apply_damage(patient, 99)
	assertion.call(str(patient.status) == "down" and bool(patient.wounded) and down.result == "", "one downed soldier remains revivable")
	assertion.call(not down.move(int(patient.id), Vector2i(4, 4)), "downed soldier cannot act")
	assertion.call(down.use_ability(int(down.units[0].id), "revive", int(patient.id)), "adjacent ally revives")
	assertion.call(int(patient.hp) == 2 and int(patient.ap) == 0 and bool(patient.wounded), "revived soldier returns at low HP and is Wounded")
	down.apply_damage(down.units[0], 99)
	assertion.call(down.result == "", "mission continues while revived ally stands")
	down.apply_damage(patient, 99)
	assertion.call(down.result == "loss", "mission loses when entire squad is down")
	var force: RefCounted = arena("consular")
	force.units[1].hp -= 4
	assertion.call(force.use_ability(int(force.units[0].id), "forceHeal", int(force.units[1].id)), "Force Heal works")
	force.units[0].ap = 3; force.units[0].focus_left = 9; force.units[1].hp -= 3
	assertion.call(force.ability_reason(int(force.units[0].id), "forceHeal").begins_with("Cooldown"), "Force Heal cooldown shown")
	var distant: RefCounted = arena("consular")
	distant.units[1].x = 5; distant.units[1].y = 2
	distant.units[1].hp = 0; distant.units[1].status = "down"; distant.units[1].wounded = true
	assertion.call(distant.ability_reason(int(distant.units[0].id), "medpac") == "No valid target" and distant.use_ability(int(distant.units[0].id), "forceHeal", int(distant.units[1].id)), "Force Heal revives from range three where medpac cannot")
	assertion.call(int(distant.units[1].hp) == 2 and bool(distant.units[1].wounded), "ranged revive restores low HP and retains Wounded")
	var resistance: RefCounted = arena("consular")
	assertion.call(resistance.ability_reason(int(resistance.units[0].id), "mindTrick") == "No valid target", "Mind Trick excludes droids")
	var defense: RefCounted = arena("guardian")
	var normal: int = int(Shot.calculate(defense, defense.units[2], defense.units[1]).hit)
	defense.units[0].x = 8; defense.units[0].y = 8
	var without: int = int(Shot.calculate(defense, defense.units[2], defense.units[1]).hit)
	assertion.call(without - normal == 15, "Defensive Line protects adjacent allies")
	var scout: RefCounted = arena("scout")
	scout.units[2].hp = 1
	scout.abilities.deadeye.chance = 100
	assertion.call(scout.use_ability(int(scout.units[0].id), "deadeye", int(scout.units[2].id)) and bool(scout.units[0].get("concealed", false)), "Ghost reconceals Scout after a kill")
	var sight: RefCounted = arena("scout")
	sight.units[0].x = 2; sight.units[0].y = 4
	sight.units[1].x = 2; sight.units[1].y = 2
	sight.units[2].x = 6; sight.units[2].y = 2
	sight.set_tile(Vector2i(4, 2), "#")
	assertion.call(not Shot.los(sight, Shot.pos(sight.units[1]), Shot.pos(sight.units[2])) and Shot.calculate(sight, sight.units[1], sight.units[2]).los, "Spotter shares line of sight")
	var reflection: RefCounted = arena("guardian")
	reflection.units[0].guard_deflect = 100
	reflection.use_ability(int(reflection.units[0].id), "guard")
	var guardian_hp := int(reflection.units[0].hp)
	for seed_value in range(1, 8):
		reflection.rng.seed = seed_value
		reflection._apply_attack(reflection.units[2], reflection.units[0], {"hit": 100, "crit": 0}, "shoot")
	assertion.call(int(reflection.units[0].hp) == guardian_hp and int(reflection.units[2].hp) < int(reflection.units[2].max_hp), "Guard deflects and Reflect Mastery returns fire")
	var pierce: RefCounted = arena("guardian")
	pierce.units[2].x = 4; pierce.units[2].y = 2
	pierce._spawn("trooper", 6, 2, -1)
	pierce.units[3].awake = true
	pierce.abilities.saberThrow.chance = 100
	pierce.use_ability(int(pierce.units[0].id), "saberThrow", int(pierce.units[2].id))
	assertion.call(int(pierce.units[3].hp) < int(pierce.units[3].max_hp), "Saber Throw pierces a second aligned foe")
	print("skills: %d class abilities exercised, medpacs, revive, wound and total squad loss" % total)
