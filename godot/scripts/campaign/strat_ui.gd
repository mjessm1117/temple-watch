extends RefCounted
const UI = preload("res://scripts/campaign/ui.gd")
const Data = preload("res://scripts/campaign/data.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const Roster = preload("res://scripts/campaign/strat_roster.gd")
const Ops = preload("res://scripts/campaign/strat_ops.gd")
const Council = preload("res://scripts/campaign/strat_council.gd")
const Identity = preload("res://scripts/campaign/strat_identity.gd")
const Prefs = preload("res://scripts/campaign/strat_preferences.gd")

static func act(view, action: Callable) -> void:
	if action.call():
		view.campaign.ensure_strategy(); view.campaign.refresh_options()
		view.get_node("/root/CampaignFlow").save(); view._refresh_shell()
	else: view.notice_label.text = "Unavailable: check resources, room power, staff and readiness."

static func button(view, box: Control, text: String, action: Callable, enabled: bool = true) -> void:
	box.add_child(UI.button(text, act.bind(view, action), enabled))

static func build(view) -> void:
	var c = view.campaign
	var p := Base.power(c.state)
	var box: VBoxContainer = view._card("TEMPLE WORKS", "Power %d / %d · rooms take 7 work days; free artisans add 50%% speed. Excavation needs a free artisan for 5 days." % [p.used, p.capacity])
	button(view, box, "Power relay +4 · %d Cr" % (80 + 40 * int(c.state.facility.relay)), Base.relay.bind(c))
	if c.state.build != "": box.add_child(UI.label("%s · %.1f work days remaining" % [c.state.build, c.state.facility.build_left], 15, UI.GOLD))
	var grid: VBoxContainer = view._card("BUILD GRID", "Choose a bay to excavate or place a wing. Linked wings share a wall; staff doubles their adjacency bonus.")
	for tier in ["t", "m", "b", "a", "u"]:
		var cells := HBoxContainer.new(); cells.alignment = BoxContainer.ALIGNMENT_CENTER; grid.add_child(cells)
		for slot in Data.get_table("temple", "SLOTS"):
			if slot.tier != tier: continue
			var occupant: String = c.state.slots.get(slot.id, "")
			var label: String = occupant.capitalize() if occupant != "" else "Clear" if c.state.facility.clear.has(slot.id) else "Sealed"
			if c.state.facility.dig.get("slot", "") == slot.id: label = "Digging"
			var cell := UI.button("%s · %s" % [slot.sn, label], func(): view.build_slot = str(slot.id); view._show_page())
			cell.name = "Bay_" + str(slot.id); cell.custom_minimum_size = Vector2(155, 42)
			cell.modulate = UI.ACCENT if view.build_slot == slot.id else Color.WHITE
			cells.add_child(cell)
	for slot in Data.get_table("temple", "SLOTS"):
		if slot.tier == "sp" or slot.id != view.build_slot: continue
		var current: String = c.state.slots.get(slot.id, "")
		var clear: bool = c.state.facility.clear.has(slot.id)
		box = view._card(str(slot.n), "Occupied by " + current if current != "" else "Excavated bay" if clear else "Sealed bay")
		if not clear:
			if c.state.facility.dig.get("slot", "") == slot.id: box.add_child(UI.label("Excavating · %d days left" % c.state.facility.dig.left, 14, UI.GOLD))
			else: button(view, box, "Excavate · %d Cr" % int(Data.get_table("temple", "UNDER_DIG").get(slot.id, 40)), Base.excavate.bind(c, str(slot.id)))
		elif current == "" and int(slot.wing) == 1:
			var row := HFlowContainer.new(); box.add_child(row)
			for wing in c.state.wings:
				if int(c.state.wings[wing]) > 0: continue
				button(view, row, "Place " + str(wing), Base.place.bind(c, str(wing), str(slot.id)))
		elif slot.tier == "u":
			var feature: Dictionary = Data.get_table("temple", "BAY_FEAT").get(c.state.mods.features.get(slot.id, ""), {})
			box.add_child(UI.label(str(feature.get("tip", "Vault open")), 14))
	for wing in c.state.wings:
		var data: Dictionary = Data.get_table("core", "WINGS")[wing]
		var level := int(c.state.wings[wing]); var next := level + 1
		box = view._card("%s · L%d · %s" % [data.n, level, Base.slot_of(c.state, wing)], Base.summary(c.state, wing))
		box.add_child(UI.label(str(data.eff[level]), 14))
		box.add_child(UI.label(Base.production(c.state, wing), 13, UI.ACCENT))
		if next < data.cost.size():
			var req := str(data.get("req", [])[next]) if next < data.get("req", []).size() else ""
			button(view, box, "Build level %d · %d Cr%s" % [next, data.cost[next], " · needs " + req if not c.researched(req) else ""], c.build_wing.bind(str(wing)), c.state.build == "" and c.researched(req))
		var row := HFlowContainer.new(); box.add_child(row)
		for worker in c.state.facility.workers:
			if worker.wing == wing: button(view, row, "Release " + str(worker.n), Base.assign_worker.bind(c, str(worker.id), ""))
			elif worker.role == Base.ROLE[wing] and worker.wing == "" and level > 0: button(view, row, "Assign " + str(worker.n), Base.assign_worker.bind(c, str(worker.id), str(wing)))
		for pair in Data.get_table("temple", "ADJ"):
			if wing not in [pair.a, pair.b]: continue
			var live := Base.operational(c.state, pair.a) and Base.operational(c.state, pair.b) and Base.adjacent(Base.slot_of(c.state, pair.a), Base.slot_of(c.state, pair.b))
			box.add_child(UI.label("%s %s · %s ↔ %s" % ["LINKED" if live else "Link", pair.n, pair.a, pair.b], 13, UI.ACCENT if live else UI.MUTED))
		for line in c.state.facility.log.get(wing, []).slice(0, 2): box.add_child(UI.label(str(line), 12, UI.MUTED))
	box = view._card("TEMPLE STAFF", "Archivists speed research; artisans speed building and projects; healers improve recovery. One staff slot per room level, up to two.")
	for worker in c.state.facility.workers: box.add_child(UI.label("%s · %s · %s" % [worker.n, worker.role, worker.wing if worker.wing != "" else "available"], 14))
	for role in ["archivist", "artisan", "healer"]: button(view, box, "Hire %s · 75 Cr + 1 recruit" % role, Base.hire_staff.bind(c, role))
	box = view._card("SPIRES", "Available from month 4 or era 2. Construction takes 14 days.")
	for id in Data.get_table("temple", "SPIRES"):
		var sp: Dictionary = Data.get_table("temple", "SPIRES")[id]
		box.add_child(UI.label(str(sp.n) + " · " + str(sp.tip), 14))
		button(view, box, "Online" if c.state.mods.spire.get(id, false) else "Build · 350 Cr + 2 Kyber", Base.spire.bind(c, str(id)), not c.state.mods.spire.get(id, false))

static func projects(view) -> void:
	# --- wave10 gear ---
	preload("res://scripts/campaign/research_screen.gd").render(view)
	var c = view.campaign
	var box: VBoxContainer = view._card("FORGE PROJECTS", "One engineering project at a time. Requires a powered Forge; assigned artisans accelerate production.")
	for id in Data.get_table("temple", "PROJECTS"):
		var p: Dictionary = Data.get_table("temple", "PROJECTS")[id]
		box.add_child(UI.label("%s · %d days · %s" % [p.n, p.days, p.desc], 14))
		var progress := ""
		if c.state.strategy.project.get("id", "") == id: progress = " · %.1f days complete" % c.state.strategy.project.progress
		button(view, box, "%s · %s%s" % ["Complete" if id in c.state.strategy.projects else "Start", preload("res://scripts/campaign/galaxy_intel.gd").resources(p.cost), progress], Roster.start_project.bind(c, str(id)), c.state.strategy.project.is_empty() and id not in c.state.strategy.projects)

static func roster(view) -> void:
	var c = view.campaign
	var box: VBoxContainer = view._card("RECRUIT POOL", "Three candidates each month; a Padawan in odd months. Roster capacity %d." % Roster.capacity(c.state))
	for candidate in c.state.cands:
		button(view, box, "Recruit %s · %s · %s" % [candidate.n, candidate.cls, "Padawan · Council-sponsored" if candidate.jedi else "30 Cr + 1 recruit"], Roster.hire.bind(c, str(candidate.id)))
	box = view._card("SQUAD DOCTRINE", "Deploy 5 now, 6 after upgrade I, 7 after upgrade II. Current capacity %d. Upgrade I needs a rank 3 veteran; upgrade II needs rank 4 and Barracks II." % c.squad_capacity())
	button(view, box, "Increase squad capacity · %d Cr" % (100 + 75 * int(c.state.strategy.squad_upgrades)), Roster.upgrade_squad.bind(c), int(c.state.strategy.squad_upgrades) < 2)
	if not c.state.strategy.training.is_empty(): view._card("TRAINING CENTER", "%s · %s · %.1f days remaining" % [c.state.strategy.training.id, c.state.strategy.training.mode, c.state.strategy.training.left])

static func soldier(view, box: VBoxContainer, r: Dictionary) -> void:
	var c = view.campaign
	box.add_child(UI.label("%s · fatigue %d/100 · stress %d · %s" % [Roster.fatigue_status(r), r.fatigue, r.stress, r.assign if r.assign != "" else "on call"], 14, UI.GOLD))
	# --- wave10 story ---
	box.add_child(UI.label("BONDS  " + preload("res://scripts/campaign/bond_overlay.gd").summary(c.state,str(r.id)),13,UI.ACCENT))
	if int(r.fatigue) >= 34: box.add_child(UI.label("Tired: −5 aim, −10 will. Exhausted at 67: cannot deploy. Rest to recover.", 13, UI.MUTED))
	var row := HFlowContainer.new(); box.add_child(row)
	button(view, row, "Retrain · 40 Cr", Roster.train.bind(c, str(r.id), "retrain"), Roster.ready(r))
	button(view, row, "Extra ability slot · 75 Cr", Roster.train.bind(c, str(r.id), "slot"), Roster.ready(r) and int(r.ability_slots) < 2)
	if r.extra_picks.size() < int(r.ability_slots):
		for perk in Roster.extra_options(r): button(view, row, "Learn %s · 50 Cr" % perk, Roster.train.bind(c, str(r.id), "ability", str(perk)))

static func council(view) -> void:
	var c = view.campaign
	var box: VBoxContainer = view._card("COUNCIL EDICTS", "Loyalty %d/100 · adopt up to two policies. One change each month; upkeep paid at month end." % c.state.strategy.loyalty)
	for id in Data.get_table("temple", "EDICTS"):
		var card: Dictionary = Data.get_table("temple", "EDICTS")[id]
		var chosen: bool = id in view.edict_draft
		box.add_child(UI.label(str(card.n) + " · " + str(card.desc), 14))
		box.add_child(UI.button("✓ Selected" if chosen else "Select", func():
			if id in view.edict_draft: view.edict_draft.erase(id)
			elif view.edict_draft.size() < 2: view.edict_draft.append(id)
			view._show_page()))
	button(view, box, "Adopt edicts for this month", Council.edicts.bind(c, view.edict_draft), int(c.state.strategy.edict_month) != int(c.state.month))
	var keys: Array = Data.get_table("temple", "VOTES").keys()
	var id: String = keys[(int(c.state.month) - 1) % keys.size()]
	var vote: Dictionary = Data.get_table("temple", "VOTES")[id]
	box = view._card(str(vote.n), str(vote.text))
	for i in vote.opts.size(): button(view, box, str(vote.opts[i].t) + " · " + preload("res://scripts/campaign/galaxy_intel.gd").resources(vote.opts[i].fx), Council.vote.bind(c, id, i), not c.state.strategy.votes.has("%d:%s" % [c.state.month, id]))
	box = view._card("COUNCIL SUPPORT", "Retired Council members advise one deployment per month. Retired generals advise once. Costs 10 loyalty; +5 squad aim and will.")
	for r in c.state.roster:
		if r.status == "retired" and r.get("role", "") in ["council", "general"]: button(view, box, ("✓ " if r.id in c.state.strategy.support else "Request ") + str(r.n), Council.support.bind(c, str(r.id)))

static func identity(view, box: VBoxContainer, r: Dictionary) -> void:
	var c = view.campaign
	var picker := OptionButton.new(); box.add_child(picker)
	var voices: Dictionary = Data.get_table("legacy", "VOICES")
	var pool := voices.keys().filter(func(key): return voices[key].who == ("jedi" if preload("res://scripts/campaign/progression.gd").is_jedi(r) else "troop"))
	for key in pool: picker.add_item("Voice: " + str(voices[key].n))
	picker.select(pool.find(r.voice)); picker.item_selected.connect(func(i): act(view, Identity.set_voice.bind(c, str(r.id), str(pool[i]))))
	if c.state.pairs.has(r.id): box.add_child(UI.label("Mentor: %s · within 3 tiles: +10 aim; Padawan kill: mentor +1 Focus" % c.soldier(c.state.pairs[r.id]).n, 13, UI.ACCENT))
	var secret: Dictionary = Data.get_table("legacy", "SECRETS")[r.lore.secret]
	if r.lore.revealed: box.add_child(UI.label(str(secret.reveal).replace("{n}", r.n), 14, UI.GOLD))
	else:
		for hint in secret.hints.slice(0, mini(3, r.lore.hints.size())): box.add_child(UI.label(str(hint).replace("{n}", r.n).replace("{p}", "a trusted friend"), 13, UI.MUTED))
	for line in r.quotes.slice(0, 1): box.add_child(UI.label('“%s”' % line, 13, UI.MUTED))
	if r.status == "active" and int(r.rank) >= 4:
		button(view, box, "Retire to Council", preload("res://scripts/campaign/legacy.gd").retire.bind(c, str(r.id), "council"))
		button(view, box, "Retire as regional general", preload("res://scripts/campaign/legacy.gd").retire.bind(c, str(r.id), "general", "core"))

static func field(view) -> void:
	var c = view.campaign
	var box: VBoxContainer = view._card("FIELD OPERATIONS", "Pick 2–3 fit soldiers. Ambushes cause wounds; success rolls separately. Capture rolls only on failure. Tired members reduce success.")
	var row := HFlowContainer.new(); box.add_child(row)
	for r in c.state.roster:
		if not Roster.ready(r): continue
		row.add_child(UI.button(("✓ " if r.id in view.field_team else "+ ") + str(r.n), func():
			if r.id in view.field_team: view.field_team.erase(r.id)
			elif view.field_team.size() < 3: view.field_team.append(r.id)
			view._show_page()))
	for op in c.state.field.list:
		if op.st not in ["open", "team"]: continue
		var d: Dictionary = Data.get_table("galaxy", "FIELD_OPS")[op.k]
		box = view._card(str(d.n) + " · " + str(op.planet), str(d.desc))
		if op.st == "team":
			box.add_child(UI.label("Team away · %d days · %d%% success" % [op.left, op.ch], 14)); continue
		var risk: Dictionary = c.field_risk(op.id, view.field_team)
		box.add_child(UI.label("Expires in %d days · %d days away · fee %d Cr" % [op.exp, d.days, int(d.get("fee", 0))], 14, UI.GOLD))
		box.add_child(UI.label("Success %d%% · ambush %d%% · wound %d%% · capture on failure %d%%" % [risk.success, risk.ambush, risk.wound, risk.capture], 14))
		box.add_child(UI.label("Rewards: %s\n%s" % [preload("res://scripts/campaign/galaxy_intel.gd").resources(risk.rewards), " · ".join(risk.why)], 13, UI.MUTED))
		button(view, box, "Send selected team", c.send_field_op.bind(str(op.id), view.field_team), int(risk.success) > 0)
	for entry in c.state.field.log: view._card("FIELD REPORT", str(entry.get("text", entry.k)))

static func settings(view) -> void:
	var box: VBoxContainer = view._card("PRESENTATION SETTINGS", "Saved on this device.")
	box.add_child(preload("res://scripts/graphics_options.gd").new())
	for row in [["speed","Animation speed",[0.5,1.0,2.0,4.0]], ["cine","Cinematics",[true,false]], ["motion","Reduced motion",[true,false]], ["numbers","Show numbers",[true,false]], ["cb","Colorblind palette",[true,false]], ["tips","Tips",[true,false]]]:
		box.add_child(UI.label(row[1], 16, UI.GOLD))
		var buttons := HFlowContainer.new(); box.add_child(buttons)
		for value in row[2]:
			button(view, buttons, ("✓ " if Prefs.get_value(row[0]) == value else "") + (str(value) + "×" if row[0] == "speed" else "On" if value else "Off"), Prefs.set_value.bind(str(row[0]), value))
