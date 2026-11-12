extends RefCounted
## Phone layout uses CSS/logical pixels; window_size() remains physical pixels.
static var test_scale := 0.0
static var test_touch := -1
static var test_mobile := -1
static var test_window_size := Vector2i.ZERO

static func window_size() -> Vector2i:
	if test_window_size != Vector2i.ZERO: return test_window_size
	if OS.has_feature("web"):
		var width: Variant = JavaScriptBridge.eval("document.getElementById('canvas')?.width || 0")
		var height: Variant = JavaScriptBridge.eval("document.getElementById('canvas')?.height || 0")
		if width != null and height != null and int(width) > 0 and int(height) > 0:
			return Vector2i(int(width), int(height))
	var tree := Engine.get_main_loop() as SceneTree
	if DisplayServer.get_name() == "headless" and tree != null: return tree.root.size
	var physical := DisplayServer.window_get_size()
	if physical.x > 0 and physical.y > 0: return physical
	return tree.root.size if tree != null else Vector2i.ZERO

static func device_scale() -> float:
	if test_scale > 0.0: return test_scale
	if OS.has_feature("web"):
		var ratio: Variant = JavaScriptBridge.eval("window.devicePixelRatio || 1")
		return maxf(1.0, float(ratio)) if ratio != null else 1.0
	return maxf(1.0, DisplayServer.screen_get_scale())

static func logical_size(size: Vector2i) -> Vector2:
	return Vector2(size) / device_scale()

static func touch_device() -> bool:
	if test_touch >= 0: return test_touch == 1
	if DisplayServer.is_touchscreen_available() or mobile_device(): return true
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0 || matchMedia('(pointer: coarse)').matches"))
	return false

static func mobile_device() -> bool:
	if test_mobile >= 0: return test_mobile == 1
	return OS.has_feature("web_ios") or OS.has_feature("web_android") or OS.has_feature("mobile")

static func safe_margins(view_size: Vector2) -> Vector4:
	var physical := window_size()
	if physical.x <= 0 or physical.y <= 0: return Vector4.ZERO
	var margins := Vector4.ZERO
	if OS.has_feature("web"):
		margins = Vector4(
			float(JavaScriptBridge.eval("window.templeSafeArea?.left || 0")) * device_scale(),
			float(JavaScriptBridge.eval("window.templeSafeArea?.top || 0")) * device_scale(),
			float(JavaScriptBridge.eval("window.templeSafeArea?.right || 0")) * device_scale(),
			float(JavaScriptBridge.eval("window.templeSafeArea?.bottom || 0")) * device_scale())
	else:
		var safe := DisplayServer.get_display_safe_area()
		if safe.size.x > 0 and safe.size.y > 0:
			margins = Vector4(maxi(0, safe.position.x), maxi(0, safe.position.y), maxi(0, physical.x - safe.end.x), maxi(0, physical.y - safe.end.y))
	return Vector4(margins.x * view_size.x / physical.x, margins.y * view_size.y / physical.y,
		margins.z * view_size.x / physical.x, margins.w * view_size.y / physical.y)

static func narrow(size: Vector2i) -> bool:
	var logical := logical_size(size)
	var short_side := minf(logical.x, logical.y)
	# A 1366×768 desktop window also has a short side below 900.
	return short_side > 0.0 and short_side < 900.0 and (maxf(logical.x, logical.y) < 1200.0 or mobile_device() or touch_device())

static func battle_board_fraction(size: Vector2) -> float:
	# Conservative area budget for the scaled top, tray and two collapsed cards.
	var covered := size.x * (42.0 + 64.0) * 1.2 + minf(size.x, 436.0 * 1.2) * 38.0 * 1.2
	return 1.0 - covered / maxf(1.0, size.x * size.y)
