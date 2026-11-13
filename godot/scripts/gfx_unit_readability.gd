extends RefCounted
## Compatibility-safe material rim and low, unobtrusive selection marker.
const RIM = preload("res://assets/env/unit_rim.gdshader")
const BLUE := Color(0.0,0.831,1.0,0.72)
const GOLD := Color(1.0,0.76,0.36,0.72)
const RED := Color(1.0,0.188,0.188,0.72)
static var _accent_shader26: Shader
static var _side_plates27: Dictionary = {}

static func side_plate27(side: String) -> Texture2D:
	if _side_plates27.has(side): return _side_plates27[side]
	var enemy := side == "enemy"
	var color: Color = preload("res://scripts/unit_view.gd").side_color26(side)
	var image := Image.create(120, 50, false, Image.FORMAT_RGBA8)
	for y in 50:
		for x in 120:
			if x >= 49 and y >= 20 and y < 39:
				var edge := x < 52 or x >= 117 or y < 23 or y >= 36
				image.set_pixel(x, y, Color(color.r, color.g, color.b, 0.9 if edge else 0.48))
			elif x < 46:
				var filled := absf(float(x - 23)) + absf(float(y - 24)) * (0.8 if enemy else 1.15) < (23.0 if enemy else 21.0)
				if filled:
					var cut := enemy and y < 25 and absf(float(x - 23)) < float(25 - y) * 0.65
					if not cut: image.set_pixel(x, y, color)
	var texture := ImageTexture.create_from_image(image)
	_side_plates27[side] = texture
	return texture

static func accent_shader26() -> Shader:
	if _accent_shader26 != null: return _accent_shader26
	_accent_shader26 = Shader.new()
	# Reuse the rim overlay, adding a narrow material color band across the torso.
	_accent_shader26.code = RIM.code.replace("void fragment() {", "uniform vec4 accent_color : source_color;\nuniform float enemy_shape;\nvarying vec3 torso_pos;\nvoid vertex() { torso_pos = VERTEX; }\nvoid fragment() {").replace("ALPHA = edge * rim_color.a;", "float chest = smoothstep(1.13, 1.18, torso_pos.y) * (1.0 - smoothstep(1.47, 1.52, torso_pos.y));\n\tfloat width = 1.0 - smoothstep(0.31, 0.41, abs(torso_pos.x));\n\tfloat chevron = 1.0 - smoothstep(0.055, 0.11, abs(torso_pos.y - (1.25 - abs(torso_pos.x) * 0.42)));\n\tfloat ally_bars = (1.0 - smoothstep(0.06, 0.10, abs(torso_pos.y - 1.23))) + (1.0 - smoothstep(0.06, 0.10, abs(torso_pos.y - 1.39)));\n\tfloat side_mark = chest * width * (enemy_shape > 0.5 ? chevron : ally_bars);\n\tALBEDO = mix(ALBEDO, accent_color.rgb, clamp(side_mark, 0.0, 1.0));\n\tEMISSION += accent_color.rgb * side_mark * 0.7;\n\tALPHA = max(edge * rim_color.a, side_mark * 0.72);")
	return _accent_shader26

static func unit_of(node: Node) -> Node:
	var current := node.get_parent()
	while current != null:
		var script = current.get_script()
		if script != null and str(script.resource_path) == "res://scripts/unit_view.gd": return current
		current = current.get_parent()
	return null

static func apply(node: GeometryInstance3D) -> void:
	if not node is MeshInstance3D: return
	var unit := unit_of(node)
	if unit == null or unit.model == null: return
	var current: Node = node
	var in_model := false
	var attachment := false
	while current != unit:
		if current == unit.model: in_model = true
		if current is BoneAttachment3D: attachment = true
		current = current.get_parent()
	if not in_model: return
	var game = unit.get_parent().get_parent()
	if game == null or game.mission == null: return
	var graphics := unit.get_tree().root.get_node_or_null("Graphics")
	# The body mesh carries the side rim and chest band. Bone attachments can
	# contain dozens of tiny weapon parts; repeating that overlay on each part
	# costs a draw while adding no readable marking on the gate phone view.
	if attachment and graphics != null and graphics.effective == "low" and str(game.mission.spec.get("id", "")) == "relay":
		if node.has_meta("gfx_rim"):
			node.material_overlay = null
			node.remove_meta("gfx_rim")
		return
	if node.has_meta("gfx_rim"): return
	var data: Dictionary = game.mission.unit_by_id(unit.unit_id)
	if data.is_empty(): return
	var color := RED if str(data.side) == "enemy" else BLUE
	var material := ShaderMaterial.new()
	material.shader = accent_shader26()
	material.set_shader_parameter("rim_color",color)
	material.set_shader_parameter("accent_color", preload("res://scripts/unit_view.gd").side_color26(str(data.side)))
	material.set_shader_parameter("enemy_shape", 1.0 if str(data.side) == "enemy" else 0.0)
	node.material_overlay = material
	node.set_meta("gfx_rim",true)

static func update_selection(game: Node) -> void:
	for unit in game.figures.get_children():
		if unit.get_script() == null or str(unit.get_script().resource_path) != "res://scripts/unit_view.gd": continue
		var badge: Sprite3D = unit.get_node_or_null("SideBadge26")
		if badge != null:
			var side := "enemy" if unit.enemy_side else "player"
			badge.texture = side_plate27(side)
			badge.pixel_size = 0.016
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
