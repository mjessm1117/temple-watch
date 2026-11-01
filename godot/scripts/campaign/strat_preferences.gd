extends RefCounted
## Device-local presentation preferences, independent of campaign saves.
const PATH = "user://strategy-settings.cfg"
const DEFAULTS = {"speed":1.0,"cine":true,"motion":false,"numbers":false,"cb":false,"tips":true}
static var values: Dictionary = {}

static func get_value(key: String) -> Variant:
	if values.is_empty():
		var config := ConfigFile.new(); config.load(PATH)
		for name in DEFAULTS: values[name] = config.get_value("presentation", name, DEFAULTS[name])
	return values.get(key, DEFAULTS.get(key))

static func set_value(key: String, value: Variant) -> bool:
	if not DEFAULTS.has(key): return false
	get_value(key)
	if key == "speed" and float(value) not in [0.5, 1.0, 2.0, 4.0]: return false
	values[key] = value
	var config := ConfigFile.new()
	for name in values: config.set_value("presentation", name, values[name])
	return config.save(PATH) == OK
