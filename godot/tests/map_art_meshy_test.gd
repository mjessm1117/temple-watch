extends RefCounted
const Maps = preload("res://scripts/map_catalog.gd")
const Mission = preload("res://scripts/mission.gd")
const Meshy = preload("res://scripts/meshy_theme_models.gd")
const Batch = preload("res://scripts/meshy_theme_batch.gd")
var t

func run(suite, art) -> void:
	t = suite
	var original: Dictionary = art.props.duplicate(true)
	var assets: Dictionary = {}
	audit(str(original.meshy1_models.objective),4000)
	for theme in original.meshy_themes:
		for path in original.meshy_themes[theme].values(): assets[path] = "cover"
	for path in original.meshy_objectives.values(): assets[path] = "objective"
	for path: String in assets:
		for lod in 2:
			var file := path if lod == 0 else path.trim_suffix(".glb")+"_lod1.glb"
			audit(file,(3000 if lod == 0 else 800) if assets[path] == "cover" else (4000 if lod == 0 else 1000))
	var examples := {"temple":"res://data/rescue.json","ruins":Maps.resolve("archive"),"caves":Maps.resolve("r_caves"),"jungle":Maps.resolve("h_grove"),"plains":Maps.resolve("blockade"),"snow":Maps.resolve("ilum"),"city":Maps.resolve("envoy"),"dock":Maps.resolve("rescue")}
	for theme: String in examples:
		var m = Mission.new(17,examples[theme]); var before: PackedByteArray = t.state(m)
		art.props = original.duplicate(true); art.build(m)
		t.validate(art,m,theme+" mapped")
		var enabled := signature(art)
		for kind in original.meshy_themes[theme]:
			t.check(art.batch.records.any(func(r): return r.get("meshy_path","") == original.meshy_themes[theme][kind]),theme+": "+kind+" present in real mission")
		t.check(art.batch.records.any(func(r): return r.role == "cover" and r.has("meshy_path")),theme+": own Meshy cover instantiated")
		for record in art.batch.records:
			if record.role == "cover" and record.has("meshy_path"):
				var kind := "full_cover" if record.kind == "#" else "half_cover"
				t.check(record.meshy_path == original.meshy_themes[theme].get(kind,""),theme+": no other theme borrowed")
		art.build(m)
		t.check(enabled == signature(art),theme+": seeded transforms stable across rebuild")
		for kind in ["full_cover","half_cover"]:
			art.props = original.duplicate(true); art.props.meshy_themes[theme].erase(kind); art.build(m)
			t.validate(art,m,theme+" missing "+kind)
			for record in art.batch.records:
				if record.role == "cover" and ((record.kind == "#") == (kind == "full_cover")):
					t.check(not record.has("meshy_path"),theme+": missing cover entry uses current art")
		art.props = original.duplicate(true); art.props.meshy_themes.erase(theme); art.props.meshy_objectives.clear(); art.props.meshy1_models.clear(); art.build(m)
		var fallback := signature(art)
		t.validate(art,m,theme+" missing theme")
		art.props = original.duplicate(true); art.props.meshy1_enabled = false; art.build(m)
		t.validate(art,m,theme+" disabled")
		t.check(fallback == signature(art),theme+": absent mappings and master switch render identical fallback")
		t.check(not art.batch.records.any(func(r): return r.has("meshy_path")),theme+": disabled means no Meshy models")
		t.check(before == t.state(m),theme+": fallback/rebuild preserve all mission state")
		await t.process_frame
	art.props = original
	for family in ["hack_terminal","destroy_relay","defend","sabotage","rescue","evac"]:
		var expected: String = {"hack_terminal":"terminal","destroy_relay":"relay","defend":"relay","sabotage":"charge","rescue":"restraint","evac":"beacon"}[family]
		t.check(Meshy.action(original,family) == expected,family+": action-based objective routing")
		t.check(not Meshy.objective_path(original,expected).is_empty() or expected == "terminal",family+": objective path mapped (legacy terminal lacks LOD1)")
	var empty := original.duplicate(true); empty.meshy_objectives.clear()
	for kind in original.meshy_objectives:
		t.check(Meshy.objective_path(empty,kind).is_empty(),kind+": missing objective falls back")
	t.check(Meshy.action(original,"operation").is_empty(),"unmapped operation keeps its existing art")
	for item in [["archive","terminal"],["relay","relay"],["sabotage","charge"],["rescue","restraint"],["escort","beacon"]]:
		var mission = Mission.new(17,Maps.resolve(item[0])); var before: PackedByteArray = t.state(mission)
		art.props = original.duplicate(true); art.props.meshy_objectives.erase(item[1])
		if item[1] == "terminal": art.props.meshy1_models.clear()
		art.build(mission); t.validate(art,mission,item[1]+" missing objective")
		t.check(not art.batch.records.any(func(r): return str(r.get("meshy_path","")).contains("obj_"+item[1])),item[1]+": missing objective uses fallback in mission")
		t.check(before == t.state(mission),item[1]+": objective fallback preserves mission")
	art.props = original
	var m = Mission.new(17,Maps.resolve("rescue")); art.build(m)
	t.check(art.batch.records.any(func(r): return r.get("meshy_path","").contains("restraint")),"captive uses restraint")
	m.prisoner.freed = true; art.refresh_markers(m)
	t.check(not art.batch.records.any(func(r): return r.get("meshy_path","").contains("restraint")),"freed escort uses person again")
	lod_ranges(art)
	await detection_batch(art)
	var b := Batch.new()
	t.check(not b.pair("",Vector3.ZERO,1,1),"empty model safely declines")
	t.check(not b.pair("res://assets/maps/not_present.glb",Vector3.ZERO,1,1),"absent GLB safely declines")
	# A valid LOD0 without its explicit LOD1 must also fall back, without a load error.
	t.check(not b.pair("res://assets/maps/crate.glb",Vector3.ZERO,1,1),"absent LOD pair safely declines")
	t.check(Meshy.cover_angle(m,Vector2i(7,7),false,true) == PI/2,"vertical map cover direction")
	t.check(Meshy.cover_angle(m,Vector2i(7,7),true,false) == 0,"horizontal map cover direction")
	for tile in [Vector2i(7,7),Vector2i(9,12),Vector2i(4,8)]:
		var angle := Meshy.cover_angle(m,tile,false,false)
		t.check(is_equal_approx(fmod(angle,PI/2),0.0),"isolated cover rotates by seeded quarter turns")

