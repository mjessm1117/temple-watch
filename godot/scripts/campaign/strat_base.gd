extends RefCounted
## Spatial Temple rules. Save data is plain dictionaries; presentation reads the same model.
const Data = preload("res://scripts/campaign/data.gd")
const POWER = {"medical":2, "training":1, "forge":3, "armory":2, "comms":2, "archives":2, "gardens":1, "barracks":1}
const ROLE = {"medical":"healer", "gardens":"healer", "archives":"archivist", "comms":"archivist", "training":"artisan", "forge":"artisan", "armory":"artisan", "barracks":"artisan"}

static func ensure(s: Dictionary) -> void:
	if not s.has("slots"): s.slots = {}
	if not s.has("facility"):
		s.facility = {"clear":[], "dig":{}, "relay":0, "build_left":7.0, "workers":[
			{"id":"staff1", "n":"Archivist Sera", "role":"archivist", "wing":""},
			{"id":"staff2", "n":"Artisan Daro", "role":"artisan", "wing":""},
			{"id":"staff3", "n":"Healer Nemi", "role":"healer", "wing":"medical"}], "next_staff":4, "log":{}}
		# Existing rooms are grandfathered into usable power and excavated bays.
		var used := 0
		for k in s.wings:
			if int(s.wings[k]) > 0: used += int(POWER.get(k, 0))
		s.facility.relay = maxi(0, ceili(float(used - 8) / 4))
		for slot in Data.get_table("temple", "SLOTS"):
			if slot.tier == "b": s.facility.clear.append(slot.id)
	for k in s.wings:
		if (int(s.wings[k]) > 0 or s.get("build", "") == k) and slot_of(s, k) == "":
			var home: String = Data.get_table("temple", "WING_HOME")[k]
			if not s.slots.has(home): s.slots[home] = k
		for slot in s.slots:
			if not s.facility.clear.has(slot): s.facility.clear.append(slot)
	if not s.has("mods"): s.mods = {}
	for key in ["dug", "spire", "features", "spire_work"]:
		if not s.mods.has(key): s.mods[key] = {}

static func slot_of(s: Dictionary, wing: String) -> String:
	for slot in s.get("slots", {}):
		if s.slots[slot] == wing: return str(slot)
	return ""

static func slot_data(id: String) -> Dictionary:
	for slot in Data.get_table("temple", "SLOTS"):
		if slot.id == id: return slot
	return {}

static func adjacent(a: String, b: String) -> bool:
	var x := slot_data(a); var y := slot_data(b)
	if x.is_empty() or y.is_empty() or a == b: return false
	return (x.row == y.row and absf(float(x.x) - float(y.x)) == 1.0) or (absi(int(x.row) - int(y.row)) == 1 and absf(float(x.x) - float(y.x)) == 0.5)

static func staff_count(s: Dictionary, wing: String) -> int:
	var count := 1 if s.get("staff", {}).has(wing) else 0
	for worker in s.get("facility", {}).get("workers", []):
		if worker.wing == wing: count += 1
	return count

static func power(s: Dictionary) -> Dictionary:
	var used := 0
	for k in POWER:
		if int(s.wings.get(k, 0)) > 0 or s.get("build", "") == k: used += int(POWER[k])
	return {"used":used, "capacity":8 + 4 * int(s.get("facility", {}).get("relay", 0))}

static func operational(s: Dictionary, wing: String) -> bool:
	var p := power(s)
	return int(s.wings.get(wing, 0)) > 0 and int(p.used) <= int(p.capacity)

