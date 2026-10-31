extends RefCounted
## Frozen web campaign tables, exported without numerical retuning.
const FILES = ["core", "temple", "research", "gear", "galaxy", "legacy", "missions"]
static var cache: Dictionary = {}

static func get_table(group: String, key: String) -> Variant:
	if not cache.has(group):
		var path := "res://data/campaign/%s.json" % group
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		cache[group] = parsed if parsed is Dictionary else {}
	return cache[group].get(key, {})

static func all(group: String) -> Dictionary:
	if not cache.has(group): get_table(group, "")
	return cache[group]
