extends RefCounted
## Runtime copies keep the source/imported art untouched and High fully reversible.
var textures: Dictionary = {}
var materials: Dictionary = {}
var meshes: Dictionary = {}

func small_texture(texture: Texture2D) -> Texture2D:
	if texture.get_width() <= 1024 and texture.get_height() <= 1024: return texture
	if textures.has(texture): return textures[texture]
	var pixels := texture.get_image()
	if pixels == null: return texture
	if pixels.is_compressed(): pixels.decompress()
	var ratio := 1024.0/maxi(pixels.get_width(),pixels.get_height())
	pixels.resize(maxi(1,int(pixels.get_width()*ratio)),maxi(1,int(pixels.get_height()*ratio)),Image.INTERPOLATE_LANCZOS)
	pixels.generate_mipmaps()
	var result := ImageTexture.create_from_image(pixels)
	textures[texture] = result
	return result

func small_material(material: Material) -> Material:
	if material == null: return null
	if materials.has(material): return materials[material]
	var replacements: Dictionary = {}
	for property in material.get_property_list():
		var value = material.get(property.name)
		if value is Texture2D and (value.get_width() > 1024 or value.get_height() > 1024):
			replacements[property.name] = small_texture(value)
	if replacements.is_empty(): return material
	var result: Material = material.duplicate()
	for property in replacements: result.set(property,replacements[property])
	materials[material] = result
	return result

func small_mesh(mesh: Mesh) -> Mesh:
	if mesh == null: return null
	if meshes.has(mesh): return meshes[mesh]
	var replacements: Dictionary = {}
	for surface in mesh.get_surface_count():
		var material := mesh.surface_get_material(surface)
		var reduced := small_material(material)
		if reduced != material: replacements[surface] = reduced
	if replacements.is_empty(): return mesh
	var result: Mesh = mesh.duplicate()
	for surface in replacements:
		if result is ArrayMesh: result.surface_set_material(surface,replacements[surface])
		elif result is PrimitiveMesh: result.material = replacements[surface]
	meshes[mesh] = result
	return result

func replace(object: Object, property: String, reduced: Resource) -> void:
	var key := "graphics_original_"+property
	if object.get(property) == reduced: return
	if not object.has_meta(key): object.set_meta(key,object.get(property))
	object.set(property,reduced)

func restore(object: Object, property: String) -> void:
	var key := "graphics_original_"+property
	if object.has_meta(key):
		object.set(property,object.get_meta(key)); object.remove_meta(key)

func apply(node: GeometryInstance3D, low: bool) -> void:
	if low:
		replace(node,"material_override",small_material(node.material_override))
		if node is MeshInstance3D:
			replace(node,"mesh",small_mesh(node.mesh))
			for surface in node.get_surface_override_material_count():
				var mat: Material = node.get_surface_override_material(surface)
				var reduced := small_material(mat)
				if mat != reduced:
					node.set_meta("graphics_surface_%d" % surface,mat)
					node.set_surface_override_material(surface,reduced)
		elif node is MultiMeshInstance3D and node.multimesh:
			replace(node.multimesh,"mesh",small_mesh(node.multimesh.mesh))
	else:
		restore(node,"material_override")
		if node is MeshInstance3D:
			restore(node,"mesh")
			for surface in node.get_surface_override_material_count():
				var key := "graphics_surface_%d" % surface
				if node.has_meta(key):
					node.set_surface_override_material(surface,node.get_meta(key)); node.remove_meta(key)
		elif node is MultiMeshInstance3D and node.multimesh: restore(node.multimesh,"mesh")
