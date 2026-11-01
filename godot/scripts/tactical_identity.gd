extends RefCounted
const Identity = preload("res://scripts/campaign/strat_identity.gd")
const Shot = preload("res://scripts/shot.gd")
var state: Dictionary

func _init(value: Dictionary) -> void:
	state = value

func soldier(id: String) -> Dictionary:
	for r in state.get("roster",[]):
		if r.id == id: return r
	return {}

func mentor(m, u: Dictionary) -> Dictionary:
	if not u.has("master") or u.master == "": return {}
	for ally in m.living("player"):
		if ally.get("rid","") == u.master and soldier(str(u.master)).get("status","") == "active": return ally
	return {}

func aim(m, u: Dictionary) -> int:
	var master := mentor(m,u)
	if master.is_empty(): return 0
	return int(Identity.proximity(self,str(u.rid),Shot.distance(Shot.pos(u),Shot.pos(master)),true).aim)

func kill(m, u: Dictionary) -> void:
	var master := mentor(m,u)
	if master.is_empty(): return
	master.focus_left = mini(int(master.focus),int(master.focus_left)+int(Identity.proximity(self,str(u.rid),Shot.distance(Shot.pos(u),Shot.pos(master)),true).kill_focus))

func voice(m, u: Dictionary, event: String) -> String:
	if not u.has("rid"): return ""
	var line := Identity.voice_line(self,str(u.rid),event,m.turn)
	if line != "":
		u.quote = line
		m.message("%s: %s" % [u.name,line])
	return line