static func effects(s: Dictionary) -> Dictionary:
	var out := {}
	for pair in Data.get_table("temple", "ADJ"):
		if operational(s, pair.a) and operational(s, pair.b) and adjacent(slot_of(s, pair.a), slot_of(s, pair.b)):
			out[pair.k] = int(out.get(pair.k, 0)) + int(pair.v) * (2 if staff_count(s, pair.a) + staff_count(s, pair.b) > 0 else 1)
	for id in s.get("mods", {}).get("spire", {}):
		if s.mods.spire[id]: _merge(out, Data.get_table("temple", "SPIRES")[id].eff)
	for id in s.get("mods", {}).get("features", {}):
		var feature: Dictionary = Data.get_table("temple", "BAY_FEAT").get(s.mods.features[id], {})
		var enabled := true
		for wing in feature.get("wings", []):
			if not operational(s, wing): enabled = false
		if enabled: _merge(out, feature)
	return out

static func _merge(out: Dictionary, effect: Dictionary) -> void:
	for key in ["heal", "research", "stress", "bench", "winCr", "will", "xp"]:
		out[key] = int(out.get(key, 0)) + int(effect.get(key, 0))
	for key in effect.get("month", {}): out[key] = int(out.get(key, 0)) + int(effect.month[key])

static func log_room(s: Dictionary, wing: String, message: String) -> void:
	var entries: Array = s.facility.log.get(wing, [])
	entries.push_front("M%d D%d · %s" % [s.month, s.day, message])
	entries.resize(mini(12, entries.size())); s.facility.log[wing] = entries

static func excavate(c, id: String) -> bool:
	ensure(c.state)
	var slot := slot_data(id)
	if slot.is_empty() or slot.tier == "sp" or c.state.facility.clear.has(id) or not c.state.facility.dig.is_empty(): return false
	var artisan := false
	for worker in c.state.facility.workers:
		if worker.role == "artisan" and worker.wing == "": artisan = true
	if not artisan: return false
	var cost := int(Data.get_table("temple", "UNDER_DIG").get(id, 40))
	if not c.spend({"credits":cost}): return false
	c.state.facility.dig = {"slot":id, "left":5}
	# Excavation reserves an artisan until completion.
	for worker in c.state.facility.workers:
		if worker.role == "artisan" and worker.wing == "": worker.wing = "excavation"; break
	return true

static func place(c, wing: String, slot: String) -> bool:
	ensure(c.state)
	var d := slot_data(slot)
	if not POWER.has(wing) or d.is_empty() or int(d.wing) != 1 or not c.state.facility.clear.has(slot) or c.state.slots.has(slot): return false
	if int(c.state.wings[wing]) > 0: return false
	var old := slot_of(c.state, wing)
	if old != "": c.state.slots.erase(old)
	c.state.slots[slot] = wing
	return true

static func reserve(c, wing: String) -> bool:
	ensure(c.state)
	var p := power(c.state)
	if int(c.state.wings[wing]) == 0 and int(p.used) + int(POWER[wing]) > int(p.capacity): return false
	if slot_of(c.state, wing) != "": return true
	var home: String = Data.get_table("temple", "WING_HOME")[wing]
	if place(c, wing, home): return true
	for slot in c.state.facility.clear:
		if place(c, wing, slot): return true
	return false

static func assign_worker(c, id: String, wing: String) -> bool:
	ensure(c.state)
	for worker in c.state.facility.workers:
		if worker.id != id or worker.wing == "excavation": continue
		if wing != "" and (not operational(c.state, wing) or ROLE.get(wing) != worker.role or staff_count(c.state, wing) >= mini(2, int(c.state.wings[wing]))): return false
		worker.wing = wing
		if wing != "": log_room(c.state, wing, "%s assigned" % worker.n)
		return true
	return false

static func hire_staff(c, role: String) -> bool:
	if role not in ["archivist", "artisan", "healer"] or not c.spend({"credits":75, "recruits":1}): return false
	var id := int(c.state.facility.next_staff); c.state.facility.next_staff = id + 1
	c.state.facility.workers.append({"id":"staff%d" % id, "n":"%s %d" % [role.capitalize(), id], "role":role, "wing":""})
	return true

static func relay(c) -> bool:
	if not c.spend({"credits":80 + 40 * int(c.state.facility.relay)}): return false
	c.state.facility.relay = int(c.state.facility.relay) + 1
	return true

