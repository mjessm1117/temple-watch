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

static func _direct(m: RefCounted, a: Vector2i, b: Vector2i, peek: bool) -> bool:
	var points := line(a, b)
	var n: int = points.size() - 1
	if n < 1: return true
	var ea: float = elevation(m, a) + 1.2
	var eb: float = elevation(m, b) + 1.2
	for i in range(1, n):
		var p: Vector2i = points[i]
		if max(abs(p.x - b.x), abs(p.y - b.y)) <= 1: continue
		if not peek and max(abs(p.x - a.x), abs(p.y - a.y)) <= 1 and not full(m.tile(p)): continue
		var c: String = m.tile(p)
		var top: float = float(elevation(m, p)) + (2.0 if full(c) else 0.0)
		if top > 0.0 and top >= ea + (eb - ea) * float(i) / n: return false
	return true

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
	var a := pos(attacker)
	var t := pos(target)
	var lines: Array = [["Base aim", int(attacker.aim)]]
	var cv := 0
	if melee: lines.append(["Close quarters", 10])
	else:
		cv = cover(m, t, a)
		# A two-level vantage sees over one tier of nearby cover.
		if elevation(m, a) - elevation(m, t) >= 2: cv = maxi(0, cv - 20)
		if cv > 0: lines.append(["Full cover" if cv == 40 else "Half cover", -cv])
		var d := distance(a, t)
		var r := float(attacker.range)
		if d > r * 0.6: lines.append(["Range", -roundi((d - r * 0.6) * 3)])
	if elevation(m, a) > elevation(m, t): lines.append(["High ground", 20])
	var defense := int(target.get("defense", 0))
	if bool(target.get("hunkered", false)): defense += 30
	if defense > 0: lines.append(["Defense", -defense])
	if modifier != 0: lines.append(["Ability", modifier])
	var raw := 0
	for item in lines: raw += int(item[1])
	var hit := clampi(raw, 5, 95)
	var flanked := not melee and in_cover(m, t) and cv == 0
	if flanked: lines.append(["Flanking critical chance", 50])
	if bool(target.get("hunkered", false)) and flanked: lines.append(["Hunker blocks flank critical", -50])
	var crit := int(attacker.get("crit", 0)) + (50 if flanked and not bool(target.get("hunkered", false)) else 0)
	return {"lines": lines, "hit": hit, "crit": crit, "graze": 0 if melee else min(GRAZE, 100 - hit), "cover": cv, "flanked": flanked, "los": melee or los(m, a, t), "range_ok": melee or distance(a, t) <= float(attacker.range)}
