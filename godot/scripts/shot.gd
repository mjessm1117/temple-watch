extends RefCounted
class_name ShotRules

# Direct port of public/js/rules.js: line, los/los0, coverVal, odds and graze band.
const GRAZE: int = 10
const DIRS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

static func pos(u: Dictionary) -> Vector2i:
	return Vector2i(int(u.x), int(u.y))

static func distance(a: Vector2i, b: Vector2i) -> float:
	return a.distance_to(b)

static func elevation(m: RefCounted, p: Vector2i) -> int:
	var c: String = m.tile(p)
	if c == "M": return 2
	if c == "^": return 1
	return 0

static func full(c: String) -> bool:
	return c == "#"

static func half(c: String) -> bool:
	return c in ["c", "h", "k"]

static func line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var n: int = max(abs(b.x - a.x), abs(b.y - a.y)) * 2
	if n == 0: return [a]
	for i in range(n + 1):
		var t: float = float(i) / n
		var p := Vector2i(roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t)))
		if out.is_empty() or out.back() != p: out.append(p)
	return out

static func _blocker(m: RefCounted, a: Vector2i, b: Vector2i, peek: bool) -> Vector2i:
	var points := line(a, b)
	var n: int = points.size() - 1
	if n < 1: return Vector2i(-1, -1)
	var ea: float = elevation(m, a) + 1.2
	var eb: float = elevation(m, b) + 1.2
	for i in range(1, n):
		var p: Vector2i = points[i]
		if max(abs(p.x - b.x), abs(p.y - b.y)) <= 1: continue
		if not peek and max(abs(p.x - a.x), abs(p.y - a.y)) <= 1 and not full(m.tile(p)): continue
		var c: String = m.tile(p)
		var top: float = float(elevation(m, p)) + (2.0 if full(c) else 0.0)
		if top > 0.0 and top >= ea + (eb - ea) * float(i) / n: return p
	return Vector2i(-1, -1)

static func _direct(m: RefCounted, a: Vector2i, b: Vector2i, peek: bool) -> bool:
	return _blocker(m, a, b, peek).x < 0

static func los(m: RefCounted, a: Vector2i, b: Vector2i) -> bool:
	if _direct(m, a, b, false): return true
	var beside_wall := false
	for d in DIRS:
		if full(m.tile(a + d)): beside_wall = true
	if not beside_wall: return false
	for d in DIRS:
		var p := a + d
		if m.in_bounds(p) and m.passable(p) and p != b and _direct(m, p, b, true): return true
	return false

static func cover(m: RefCounted, target: Vector2i, from: Vector2i) -> int:
	var value := 0
	var dx := signi(from.x - target.x)
	var dy := signi(from.y - target.y)
	var te := elevation(m, target)
	var fe := elevation(m, from)
	var checks: Array[Vector2i] = []
	if dx != 0: checks.append(target + Vector2i(dx, 0))
	if dy != 0: checks.append(target + Vector2i(0, dy))
	for p in checks:
		var c: String = m.tile(p)
		if full(c): value = max(value, 40)
		elif half(c): value = max(value, 20)
		elif m.in_bounds(p):
			var rise := elevation(m, p) - te
			if rise > 0 and fe < te + rise: value = max(value, 40 if rise >= 2 else 20)
	return value

static func in_cover(m: RefCounted, target: Vector2i) -> bool:
	for d in DIRS:
		var p := target + d
		if full(m.tile(p)) or half(m.tile(p)) or elevation(m, p) > elevation(m, target): return true
	return false

