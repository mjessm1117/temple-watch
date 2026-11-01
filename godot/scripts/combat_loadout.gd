extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")

static func setup(m: RefCounted, state: Dictionary) -> void:
	for u in m.living("player"):
		var active: Array = []
		var passive: Array = u.get("passives", []).duplicate()
		match str(u.class_name):
			"Sentinel": active = ["strike","guard","meditate","shadowStep","disarm","pull","breach"]; passive += ["sense","executioner"] if "sense" not in passive else []
			"Wayseeker": active = ["strike","guard","meditate","beastCalm","pull","push","breach"]; passive += ["pathfinder","wildBond"] if "pathfinder" not in passive else []
			"Guardian": active = ["flurry", "mightyBlow", "precisionStrike"] if not u.has("rid") else []
			"Consular": active = ["massHeal", "forceWave", "stasisField", "disarm"] if not u.has("rid") else []
			"Medic": active = ["medBeacon"] if not u.has("rid") else []
			"Heavy": active = ["grenade","ionNade","barrage","holdLine"]; passive += ["shredder"]
			"Scout": active = ["snipe","hunker"]
			"Shieldbearer": active = ["shieldWall","taunt","hunker"]
			"Gunslinger": active = ["fanFire","runGun","hunker"]
		if int(u.get("focus", 0)) == 0:
			active += ["grenade", "backup", "coverFire", "handoff", "moSurge", "moRally", "moStrike"]
		for r in state.get("roster", []):
			if str(r.get("id", "")) != str(u.get("rid", "-")): continue
			for pick in r.get("picks", []):
				if m.abilities.has(pick): active.append(pick)
		for id in active:
			if not m.abilities.has(id): continue
			if bool(m.abilities[id].get("passive", false)):
				if id not in passive: passive.append(id)
			elif id not in u.kit: u.kit.append(id)
		u.passives = passive
		if "pathfinder" in passive: u.mob = int(u.mob) + 1
		if "wildBond" in passive: u.focus_left = int(u.focus)
		if str(u.class_name) == "Heavy": u.grenades = 2
		# Legacy drills apply for living roster partners, even when the partner stays home.
		for key in state.get("bonds", {}):
			var ids: PackedStringArray = str(key).split("|")
			if str(u.get("rid", "")) not in ids: continue
			var partner_alive := false
			for r in state.get("roster", []):
				if str(r.get("id", "")) in ids and str(r.id) != str(u.rid) and str(r.get("status", "")) != "dead": partner_alive = true
			if not partner_alive: continue
			var bond: Dictionary = state.bonds[key]
			for drill in bond.get("dr", []):
				var mods: Dictionary = Data.get_table("legacy", "DRILLS").get(drill, {}).get("mod", {})
				for stat in mods:
					if stat == "hp": u.hp = int(u.hp)+int(mods[stat]); u.max_hp = int(u.max_hp)+int(mods[stat])
					elif stat == "dmgHi": u.damage[1] = int(u.damage[1])+int(mods[stat])
					elif stat == "kits": u.medpacs = int(u.medpacs)+int(mods[stat])
					else: u[stat] = int(u.get(stat,0))+int(mods[stat])
			if int(bond.get("lvl",0)) >= 8: u.will = int(u.get("will",0))+10
