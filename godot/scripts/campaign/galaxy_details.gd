extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const Intel = preload("res://scripts/campaign/galaxy_intel.gd")
const Art = preload("res://scripts/campaign/galaxy_art.gd")

static func fact(box: VBoxContainer, title: String, value: String, color: Color = UI.TEXT) -> void:
	var pair := UI.column(2); box.add_child(pair)
	pair.add_child(UI.label(title.to_upper(),11,Color("8aa2a5")))
	pair.add_child(UI.label(value,14,color))

static func mission_panel(view) -> void:
	var box: VBoxContainer = view.detail; var c = view.campaign
	if c.state.options.is_empty():
		box.add_child(UI.label("The galaxy is quiet",24,UI.GOLD))
		box.add_child(UI.label("No active missions. Return to the Temple to continue the Order’s story.",16,UI.MUTED)); return
	view.selected = clampi(view.selected,0,c.state.options.size()-1)
	var o: Dictionary = c.state.options[view.selected]; var m: Dictionary = c.story.mission(str(o.mission))
	var planet := Intel.planet_for(m); var region: String = Data.get_table("galaxy","PLANETS")[planet].reg
	var risk := Intel.risk(c,m,o)
	box.add_child(UI.label("%s  /  %s" % ["STORY MISSION" if o.get("story",false) else str(o.get("kind","Mission")).to_upper(),Intel.region_name(region).to_upper()],12,Color("79d3e2")))
	box.add_child(UI.label(str(o.get("n",m.get("n",o.mission))),19 if view.excerpt else 25,UI.TEXT))
	if view.excerpt and not view.phone_more: return
	if not view.excerpt or view.phone_more: box.add_child(UI.label(str(m.get("where",planet)),13,UI.MUTED))
	if m.has("quote") and o.get("story",false): box.add_child(UI.label(str(m.quote),15,UI.MUTED))
	box.add_child(UI.label(str(o.get("text",m.get("brief","Awaiting briefing."))),15))
	if o.has("text") and o.text != m.get("brief",""): box.add_child(UI.label(str(m.get("brief","")),14,UI.MUTED))
	fact(box,"Goal",Intel.goal(m))
	fact(box,"Risk","%s%s %s · strength %d / squad %d" % ["▮".repeat(risk.level),"▯".repeat(4-risk.level),risk.name,risk.enemy,risk.squad],risk.color)
	box.add_child(UI.label("Estimate against your available %d. Gear and roster changes affect risk." % risk.count,12,UI.MUTED))
	fact(box,"Expected",risk.expected+(" · start hidden" if m.get("stealth",false) else "")+(" · front B: %d fewer rank-and-file" % int(o.fewer) if o.has("fewer") else ""))
	if Data.get_table("galaxy","RISK_W").clock.has(m.get("type","")):
		fact(box,"Threat","Rises after par; reinforcements answer the alarm. At 6, the mission fails.",UI.DANGER)
	var reward := "Unknown · build Comms Hub to reveal"
	if int(c.state.wings.comms) > 0 or o.get("story",false):
		reward = Intel.resources(m.get("reward",{}))
		if m.has("bonus"): reward += " · bonus %s (%s)" % [Intel.resources(m.bonus),m.get("bonusTxt","")]
	fact(box,"Reward",reward)
	fact(box,"Deadline",Intel.deadline(o,c.state.options))
	var unrest := Intel.unrest(c,region)
	fact(box,"Region","%s · Unrest %d / 5 · %s" % [Intel.region_name(region),unrest,Data.get_table("galaxy","UNREST_WORD")[unrest]],UI.DANGER if unrest >= 3 else UI.MUTED)
	if o.has("ignore") and not o.ignore.is_empty(): fact(box,"If ignored",Intel.resources(o.ignore),UI.DANGER)
	if o.has("src"): fact(box,"Asked by",str(o.src))
	if o.has("questTxt"): fact(box,"Redemption" if o.get("redeem",false) else "Personal quest",str(o.questTxt),UI.ACCENT)
	if o.has("quest"): fact(box,"Must deploy",str(c.soldier(str(o.quest)).get("n",o.quest)))
	var squad: Array = c.default_squad(o); var names := PackedStringArray()
	for id in squad: names.append(str(c.soldier(str(id)).n))
	fact(box,"Available roster",", ".join(names) if not names.is_empty() else "No fit soldiers")
	var bonuses: PackedStringArray = preload("res://scripts/campaign/temple_rooms.gd").active_descriptions(c.state)
	fact(box,"Temple bonuses active",", ".join(bonuses) if not bonuses.is_empty() else "Build Temple wings to prepare the squad",UI.ACCENT)
	if not c.state.events11.modifier.is_empty(): fact(box,"Galaxy event bonus",Intel.resources(c.state.events11.modifier),UI.GOLD)
	if not c.state.pending_mission.is_empty(): box.add_child(UI.label("Deployment ready. Return to the Temple to resume.",14,UI.GOLD))
	if str(o.get("crisis","")) != "" and c.state.options.size() > 1:
		box.add_child(UI.label("SECOND SQUAD",16,UI.ACCENT))
		box.add_child(UI.label("Assign a strike team. This crisis resolves when you launch a different mission.",14,UI.MUTED))
		for team in c.state.teams:
			box.add_child(UI.button("Assign %s%s" % [team.n,"  ✓" if str(c.state.team_assignments.get(str(o.crisis),"")) == str(team.id) else ""],view._assign_team.bind(str(o.crisis),str(team.id))))