static func spire(c, id: String) -> bool:
	if not Data.get_table("temple", "SPIRES").has(id) or c.state.mods.spire.get(id, false) or not c.state.mods.spire_work.is_empty(): return false
	if int(c.state.month) < 4 and int(c.state.era) < 2: return false
	if not c.spend(Data.get_table("temple", "SPIRE_COST")): return false
	c.state.mods.spire_work = {"id":id, "left":14}
	return true

static func tick(c) -> void:
	var s: Dictionary = c.state
	if not s.facility.dig.is_empty():
		s.facility.dig.left = int(s.facility.dig.left) - 1
		if int(s.facility.dig.left) <= 0:
			var id: String = s.facility.dig.slot
			s.facility.clear.append(id); s.facility.dig = {}
			for worker in s.facility.workers:
				if worker.wing == "excavation": worker.wing = ""
			if id.begins_with("u"):
				s.mods.dug[id] = true
				var feature: String = {"u0":"kyber2", "u1":"holocron", "u2":"crypt"}[id]
				s.mods.features[id] = feature
				for key in Data.get_table("temple", "BAY_FEAT")[feature].get("found", {}): c.gain(key, int(Data.get_table("temple", "BAY_FEAT")[feature].found[key]))
			s.news.append("Excavation complete: %s." % slot_data(id).n)
	if not s.mods.spire_work.is_empty():
		s.mods.spire_work.left = int(s.mods.spire_work.left) - 1
		if int(s.mods.spire_work.left) <= 0:
			s.mods.spire[s.mods.spire_work.id] = true; s.news.append("Spire online: %s" % s.mods.spire_work.id); s.mods.spire_work = {}
	if s.build != "":
		var artisans := 0
		for w in s.facility.workers:
			if w.role == "artisan" and w.wing == "": artisans += 1
		s.facility.build_left = float(s.facility.build_left) - 1.0 - 0.5 * artisans
		if float(s.facility.build_left) <= 0:
			var wing: String = s.build
			s.wings[wing] = int(s.wings[wing]) + 1; s.build = ""
			log_room(s, wing, "Construction complete: level %d" % s.wings[wing]); s.news.append("%s is ready." % wing.capitalize())

static func summary(s: Dictionary, wing: String) -> String:
	var staff := staff_count(s, wing)
	var readiness := "ONLINE" if operational(s, wing) else "NO POWER" if int(s.wings.get(wing, 0)) > 0 else "UNBUILT"
	var production := {"medical":"healing +%d every 3 days" % staff, "archives":"research ×%.1f" % (1 + 0.5 * staff), "forge":"projects ×%.1f" % (1 + 0.5 * staff), "training":"training ×%.1f" % (1 + 0.5 * staff), "barracks":"+%d recruits/month" % staff, "comms":"+%d intel/month" % staff, "gardens":"−%d Darkness/month" % staff, "armory":"20% discount" if staff > 0 else "equipment"}
	return "%s · staff %d/%d · %d power · %s" % [readiness, staff, mini(2, maxi(1, int(s.wings.get(wing, 0)))), POWER[wing], production[wing]]

static func production(s: Dictionary, wing: String) -> String:
	if wing == "archives" and s.research.cur != "": return "%s · %.1f days researched" % [Data.get_table("research", "RESEARCH")[s.research.cur].n, s.research.prog]
	if wing == "forge" and not s.get("strategy", {}).get("project", {}).is_empty():
		var p: Dictionary = s.strategy.project
		return "%s · %.1f work days" % [Data.get_table("temple", "PROJECTS")[p.id].n, p.progress]
	if wing == "training" and not s.get("strategy", {}).get("training", {}).is_empty():
		var t: Dictionary = s.strategy.training
		return "%s · %s · %.1f days left" % [t.id, t.mode, t.left]
	if wing == "medical":
		var patients := 0
		for r in s.roster:
			if r.status == "active" and int(r.wound) > 0: patients += 1
		return "%d patients recovering" % patients
	return "No project in progress"
