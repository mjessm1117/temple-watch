extends MultiMeshInstance3D
## A fixed pool shares one material/draw across flash, core, debris and smoke.
const LOW_CAP := 12
const HIGH_CAP := 32
var capacity := 0
var cursor := 0
var slots: Array[Dictionary] = []

func configure(low: bool) -> void:
	name = "LightfxBillboards"
	capacity = LOW_CAP if low else HIGH_CAP
	cursor = 0; slots.clear()
	var plane := QuadMesh.new(); plane.size = Vector2.ONE
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 1.45
	mat.albedo_texture = _soft_texture()
	plane.material = mat
	var pool := MultiMesh.new(); pool.transform_format = MultiMesh.TRANSFORM_3D
	pool.use_colors = true; pool.instance_count = capacity; pool.mesh = plane
	pool.custom_aabb = AABB(Vector3(-100, -20, -100), Vector3(200, 80, 200))
	multimesh = pool
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in capacity:
		slots.append({"age": 999.0, "life": 0.1, "at": Vector3.ZERO, "drift": Vector3.ZERO, "size": 0.0, "color": Color.TRANSPARENT})
		_hide(i)

func spawn(at: Vector3, size: float, color: Color, life: float, drift := Vector3.ZERO) -> void:
	if multimesh == null: return
	var i := cursor; cursor = (cursor + 1) % capacity
	slots[i] = {"age": 0.0, "life": life, "at": at, "drift": drift, "size": size, "color": color}
	_draw(i)

func _process(delta: float) -> void:
	for i in capacity:
		if float(slots[i].age) >= float(slots[i].life): continue
		slots[i].age = float(slots[i].age) + delta
		if float(slots[i].age) >= float(slots[i].life): _hide(i)
		else: _draw(i)

func _draw(i: int) -> void:
	var slot: Dictionary = slots[i]
	var fraction := float(slot.age) / float(slot.life)
	var scale_value := float(slot.size) * (1.0 + fraction * 0.7)
	var at: Vector3 = slot.at + slot.drift * float(slot.age)
	multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_value), at))
	var color: Color = slot.color
	color.a *= 1.0 - fraction
	multimesh.set_instance_color(i, color)

func _hide(i: int) -> void:
	multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.0001), Vector3.ZERO))
	multimesh.set_instance_color(i, Color.TRANSPARENT)

func _soft_texture() -> ImageTexture:
	var pixels := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var radius := Vector2((float(x) - 15.5) / 15.5, (float(y) - 15.5) / 15.5).length()
			pixels.set_pixel(x, y, Color(1, 1, 1, 1.0 - smoothstep(0.15, 1.0, radius)))
	return ImageTexture.create_from_image(pixels)