static func events_panel(view) -> void:
	var c = view.campaign; var box: VBoxContainer = view.detail
	var events = preload("res://scripts/campaign/events11_engine.gd")
	var crisis = preload("res://scripts/campaign/crisis11_engine.gd")
	var card: Dictionary = events.pending(c.state)
	if not card.is_empty():
		box.add_child(UI.label("GALAXY EVENT · %s" % card.planet.to_upper(), 14, UI.GOLD))
		box.add_child(UI.label(str(card.title), 21, UI.TEXT))
		box.add_child(UI.label(str(card.text), 14))
		for i in card.choices.size():
			var choice: Array = card.choices[i]
			box.add_child(UI.button("%s · %s" % [choice[0], events.effect_text(choice[1])], view._choose_event.bind(i)))
	for active in c.state.crises11.active:
		var row: Dictionary = crisis.definition(str(active.id))
		box.add_child(UI.label("CRISIS · %s · %d days left" % [row.title, maxi(0, int(active.deadline)-int(c.state.elapsed_days))],16,UI.DANGER))
		box.add_child(UI.label("%s · step %d / %d" % [row.planet,int(active.stage)+1,row.steps.size()],13,UI.MUTED))
		for i in row.steps[int(active.stage)].size():
			var choice: Array = row.steps[int(active.stage)][i]
			box.add_child(UI.button("%s · %s" % [choice[0], events.effect_text(choice[1])],view._choose_crisis.bind(str(active.id),i),int(c.state.elapsed_days) >= int(active.ready_day)))
		if int(c.state.elapsed_days) < int(active.ready_day): box.add_child(UI.label("Next step available tomorrow.",12,UI.MUTED))

static func region_panel(view) -> void:
	var box: VBoxContainer = view.detail; var c = view.campaign; var key: String = view.region
	var row: Array = []
	for r in Data.get_table("galaxy","REGIONS"):
		if r[0] == key: row = r; break
	if row.is_empty(): return
	box.add_child(UI.label("REGIONAL INTELLIGENCE",12,UI.ACCENT))
	if not view.planet.is_empty():
		box.add_child(UI.label(view.planet,25))
		fact(box,"Biome",str(Art.BIOMES.get(view.planet,["Uncharted"])[0]))
		fact(box,"Planet threat","%d / 5" % preload("res://scripts/campaign/events11_engine.gd").threat(c.state,view.planet),UI.DANGER)
	box.add_child(UI.label(str(row[1]),21,UI.ACCENT)); box.add_child(UI.label(str(row[3]),15))
	var unrest := Intel.unrest(c,key); var rules: Dictionary = Data.get_table("galaxy","UNREST")
	fact(box,"Unrest","%s%s %d · %s" % ["▮".repeat(unrest),"▯".repeat(5-unrest),unrest,Data.get_table("galaxy","UNREST_WORD")[unrest]],UI.DANGER if unrest >= 3 else UI.ACCENT)
	fact(box,"Darkness","Order %d / 100 · regional haze reflects Darkness and unrest" % Intel.darkness(c),UI.DANGER)
	var effects := PackedStringArray()
	if unrest >= int(rules.hostile): effects.append("Enemy aim +%d · field ops %d%% here" % [rules.aimAt3,rules.fieldAt3])
	if unrest >= int(rules.favorAt): effects.append("Senate Favor %d / month" % int(rules.favor))
	fact(box,"Regional effects"," · ".join(effects) if not effects.is_empty() else "None yet")
	fact(box,"Raised by","Ignored crises, lost missions, Sith op hits, lapsed field ops")
	fact(box,"Lowered by","Winning missions and field operations here")
	box.add_child(UI.label("WORLDS & SIGNALS",16,UI.ACCENT))
	for title in Data.get_table("galaxy","PLANETS"):
		if Data.get_table("galaxy","PLANETS")[title].reg != key: continue
		box.add_child(UI.button(title,view._planet.bind(title)))
	var count := 0
	for offer in view.map_view.offers:
		if Data.get_table("galaxy","PLANETS")[offer.planet].reg == key:
			count += 1; box.add_child(UI.button("↗ " + str(offer.name),view._select.bind(int(offer.index))))
	if count == 0: box.add_child(UI.label("Nothing needs the Order here right now.",14,UI.MUTED))
	for op in c.sith.operations():
		if op.status not in ["open","team"]: continue
		fact(box,"Dark Event",str(op.n)+" · day %d" % int(op.deadline),UI.DANGER)
		box.add_child(UI.label(str(op.desc),14,UI.MUTED))
	box.add_child(UI.button("Counter a Dark Event →",func(): view.get_node("/root/CampaignFlow").open_intelligence()))
	box.add_child(UI.button("Back to the briefing",view._tab.bind("Briefing")))

