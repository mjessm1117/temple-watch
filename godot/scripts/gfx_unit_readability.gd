extends RefCounted
## Compatibility-safe material rim and low, unobtrusive selection marker.
const RIM = preload("res://assets/env/unit_rim.gdshader")
const BLUE := Color(0.0,0.831,1.0,0.72)
const GOLD := Color(1.0,0.76,0.36,0.72)
const RED := Color(1.0,0.188,0.188,0.72)
static var _accent_shader26: Shader

static func accent_shader26() -> Shader:
	if _accent_shader26 != null: return _accent_shader26
	_accent_shader26 = Shader.new()
	# Reuse the rim overlay, adding a narrow material color band across the torso.
	_accent_shader26.code = RIM.code.replace("void fragment() {", "uniform vec4 accent_color : source_color;\nvarying vec3 torso_pos;\nvoid vertex() { torso_pos = VERTEX; }\nvoid fragment() {").replace("ALPHA = edge * rim_color.a;", "float band = smoothstep(1.22, 1.25, torso_pos.y) * (1.0 - smoothstep(1.32, 1.35, torso_pos.y));\n\tband *= 1.0 - smoothstep(0.26, 0.34, abs(torso_pos.x));\n\tALBEDO = mix(ALBEDO, accent_color.rgb, band);\n\tEMISSION += accent_color.rgb * band * 0.7;\n\tALPHA = max(edge * rim_color.a, band * 0.55);")
	return _accent_shader26

static func unit_of(node: Node) -> Node:
	var current := node.get_parent()
	while current != null:
		var script = current.get_script()
		if script != null and str(script.resource_path) == "res://scripts/unit_view.gd": return current
		current = current.get_parent()
	return null

static func apply(node: GeometryInstance3D) -> void:
	if not node is MeshInstance3D or node.has_meta("gfx_rim"): return
	var unit := unit_of(node)
	if unit == null or unit.model == null: return
	var current: Node = node
	var in_model := false
	while current != unit:
		if current == unit.model: in_model = true
		current = current.get_parent()
	if not in_model: return
	var game = unit.get_parent().get_parent()
	if game == null or game.mission == null: return
	var data: Dictionary = game.mission.unit_by_id(unit.unit_id)
	if data.is_empty(): return
	var color := RED if str(data.side) == "enemy" else BLUE
	var material := ShaderMaterial.new()
	material.shader = accent_shader26()
	material.set_shader_parameter("rim_color",color)
	material.set_shader_parameter("accent_color", preload("res://scripts/unit_view.gd").side_color26(str(data.side)))
	node.material_overlay = material
	node.set_meta("gfx_rim",true)

static func update_selection(game: Node) -> void:
	for unit in game.figures.get_children():
		if unit.get_script() == null or str(unit.get_script().resource_path) != "res://scripts/unit_view.gd": continue
		var selected: bool = int(unit.unit_id) == int(game.selected_id)
		var marker: MeshInstance3D = unit.get_node_or_null("GfxSelectionRing")
		if marker == null:
			marker = MeshInstance3D.new()
			marker.name = "GfxSelectionRing"
			var torus := TorusMesh.new()
			torus.inner_radius = 0.52
			torus.outer_radius = 0.59
			marker.mesh = torus
			marker.position.y = 0.045
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color("fff0bc")
			mat.emission_enabled = true
			mat.emission = Color("ffcf60")
			marker.material_override = mat
			unit.add_child(marker)
		marker.visible = selected
