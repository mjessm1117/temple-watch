extends RefCounted
const Classes = preload("res://scripts/class_registry.gd")

static func assign(c, master_id: String, padawan_id: String, taught_ability: String) -> bool:
	var master: Dictionary = c.soldier(master_id)
	var pupil: Dictionary = c.soldier(padawan_id)
	if master.is_empty() or pupil.is_empty() or master_id == padawan_id: return false
	if str(master.get("status", "")) != "active" or str(pupil.get("status", "")) != "active": return false
	if Classes.side(str(master.get("cls", ""))) != "jedi" or Classes.side(str(pupil.get("cls", ""))) != "jedi": return false
	if int(master.get("rank", 0)) < 5 or int(pupil.get("rank", 0)) > 2: return false
	if str(pupil.get("mentor_id", "")) != "": return false
	var pupils := 0
	for other in c.state.roster:
		if str(other.get("mentor_id", "")) == master_id and str(other.get("status", "")) == "active" and int(other.get("rank", 0)) <= 2: pupils += 1
	if pupils >= 2: return false
	if not Classes.class_data(str(master.cls)).get("abilities", {}).has(taught_ability): return false
	pupil.mentor_id = master_id
	pupil.taught_ability = taught_ability
	if not master.has("trained_padawans"): master.trained_padawans = []
	if padawan_id not in master.trained_padawans: master.trained_padawans.append(padawan_id)
	return true

static func xp_multiplier(c, pupil: Dictionary) -> float:
	var mentor: Dictionary = c.soldier(str(pupil.get("mentor_id", "")))
	return 1.5 if not mentor.is_empty() and str(mentor.get("status", "")) == "active" and int(pupil.get("rank", 0)) <= 2 else 1.0

static func on_death(c, master: Dictionary, where: String) -> void:
	if Classes.side(str(master.get("cls", ""))) != "jedi": return
	var taught: Array = master.get("trained_padawans", [])
	for id in taught:
		var pupil: Dictionary = c.soldier(str(id))
		if pupil.is_empty(): continue
		pupil.erase("mentor_id")
		pupil.erase("taught_ability")
		if not pupil.has("legacies"): pupil.legacies = []
		pupil.legacies.append({"mentor":str(master.get("n", "")), "ability":str(Classes.class_data(str(master.cls)).get("signature", "")), "power":0.5})
		c.state.news.append("%s carries %s's legacy." % [pupil.n, master.n])
	if not c.state.has("mentor_memorials"): c.state.mentor_memorials = []
	c.state.mentor_memorials.append({"id":str(master.id), "name":str(master.n), "where":where, "trained":taught.size()})
	if int(master.get("rank", 0)) >= 8 and taught.is_empty(): c.gain("orderDark", 2)
