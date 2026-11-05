extends RefCounted
## Quality uniform for the existing batched battle materials; no mesh copies.
const STONE = preload("res://assets/env/stone.gdshader")
const TERRAIN = preload("res://assets/env/terrain.gdshader")

static func apply(art: Node, low: bool) -> void:
	if art == null or not art.get("palette") is Dictionary: return
	for material in art.palette.values():
		if material is ShaderMaterial and material.shader in [STONE,TERRAIN]:
			material.set_shader_parameter("detail_quality",0.0 if low else 1.0)