static func teams_panel(view) -> void:
	var box: VBoxContainer = view.detail; var c = view.campaign
	box.add_child(UI.label("STRIKE TEAMS  ·  %d / 4" % c.team_capacity(),20,UI.ACCENT))
	box.add_child(UI.label("Assign teams from a crisis briefing. The assigned crisis resolves when another mission launches.",14,UI.MUTED))
	for team in c.state.teams:
		box.add_child(UI.label(str(team.n),18,UI.GOLD))
		var members := PackedStringArray()
		for id in team.get("mem",[]):
			var r: Dictionary = c.soldier(str(id)); members.append("%s · R%d" % [r.get("n",id),int(r.get("rank",1))])
		fact(box,"Members",", ".join(members) if not members.is_empty() else "Unstaffed")
		for crisis in c.state.team_assignments:
			if c.state.team_assignments[crisis] == team.id: fact(box,"Assignment",str(crisis))
	box.add_child(UI.button("Manage teams at the Temple",view._temple))

static func field_panel(view) -> void:
	## Integration: galaxy.gd:_field_panel delegates here; offers use stable IDs.
	var c = view.campaign
	var box: VBoxContainer = view.detail
	var ops = preload("res://scripts/campaign/strat_ops.gd")
	box.add_child(UI.label("FIELD OPERATIONS", 22, UI.ACCENT))
	var offers: Array = c.state.field.list.filter(func(op): return op.st == "open")
	var selected: Dictionary = ops.offer(c, view.field_key)
	if selected.is_empty() and not offers.is_empty(): selected = offers[0]; view.field_key = selected.id
	for op in offers: box.add_child(UI.button("%s · %dd left" % [Data.get_table("galaxy", "FIELD_OPS")[op.k].n, op.exp], view._field.bind(str(op.id))))
	if not selected.is_empty():
		var definition: Dictionary = Data.get_table("galaxy", "FIELD_OPS")[selected.k]
		fact(box, "Destination", str(selected.planet))
		fact(box, "Deadline", "%d days to accept · %d days away" % [selected.exp, definition.days])
		for r in c.state.roster:
			if preload("res://scripts/campaign/strat_roster.gd").ready(r): box.add_child(UI.button(("✓ " if r.id in view.field_team else "+ ") + str(r.n), view._toggle_field.bind(str(r.id))))
		var risk: Dictionary = c.field_risk(selected.id, view.field_team)
		fact(box, "Forecast", "%d%% success · ambush %d%% · wound %d%% · capture on failure %d%%" % [risk.success, risk.ambush, risk.wound, risk.capture])
		fact(box, "Why", " · ".join(risk.why))
		fact(box, "Reward", Intel.resources(risk.rewards))
		fact(box, "Fee", "%d Cr" % int(definition.get("fee", 0)))
		box.add_child(UI.button("SEND TEAM", view._send_field.bind(str(selected.id)), int(risk.success) > 0))
	for op in c.state.field.list:
		if op.st == "team": fact(box, "Away", "%s · returns in %d days" % [Data.get_table("galaxy", "FIELD_OPS")[op.k].n, op.left])
	for entry in c.state.field.log: box.add_child(UI.label(str(entry.get("text", entry.k)), 14))