func signature(art) -> PackedByteArray:
	return var_to_bytes(art.batch.records)

func audit(path: String, cap: int) -> void:
	t.check(ResourceLoader.exists(path),"Meshy path/LOD exists: "+path)
	if not ResourceLoader.exists(path): return
	var packed = load(path)
	t.check(packed is PackedScene,"Meshy path loads: "+path)
	if not packed is PackedScene: return
	var instance = packed.instantiate(); var parts: Array = []
	var batch := Batch.new(); batch.collect(instance,Transform3D.IDENTITY,parts)
	var triangles := 0
	for part in parts:
		var mesh: Mesh = part.mesh
		for i in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(i)
			triangles += (arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null and not arrays[Mesh.ARRAY_INDEX].is_empty() else arrays[Mesh.ARRAY_VERTEX].size())/3
			var mat: Material = part.material if part.material else mesh.surface_get_material(i)
			if mat is BaseMaterial3D:
				for slot in BaseMaterial3D.TEXTURE_MAX:
					var texture: Texture2D = mat.get_texture(slot)
					if texture: t.check(texture.get_width() <= 512 and texture.get_height() <= 512,path+": texture <=512 squared")
	t.check(triangles > 0 and triangles <= cap,"%s: %d triangles <= %d" % [path,triangles,cap])
	instance.free()

func lod_ranges(art) -> void:
	var pairs := 0
	for holder in art.find_children("MeshyLOD0*","Node3D",true,false):
		var sibling: Node = holder.get_parent().get_child(holder.get_index()+1)
		t.check(str(sibling.name).begins_with("MeshyLOD1"),"each near group has far group")
		var near: GeometryInstance3D = holder.get_child(0)
		for far: GeometryInstance3D in sibling.get_children():
			t.check(near.custom_aabb == far.custom_aabb,"LOD range centres match across all materials")
			t.check(is_equal_approx(near.visibility_range_end,far.visibility_range_begin) and is_equal_approx(near.visibility_range_end,art.batch.lod_distance),"LOD complementary distance ranges")
			t.check(near.visibility_range_end_margin == 0 and far.visibility_range_begin_margin == 0,"LOD switch has no hole or overlap")
			t.check(far.visibility_range_fade_mode == GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED,"Compatibility uses hard range switch")
		pairs += 1
	t.check(pairs > 0,"real mission has LOD groups")

func detection_batch(art) -> void:
	var source := Node3D.new(); t.root.add_child(source)
	var view := preload("res://scripts/meshy_theme_markers.gd").new(); t.root.add_child(view); view.bind(source)
	var box = art.box(Vector3(4,1.56,6),Vector3(0.08,0.05,0.86),art.material(Color("e65747")),source)
	await t.process_frame; await t.process_frame
	t.check(source.get_child_count() == 1 and not source.visible,"detection batching preserves rule-owned nodes")
	var mm: MultiMesh = view.view.multimesh
	t.check(mm.visible_instance_count == 1,"detection border batched")
	t.check(view.submitted[0].transform.origin.is_equal_approx(box.position),"detection border retains exact raised height and position")
	t.check(view.submitted[0].transform.basis.get_scale().is_equal_approx(box.mesh.size),"detection border retains exact dimensions")
	t.check(view.submitted[0].color.is_equal_approx(box.material_override.albedo_color),"detection border retains color")
	source.remove_child(box); box.queue_free(); await t.process_frame; await t.process_frame
	t.check(view.view.multimesh.visible_instance_count == 0,"detection batch follows rule refresh")
	view.queue_free(); await t.process_frame; await t.process_frame
	t.check(source.visible,"detaching art restores source border visibility")
	source.queue_free(); await t.process_frame
