extends RefCounted
## Slot zero is the legacy autosave path; numbered slots are independent snapshots.
const Campaign = preload("res://scripts/campaign/state.gd")

static func path(slot: int) -> String:
	return Campaign.SAVE_PATH if slot == 0 else "user://campaign-slot-%d.json" % slot

static func metadata(slot: int) -> Dictionary:
	var filename := path(slot)
	if not FileAccess.file_exists(filename): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(filename))
	if not parsed is Dictionary or int(parsed.get("v", 0)) not in [1, 2] or not parsed.get("C") is Dictionary: return {}
	var state: Dictionary = parsed.C
	return {"month":int(state.get("month", 1)), "day":int(state.get("day", 1)),
		"missions":int(state.get("step", 0)),
		"squad":state.get("roster", []).size(), "last_played":int(parsed.get("at", 0))}

static func description(slot: int) -> String:
	var info := metadata(slot)
	if info.is_empty(): return "Empty"
	var when := Time.get_datetime_string_from_unix_time(int(info.last_played), true) if int(info.last_played) > 0 else "Unknown"
	return "M%d D%d  ·  %d missions  ·  %d squad  ·  %s" % [info.month, info.day, info.missions, info.squad, when]

static func write(campaign: RefCounted, slot: int) -> bool:
	if slot < 0 or slot > 3: return false
	return campaign.save(path(slot))

static func read(campaign: RefCounted, slot: int) -> bool:
	if slot < 0 or slot > 3: return false
	return campaign.load_save(path(slot))