static func calculate(m: RefCounted, attacker: Dictionary, target: Dictionary, melee: bool = false, modifier: int = 0) -> Dictionary:
	var chains = preload("res://scripts/ability_chains.gd")
	modifier += preload("res://scripts/campaign/battle_sith.gd").aim(attacker,target,melee)
	if m.get("identity") != null: modifier += m.identity.aim(m,attacker)
	var a := pos(attacker)
	var t := pos(target)
	var lines: Array = [["Base aim", int(attacker.aim) + int(attacker.get("buff_aim", 0)) + int(attacker.get("debuff_aim", 0)) + int(target.get("marked_aim", 0))]]
	if chains.has_tag(target, "MARKED"): lines.append(["Marked", 20])
	if chains.has_tag(attacker, "INSPIRED"): lines.append(["Inspired", 15])
	if chains.has_tag(attacker, "PINNED"): lines.append(["Pinned", -15])
	if "executioner" in attacker.get("passives", []) and int(target.hp) * 2 <= int(target.max_hp): lines.append(["Executioner", 25])
	var bond_bonus := 0
	for ally in m.units:
		if int(ally.get("id", -1)) not in attacker.get("bondmates", {}) or int(ally.get("hp",0)) <= 0 or distance(pos(ally), a) > 3.0: continue
		var pair_key: String = attacker.bondmates[int(ally.id)]
		bond_bonus = maxi(bond_bonus, 10 if int(m.bond_pairs[pair_key].get("lvl",0)) >= 8 else 5)
	if bond_bonus > 0: lines.append(["Bond proximity", bond_bonus])
	if str(attacker.get("side", "")) == "player":
		var aura := 0
		for ally in m.units:
			if str(ally.get("side", "")) == "player" and int(ally.get("hp", 0)) > 0 and distance(pos(ally), a) <= 3.0:
				aura = maxi(aura, int(ally.get("master_aura", 0)))
		if aura > 0: lines.append(["Master aura", aura * 5])
	var cv := 0
	if melee: lines.append(["Close quarters", 10])
	else:
		cv = cover(m, t, a)
		if chains.has_tag(target, "EXPOSED") or chains.has_tag(target, "LIFTED"): cv = 0
		# A two-level vantage sees over one tier of nearby cover.
		if elevation(m, a) - elevation(m, t) >= 2: cv = maxi(0, cv - 20)
		lines.append(["Full cover" if cv == 40 else "Half cover" if cv == 20 else "No cover", -cv])
		var d := distance(a, t)
		var r := float(attacker.range)
		lines.append(["Range", -roundi((d - r * 0.6) * 3) if d > r * 0.6 else 0])
	lines.append(["High ground", 20 if elevation(m, a) > elevation(m, t) else 0])
	var defense := int(target.get("defense", 0))
	if bool(target.get("hunkered", false)): defense += 30
	defense += int(target.get("buff_defense", 0))
	if bool(target.get("guard", false)): defense += roundi(25 * float(target.get("guard_power", 1.0)))
	if chains.has_tag(target, "STAGGERED"): defense -= 15
	if str(target.get("side", "")) == "player":
		for ally in m.units:
			if str(ally.get("side", "")) == "player" and int(ally.get("hp", 0)) > 0 and int(ally.get("id", -1)) != int(target.get("id", -2)) and "defLine" in ally.get("passives", []) and distance(pos(ally), t) <= 1.5:
				defense += 15
				break
	if defense != 0: lines.append(["Defense", -defense])
	if modifier != 0: lines.append(["Ability", modifier])
	var raw := 0
	for item in lines: raw += int(item[1])
	var hit := clampi(raw, 5, 95)
	var flanked := not melee and in_cover(m, t) and cv == 0
	if flanked: lines.append(["Flanking critical chance", 50])
	if bool(target.get("hunkered", false)) and flanked: lines.append(["Hunker blocks flank critical", -50])
	var crit := int(attacker.get("crit", 0)) + (50 if flanked and not bool(target.get("hunkered", false)) else 0) + (10 if chains.has_tag(target, "MARKED") else 0)
	var sight := melee or los(m, a, t)
	if not sight and str(attacker.get("side", "")) == "player" and str(target.get("side", "")) == "enemy":
		for ally in m.units:
			if int(ally.get("hp", 0)) > 0 and "spotter" in ally.get("passives", []) and distance(pos(ally), t) <= 11.0 and los(m, pos(ally), t): sight = true; break
	return {"lines": lines, "hit": hit, "crit": crit, "graze": 0 if melee else min(GRAZE, 100 - hit), "cover": cv, "flanked": flanked, "los": sight, "range_ok": melee or distance(a, t) <= float(attacker.range)}

static func trace(m: RefCounted, a: Vector2i, b: Vector2i) -> Dictionary:
	if _direct(m, a, b, false): return {"clear":true, "origin":a, "end":b, "blocker":Vector2i(-1,-1)}
	var beside_wall := false
	for d in DIRS:
		if full(m.tile(a + d)): beside_wall = true
	if beside_wall:
		for d in DIRS:
			var p := a + d
			if m.in_bounds(p) and m.passable(p) and p != b and _direct(m, p, b, true): return {"clear":true, "origin":p, "end":b, "blocker":Vector2i(-1,-1)}
	return {"clear":false, "origin":a, "end":b, "blocker":_blocker(m, a, b, false)}

static func damage_preview(attacker: Dictionary, target: Dictionary) -> Dictionary:
	var armor := int(target.get("armor", 0))
	var low := int(attacker.damage[0]); var high := int(attacker.damage[1])
	return {"normal":[maxi(1, low-armor), maxi(1, high-armor)], "critical":[maxi(1, low+2-armor), maxi(1, high+2-armor)], "graze":[maxi(1, ceili(low*0.5)-armor), maxi(1, ceili(high*0.5)-armor)], "armor":armor, "shred":mini(1, armor)}
