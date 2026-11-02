extends RefCounted
## Cohesion earned in battle and the lasting cost of losing a partner.

const Legacy = preload("res://scripts/campaign/legacy.gd")
const Progression = preload("res://scripts/campaign/progression.gd")

static func ensure(s: Dictionary) -> void:
	if not s.has("bonds"): s.bonds = {}
	if not s.has("story_grief"): s.story_grief = []
	if not s.has("bond_losses"): s.bond_losses = []
	for pair in s.bonds:
		var bond: Dictionary = s.bonds[pair]
		if not bond.has("lvl"): bond.lvl = 0
		if not bond.has("n"): bond.n = 0
		if not bond.has("dr"): bond.dr = []

static func settle(c, result: Dictionary) -> void:
	ensure(c.state)
	for pair in result.get("bond_cohesion", {}):
		var ids: PackedStringArray = str(pair).split("|")
		if ids.size() == 2: Legacy.bond_points(c,ids[0],ids[1],int(result.bond_cohesion[pair]))
	var text: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/wave10-choices.json")).records.W10_GRIEF
	for pair in c.state.bonds:
		var bond: Dictionary = c.state.bonds[pair]
		if int(bond.get("lvl",0)) < 1: continue
		var ids: PackedStringArray = str(pair).split("|")
		if ids.size() != 2: continue
		for lost_id in ids:
			var lost: Dictionary = c.soldier(lost_id)
			var survivor: Dictionary = c.soldier(ids[1] if lost_id == ids[0] else ids[0])
			if lost.is_empty() or survivor.is_empty() or survivor.get("status") != "active" or not Progression.is_jedi(survivor): continue
			var cause := "dead" if lost.get("status") == "dead" else "dark" if int(lost.get("dark",0)) >= 8 else ""
			var mark := str(pair) + ":" + lost_id + ":" + cause
			if cause == "" or c.state.bond_losses.has(mark): continue
			c.state.bond_losses.append(mark)
			if not survivor.has("bonus"): survivor.bonus = {}
			survivor.bonus.will = int(survivor.bonus.get("will",0)) - 5
			var line: String = str(text[cause]).replace("{partner}",str(lost.n)).replace("{survivor}",str(survivor.n))
			c.state.story_grief.append({"id":mark,"text":line})
			c.state.news.append("%s: bond loss, will -5." % survivor.n)
