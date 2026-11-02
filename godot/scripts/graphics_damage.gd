extends RefCounted
## Compatibility has no projected decals. Batch textured scars on cover bounds.
static func build(parent: Node3D, texture: Texture2D, transforms: Array[Transform3D]) -> void:
	if transforms.is_empty(): return
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh := BoxMesh.new(); mesh.size = Vector3.ONE; mesh.material = material
	var batch := MultiMesh.new(); batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh; batch.instance_count = transforms.size()
	for index in transforms.size(): batch.set_instance_transform(index,transforms[index])
	var view := MultiMeshInstance3D.new(); view.multimesh = batch
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(view)
