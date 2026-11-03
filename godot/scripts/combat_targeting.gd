extends RefCounted
const Shot = preload("res://scripts/shot.gd")
const Concealment = preload("res://scripts/combat_concealment.gd")
var g
var trace_root: Node3D
var detection_root: Node3D

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
