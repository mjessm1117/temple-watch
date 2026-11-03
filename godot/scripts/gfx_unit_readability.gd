extends RefCounted
## Compatibility-safe material rim and low, unobtrusive selection marker.
const RIM = preload("res://assets/env/unit_rim.gdshader")
const BLUE := Color(0.31,0.77,1.0,0.42)
const GOLD := Color(1.0,0.76,0.36,0.44)
const RED := Color(1.0,0.30,0.34,0.48)

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
	var color := RED if str(data.side) == "enemy" else GOLD if str(data.get("class_name","")) in ["Guardian","Consular"] else BLUE
	var material := ShaderMaterial.new()
	material.shader = RIM
	material.set_shader_parameter("rim_color",color)
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
			torus.inner_radius = 0.51
			torus.outer_radius = 0.57
			marker.mesh = torus
			marker.position.y = 0.045
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color("ffdb8e")
			mat.emission_enabled = true
			mat.emission = Color("ffbe54")
			marker.material_override = mat
			unit.add_child(marker)
		marker.visible = selected
