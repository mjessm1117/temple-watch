extends RefCounted
const PATH = "user://style21-settings.cfg"

static func get_value(key: String) -> Variant:
	var config := ConfigFile.new()
	config.load(PATH)
	return config.get_value("accessibility", key, 1.0 if key == "text_scale" else true)

static func set_value(key: String, value: Variant) -> bool:
	if key not in ["text_scale", "sound"]: return false
	if key == "text_scale" and float(value) not in [1.0, 1.15, 1.3]: return false
	var config := ConfigFile.new()
	config.load(PATH)
	config.set_value("accessibility", key, value)
	var error := config.save(PATH)
	if error == OK and key == "sound": AudioServer.set_bus_mute(0, not bool(value))
	return error == OK
