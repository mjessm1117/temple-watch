extends SceneTree
const Touch = preload("res://scripts/touch_input.gd")
const Quality = preload("res://scripts/graphics_settings.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	check(Touch.should_click(Vector2.ZERO, Vector2(12,0), false, false), "tap becomes click")
	check(not Touch.should_click(Vector2.ZERO, Vector2(12.1,0), true, false), "drag threshold suppresses click")
	check(not Touch.should_click(Vector2.ZERO, Vector2.ZERO, false, true), "pinch suppresses click")
	check(Touch.pinched_zoom(20.0, 100.0, 500.0) == 9.0, "pinch clamps near")
	check(Touch.pinched_zoom(20.0, 500.0, 10.0) == 65.0, "pinch clamps far")
	check(Quality.default_tier("Linux", true, false, false) == "low", "web defaults Low")
	check(Quality.default_tier("Linux", false, false, false) == "high", "desktop defaults High")
	check(Quality.phone_ui_scale(Vector2i(844,390)) > 1.0, "phone UI enlarged")
	check(Quality.phone_ui_scale(Vector2i(1366,900)) == 1.0, "desktop UI unchanged")
	print("Mobile Web 1: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
