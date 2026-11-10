extends MultiMeshInstance3D
## One draw for bounded, drifting theme motes. Positions recycle without allocation.
const Presets = preload("res://scripts/gfx_theme_presets.gd")
var count := 0
var width := 12.0
var depth := 12.0
var phase := 0.0
var rise := 0.0
var _origin := Vector3.ZERO

func configure(theme: String, size: Vector2, low: bool, center: Vector3) -> void:
	name = "LightfxAmbient"
	count = 5 if low else 12 if theme != "snow" else 16
	width = size.x; depth = size.y; _origin = center
	var mood: Dictionary = Presets.motes(theme)
	rise = float(mood.rise)
	var plane := QuadMesh.new(); plane.size = Vector2(0.16, 0.16)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.albedo_color = Color(mood.color, 0.42 if low else 0.55)
	plane.material = mat
	var pool := MultiMesh.new(); pool.transform_format = MultiMesh.TRANSFORM_3D
	pool.instance_count = count; pool.mesh = plane
	multimesh = pool
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_range_end = 36.0
	_update_instances()

func _process(delta: float) -> void:
	phase += delta
	if phase > 1000.0: phase = 0.0
	_update_instances()

func _update_instances() -> void:
	if multimesh == null: return
	for i in count:
		var seed := float(i) * 7.713
		var x := fposmod(seed * 2.7 + phase * (0.13 + float(i % 3) * 0.05), width) - width * 0.5
		var z := fposmod(seed * 4.3 + phase * 0.09, depth) - depth * 0.5
		var y := fposmod(seed * 0.71 + phase * rise, 2.4) + 0.35
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, _origin + Vector3(x, y, z)))
