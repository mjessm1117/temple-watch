extends RefCounted
const Shot = preload("res://scripts/shot.gd")
const Concealment = preload("res://scripts/combat_concealment.gd")
var g
var trace_root: Node3D
var detection_root: Node3D

func decision_details24(attacker: Dictionary, target: Dictionary) -> Array:
	if g == null or attacker.is_empty() or target.is_empty(): return []
	var melee: bool = str(g.action) == "strike"
	var modifier: int = int(attacker.get("leap_aim", 0)) if melee else 0
	var data: Dictionary = shot_breakdown(g.mission, attacker, target, melee, modifier)
	var details: Array = []
	var present: Dictionary = {}
	for line in data.get("lines", []):
		var label: String = str(line[0])
		details.append({"label": label, "value": int(line[1])})
		present[label] = true
	if not melee and not (present.has("Full cover") or present.has("Half cover") or present.has("No cover")):
		details.append({"label": "No cover", "value": 0})
	for missing in ["High ground", "Flanking critical chance", "Ability", "Range"]:
		if not present.has(missing): details.append({"label": missing, "value": 0})
	for item in data.get("aim_lines", []):
		if str(item[0]) == "Hit chance cap": details.append({"label": "Hit chance cap", "value": int(item[1])})
	return details

static func shot_breakdown(m: RefCounted, actor: Dictionary, target: Dictionary, melee: bool = false, modifier: int = 0) -> Dictionary:
	var data: Dictionary = Shot.calculate(m, actor, target, melee, modifier)
	var aim_lines: Array = []
	var raw := 0
	for item in data.lines:
		if str(item[0]) in ["Flanking critical chance", "Hunker blocks flank critical"]: continue
		aim_lines.append(item)
		raw += int(item[1])
	if raw != int(data.hit): aim_lines.append(["Hit chance cap", int(data.hit) - raw])
	data.aim_lines = aim_lines
	return data

static func decision_summary(data: Dictionary, target_name: String, melee: bool = false) -> Dictionary:
	var modifiers: Array[String] = []
	if not melee:
		modifiers.append("COVER −%d" % int(data.get("cover", 0)) if int(data.get("cover", 0)) > 0 else "NO COVER +0")
	for item in data.get("lines", []):
		if str(item[0]) == "High ground" and int(item[1]) != 0:
			modifiers.append("HEIGHT %+d" % int(item[1]))
			break
	if modifiers.size() < 2:
		for item in data.get("lines", []):
			var label := str(item[0])
			if label in ["Base aim", "Full cover", "Half cover", "No cover", "High ground", "Flanking critical chance", "Hunker blocks flank critical"] or int(item[1]) == 0: continue
			modifiers.append("%s %+d" % [label.to_upper(), int(item[1])])
			if modifiers.size() == 2: break
	return {"target": target_name, "hit": int(data.get("hit", 0)), "badge": "FLANKED" if bool(data.get("flanked", false)) else "NO COVER" if not melee and int(data.get("cover", 0)) == 0 else "IN COVER", "modifiers": modifiers.slice(0, 2)}

func clear_trace() -> void:
	if trace_root == null:
		trace_root = Node3D.new(); g.add_child(trace_root)
	g._clear(trace_root)

func detection() -> void:
	if detection_root == null:
		detection_root = Node3D.new(); g.add_child(detection_root)
	g._clear(detection_root)
	if g.mission.get("squad_concealed") == null: return
	for tile in Concealment.detection_tiles(g.mission):
		g.hud_controls._border(detection_root, tile, Color("e65747"), 0.16)

func trace(actor: Dictionary, target: Dictionary) -> void:
	var data := Shot.trace(g.mission, Shot.pos(actor), Shot.pos(target))
	var a: Vector2i = data.origin
	var b: Vector2i = data.end if bool(data.clear) else data.blocker
	var from := Vector3(a.x, Shot.elevation(g.mission, a) * 0.7 + 1, a.y)
	var to := Vector3(b.x, Shot.elevation(g.mission, b) * 0.7 + 1, b.y)
	var color := Color("73dfe9") if bool(data.clear) else Color("ff604d")
	var count := maxi(1, ceili(from.distance_to(to) * 3))
	for i in range(count):
		var at := from.lerp(to, float(i) / count)
		g._box(trace_root, at, Vector3(0.07, 0.07, 0.14), color)
	if not bool(data.clear):
		g.hud_controls._border(trace_root, b, color, 0.3)
		var label := Label3D.new(); label.text = "LINE BLOCKED"; label.font_size = 36
		label.position = to + Vector3.UP * 0.7; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = color; trace_root.add_child(label)
