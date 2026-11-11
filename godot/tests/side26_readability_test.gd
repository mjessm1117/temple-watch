extends SceneTree
const UnitView = preload("res://scripts/unit_view.gd")
const Readability = preload("res://scripts/gfx_unit_readability.gd")
const Geometry = preload("res://scripts/map_art_geometry.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var ally := UnitView.side_color26("ally")
	var enemy := UnitView.side_color26("enemy")
	check(ally.r < ally.g and ally.g < ally.b and ally.b > 0.5, "ally palette is saturated cyan")
	check(enemy.r > 0.5 and enemy.b < enemy.r, "enemy palette is saturated red")
	check(UnitView.side_color26("player") == ally, "rules player side maps to ally cyan")
	var view := UnitView.new()
	check(view.has_method("side_color26"), "live unit view exposes palette to the HUD")
	view.free()
	check(Readability.BLUE.a >= 0.70 and Readability.RED.a >= 0.70, "both side rims are opaque enough")
	check(Readability.accent_shader26().code.contains("accent_color"), "armor material has chest accent")
	var full := Geometry.cover_tint26(true)
	var half := Geometry.cover_tint26(false)
	check(full != half and full.b > full.r and half.r > half.b, "full cover is cooler and half cover warmer")
	var marker := UnitView._side_texture26("ally").get_image()
	check(marker.get_width() == 120 and marker.get_pixel(22,22).a > 0.9, "side diamond is at least 12 source pixels wide")
	check(marker.get_pixel(80,30).a > 0.4, "HP plate is colored in the same draw")
	print("side26_readability_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
