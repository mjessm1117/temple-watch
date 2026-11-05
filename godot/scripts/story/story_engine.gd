extends RefCounted
## Campaign-owned story state. The caller serializes `state` as a Dictionary.

const BOND_NEED := [8, 10, 12, 14, 16, 18, 20, 22]
const SOURCES := ["data-story", "data-era2", "data-era3", "data-saga", "data-codex", "data-life", "story-era3", "ui-codex", "tutorial", "wave10-choices", "wave10-talks", "night1-callbacks", "night1-arcs", "wave11-villain", "wave11-scenes"]
const ChoiceScenes = preload("res://scripts/story/story_choices.gd")
const Callbacks = preload("res://scripts/story/callbacks_night1.gd")
const Arcs = preload("res://scripts/story/arc_night1.gd")
const Journal = preload("res://scripts/story/journal_night1.gd")
const Villain11 = preload("res://scripts/story/villain11_arc.gd")
const Scenes11 = preload("res://scripts/story/scenes11_squad.gd")
const Beats14 = preload("res://scripts/story/story14_beats.gd")
var state: Dictionary
var data: Dictionary = {}

func _init(initial_state: Dictionary = {}) -> void:
	state = initial_state
	for source in SOURCES:
		var path := "res://data/story/%s.json" % source
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		data[source] = parsed.get("records", {}) if parsed is Dictionary else {}
	ensure_state(state)

func table(name: String) -> Variant:
	var merged: Variant = null
	for source in SOURCES:
		var value = data[source].get(name)
		if value == null: continue
		if value is Array:
			if merged == null: merged = []
			merged.append_array(value)
		elif value is Dictionary:
			if merged == null: merged = {}
			_merge_deep(merged,value)
		else: merged = value
	return merged if merged != null else {}

func _merge_deep(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.get(key) is Dictionary and source[key] is Dictionary:
			_merge_deep(target[key],source[key])
		else: target[key] = source[key]

func era_data(era: int) -> Dictionary:
	return data[["data-story", "data-era2", "data-era3"][clampi(era, 1, 3)-1]].get("ERA%d" % era, {})

func mission(mission_id: String) -> Dictionary:
	var all_missions: Dictionary = table("BASE_MISSIONS")
	all_missions.merge(table("MISSIONS"), true)
	return all_missions.get(mission_id, {})

func ensure_state(s: Dictionary) -> void:
	if not s.has("era"): s.era = 1
	if not s.has("month"): s.month = 1
	if not s.has("step"): s.step = 0
	if not s.has("flags"): s.flags = {}
	if not s.has("res"): s.res = {"credits":500,"intel":0,"kyber":1,"favor":50,"recruits":2}
	if not s.has("orderDark"): s.orderDark = 0
	if not s.has("story"):
		s.story = {"shadow":6,"done":0,"bby":3660,"seen":[],"loyal":{},"teach":{},"eraDone":0}
	if not s.has("saga"): s.saga = {"t":{},"seen":[],"id":{},"q":[],"talked":""}
	if not s.has("bonds"): s.bonds = {}
	if not s.has("pairs"): s.pairs = {}
	if not s.has("codex"): s.codex = {}
	if not s.has("eras"): s.eras = []
	if not s.has("callback_seen"): s.callback_seen = {}
	if not s.has("callback_rewarded"): s.callback_rewarded = {}
	Arcs.ensure(s)
	Villain11.ensure(s)
	Scenes11.ensure(s)
	if not s.has("roster"):
		s.roster = []
		for key in table("CAST"):
			var name: String = table("CAST")[key].get("n", key)
			var person := {"id":key,"n":name,"status":"active","rank":1,"dark":0,"stress":0}
			s.roster.append(person)
			s.saga.id[key] = key
			s.saga.t[key] = 0
	for key in table("COUNCIL_SEATS"):
		if not s.story.loyal.has(key): s.story.loyal[key] = table("COUNCIL_SEATS")[key].get("loyalty",60)
	for key in table("CAST"):
		if not s.saga.id.has(key):
			for soldier in s.roster:
				if soldier.get("n") == table("CAST")[key].get("n"): s.saga.id[key] = soldier.get("id")
		if not s.saga.t.has(key): s.saga.t[key] = 0

func start_briefing(mission_id: String) -> Dictionary:
	var m := mission(mission_id)
	if m.is_empty(): return {}
	# --- wave10 story ---
	var choices: Array = [{"id":"brief:0","label":"As briefed","text":table("AP_BRIEF").get("d",""),"fx":table("W10_BRIEF_DEFAULT").get("fx",{}),"cost":{}}]
	var approaches: Dictionary = table("APPROACH")
	var options: Array = approaches.get(mission_id, approaches.get("_", []))
	for i in options.size():
		var a: Dictionary = options[i]
		choices.append({"id":"brief:%d" % (i+1),"label":a.get("l",""),"text":a.get("d",""),"fx":a.get("fx",{}),"cost":a.get("cost",{})})
	var scene := {"kind":"briefing","id":mission_id,"title":m.get("n",mission_id),"eyebrow":m.get("where","Mission briefing"),"text":_brief_text(mission_id,m),"goal":m.get("goal",""),"choices":choices}
	Arcs.briefing(state,scene,table("N1_ARCS"))
	Callbacks.apply(state,scene,table("N1_CALLBACKS"))
	Villain11.briefing(state,scene)
	state.last_villain_briefing = scene.duplicate(true) if scene.get("villain_present",false) else {}
	if mission_id == "dock":
		var finale := finale_battle_effects(state)
		scene.finale = finale
		state.finale_effects = finale.map(func(row): return row.fx)
	state.pending = scene
	state.mission_id = mission_id
	state.beat_mission = ""
	unlock_codex(state,"mission",mission_id)
	_unlock_lore_for_mission(state,mission_id)
	return scene

func _brief_text(id: String, m: Dictionary) -> String:
	var result: String = m.get("brief","")
	var variants: Dictionary = table("BRIEF_IF")
	for row in variants.get(id, []):
		if state.flags.get(row[0],false): return result + "\n\n" + str(row[1])
	return result

func start_debrief(result: Dictionary) -> Dictionary:
	var id: String = result.get("mission_id",state.get("mission_id",""))
	var m := mission(id)
	if m.is_empty(): return {}
	var won: bool = result.get("won",false)
	state.story.done = int(state.story.get("done",0)) + 1
	if won and m.has("winFlag"): state.flags[m.winFlag] = true
	if not won and m.has("loseFlag"): state.flags[m.loseFlag] = true
	_apply_mission_flags(state,id,won,result)
	if won and state.get("approach",{}).get("win") is Dictionary:
		_apply_effects(state,state.approach.win,"")
	var squad: Array = result.get("squad",[])
	if squad.size() > 1: record_mission_bonds(state,squad,won,result.get("saved_by",{}))
	var text: String = m.get("win" if won else "lose","")
	var variants: Dictionary = table("DEBRIEF_IF")
	for row in variants.get(id, []):
		if state.flags.get(row[0],false) and row[1 if won else 2] != null:
			text += "\n\n" + str(row[1 if won else 2]); break
	var after_table: Dictionary = table("AFTER")
	var after_key := id + (":win" if won else ":lose")
	if not after_table.has(after_key) and won and not m.get("story",false):
		var generic_key := str(m.get("type","")) + ":a"
		if after_table.has(generic_key) and not state.saga.seen.has("after:"+generic_key) and randf() < 0.5:
			after_key = generic_key
			state.saga.seen.append("after:"+generic_key)
	var aftermath: Dictionary = after_table.get(after_key,{})
	var choices: Array = []
	for i in aftermath.get("ch",[]).size():
		var c: Dictionary = aftermath.ch[i]
		# --- wave10 story ---
		var fx: Dictionary = c.get("fx",{})
		if fx.is_empty(): fx = table("W10_CHOICE_OVERRIDES").get(after_key,{}).get(str(i),{})
		choices.append({"id":"after:%d" % i,"label":c.get("l",""),"text":_saga_text(state,str(c.get("say","")),aftermath.get("who","")),"fx":fx,"need":c.get("need",[])})
	# --- wave10 story ---
	if choices.is_empty(): choices = ChoiceScenes.debrief_choices(table("W10_DEBRIEF"),won)
	var scene := {"kind":"debrief","id":id,"title":aftermath.get("t",m.get("n",id)),"eyebrow":"Mission complete" if won else "Mission lost","text":text + ("\n\n" + _saga_text(state,str(aftermath.get("text","")),aftermath.get("who","")) if not aftermath.is_empty() else ""),"choices":choices,"who":aftermath.get("who","")}
	Callbacks.apply(state,scene,table("N1_CALLBACKS"))
	Villain11.debrief(state,scene)
	scene.text += "\n\n" + Beats14.debrief(state,result)
	state.pending = scene
	return scene

func _apply_mission_flags(s: Dictionary, id: String, won: bool, result: Dictionary) -> void:
	if id == "dock":
		if won: s.flags.boss_or_won = true; s.story.shadow = maxi(0,int(s.story.shadow)-1)
		else: s.flags.temple_scarred = true; s.story.shadow = mini(10,int(s.story.shadow)+1)
		_gain(s,"favor",10 if won else -10)
	elif id == "r_ravine" and won: s.flags.e2_johun_saved = true
	elif id == "r_sixth" and won: s.flags.e2_vell_saved = true
	elif id == "r_seventh":
		s.flags.e2_seventh_done = true
		if won: s.flags.e2_vorr_down = true
	elif id == "r_caves":
		s.flags.e2_caves_done = true
		if won:
			s.flags.e2_bomb_known = true
			if int(result.get("clues",0)) >= 3: s.flags.e2_bane_seen = true
	elif id == "r_bomb":
		var bane: String = result.get("bane","escaped")
		if not ["dead","captured","escaped"].has(bane): bane = "escaped"
		s.flags["e2_bane_"+bane] = true
		if bane == "escaped": s.flags.rule_of_two = true
		s.story.shadow = clampi(int(s.story.shadow)+int(table("BANE")[bane].get("shadow",0)),0,10)
		if won: s.flags.boss_ru_won = true; s.flags.e2_hoth_lives = true
		else: s.flags.e2_bomb_fired = true
		_gain(s,"favor",10 if won else -10)
	elif id == "h_hetzal" and won: s.flags.e3_hetzal_saved = true
	elif id == "h_grove":
		s.flags.e3_grove_done = true
		if won: s.flags.e3_progenitor_down = true
	elif id == "h_valo" and won: s.flags.e3_valo_held = true; s.flags.e3_ro_named = true
	elif id == "h_tempest": s.flags["e3_lourna_" + ("dead" if won and result.get("boss_dead",false) else "escaped")] = true
	elif id == "h_husks" and won:
		s.flags.e3_nameless_known = true
		if int(result.get("clues",0)) >= 3: s.flags.e3_leveler_found = true
	elif id == "h_beacon":
		if won: s.flags.boss_hr_won = true; s.flags.e3_beacon_saved = true; s.flags.e3_ro_down = true
		else: s.flags.e3_beacon_fell = true
		s.story.shadow = clampi(int(s.story.shadow)+(-1 if won else 1),0,10)
		_gain(s,"favor",10 if won else -10)

func advance_era(s: Dictionary) -> bool:
	ensure_state(s)
	Arcs.check_losses(s,table("N1_ARCS"))
	var from: int = int(s.era)
	if from >= 3 or not s.flags.get("boss_or_won" if from == 1 else "boss_ru_won",false) and not s.flags.get("temple_scarred" if from == 1 else "e2_bomb_fired",false): return false
	var next: int = from+1
	var era: Dictionary = era_data(next)
	var carry: Dictionary = era.get("carry",{})
	s.eras.append({"era":from,"shadow":s.story.shadow,"won":s.flags.get("boss_or_won" if from == 1 else "boss_ru_won",false),"epilogues":era_epilogues(s)})
	s.res.credits = roundi(int(s.res.get("credits",0))*float(carry.get("credits",0.3)))+int(carry.get("warChest",200))
	s.res.intel = 0
	s.res.favor = roundi((int(s.res.get("favor",0))+int(carry.get("favorTo",50)))/2.0)
	s.orderDark = roundi(int(s.orderDark)*float(carry.get("orderDark",0.5)))
	s.eraMod = (0 if s.flags.get("boss_or_won",false) else 1) if next == 2 else mini(2,(0 if s.flags.get("boss_or_won",false) else 1)+(0 if s.flags.get("boss_ru_won",false) else 1))
	s.roster = data["data-era%d" % next]["ERA%d_ROSTER" % next].duplicate(true)
	for i in s.roster.size(): s.roster[i].id = "e%d_%d" % [next,i]
	s.era = next; s.month = 1; s.step = 0; s.bonds = {}; s.pairs = {}; s.saga = {"t":{},"seen":[],"id":{},"q":[],"talked":""}
	s.story.done = 0; s.story.bby = int(era.get("bby",0)); s.story.eraDone = 0; s.story.seen = []
	ensure_state(s)
	return true

func next_era_resolution(s: Dictionary) -> Dictionary:
	return Arcs.next_era_resolution(s, table("N1_ARCS"))

func next_temple_talk(s: Dictionary) -> Dictionary:
	ensure_state(s)
	# --- wave10 story ---
	var pair_scene: Dictionary = ChoiceScenes.pair_talk(s,table("W10_PAIR_TALKS"))
	if not pair_scene.is_empty(): return Callbacks.apply(s,pair_scene,table("N1_CALLBACKS"))
	if int(s.era) != 1:
		var later_squad: Dictionary = Scenes11.next(s,table("W11_SCENES"))
		if not later_squad.is_empty(): return later_squad
		var later_talk: Dictionary = ChoiceScenes.temple_talk(s,table("W10_TALKS"))
		return Callbacks.apply(s,later_talk,table("N1_CALLBACKS")) if not later_talk.is_empty() else {}
	var visit_key := "%d|%d" % [int(s.step),int(s.story.done)]
	if s.saga.get("visit","") != visit_key:
		s.saga.visit = visit_key
		s.saga.forced_count = 0
	var ready: Array = []
	for talk in table("TALKS"):
		if s.saga.seen.has(talk.id) or not _cast_active(s,talk.who): continue
		if _when(s,talk.get("when",{}),talk.who): ready.append(talk)
	if ready.is_empty():
		var arc_talk := Arcs.next_talk(s,table("N1_ARCS"))
		if not arc_talk.is_empty(): return arc_talk
		var early_squad: Dictionary = Scenes11.next(s,table("W11_SCENES"))
		if not early_squad.is_empty(): return early_squad
		var extra_talk: Dictionary = ChoiceScenes.temple_talk(s,table("W10_TALKS"))
		return Callbacks.apply(s,extra_talk,table("N1_CALLBACKS")) if not extra_talk.is_empty() else {}
	var selected: Dictionary = {}
	if int(s.saga.get("forced_count",0)) < 2:
		for talk in ready:
			if talk.get("force",false): selected = talk; break
	if selected.is_empty() and s.saga.get("talked","") != visit_key:
		for talk in ready:
			if not talk.get("force",false): selected = talk; break
	if selected.is_empty():
		var arc_talk := Arcs.next_talk(s,table("N1_ARCS"))
		if not arc_talk.is_empty(): return arc_talk
		var extra_talk: Dictionary = ChoiceScenes.temple_talk(s,table("W10_TALKS"))
		return Callbacks.apply(s,extra_talk,table("N1_CALLBACKS")) if not extra_talk.is_empty() else {}
	var choices: Array = []
	for i in selected.ch.size():
		var c: Dictionary = selected.ch[i]
		# --- wave10 story ---
		var fx: Dictionary = c.get("fx",{})
		if fx.is_empty(): fx = table("W10_CHOICE_OVERRIDES").get(selected.id,{}).get(str(i),{})
		choices.append({"id":"talk:%d" % i,"label":c.get("l",""),"text":_saga_text(s,str(c.get("say","")),selected.who),"fx":fx,"need":c.get("need",[])})
	var scene := {"kind":"talk","id":selected.id,"who":selected.who,"name":_cast_name(s,selected.who),"title":selected.t,"eyebrow":"Temple conversation","text":_saga_text(s,selected.text,selected.who),"choices":choices,"forced":selected.get("force",false)}
	Callbacks.apply(s,scene,table("N1_CALLBACKS"))
	s.pending = scene
	return scene

func next_story_event(s: Dictionary) -> Dictionary:
	ensure_state(s)
	# --- wave10 story ---
	var grief: Dictionary = ChoiceScenes.grief(s,table("W10_GRIEF_SCENE"))
	if not grief.is_empty(): return grief
	for event in table("EVENTS"):
		if s.story.seen.has(event.id) or not _when(s,event.trigger,""): continue
		var choices: Array = []
		for i in event.choices.size():
			var c: Dictionary = event.choices[i]
			choices.append({"id":"event:%d" % i,"label":c.get("label",""),"fx":c.get("effects",{})})
		var scene := {"kind":"event","id":event.id,"title":"A Council matter","eyebrow":"Temple · Month %d" % int(s.month),"text":event.text,"choices":choices}
		s.pending = scene
		return scene
	return {}

func next_council_vote(s: Dictionary) -> Dictionary:
	ensure_state(s)
	if not s.has("council_seen"): s.council_seen = []
	for id in table("VOTES"):
		if s.council_seen.has(id): continue
		var vote: Dictionary = table("VOTES")[id]
		var choices: Array = []
		for i in vote.opts.size():
			var option: Dictionary = vote.opts[i]
			choices.append({"id":"vote:%d" % i,"label":option.t,"fx":option.get("fx",{}),"pleases":option.get("pleases",[])})
		var scene := {"kind":"vote","id":id,"title":vote.n,"eyebrow":"Jedi Council","text":vote.text,"choices":choices}
		Callbacks.apply(s,scene,table("N1_CALLBACKS"))
		s.pending = scene
		return scene
	return {}

func finale_battle_effects(s: Dictionary) -> Array:
	var rows: Array = []
	var used: Dictionary = {}
	for finale in table("FINALE"):
		var cast_key: String = finale.get("k","")
		if used.get(cast_key,false) or not _flag_expression(s,str(finale.get("if",{}).get("$js",""))): continue
		var unit_aim: Dictionary = finale.get("fx",{}).get("unitAim",{})
		var available := true
		for key in unit_aim:
			if not _cast_active(s,key): available = false
		if not available: continue
		used[cast_key] = true
		rows.append(finale)
	return rows

func _flag_expression(s: Dictionary, function_text: String) -> bool:
	var expression: String = function_text.get_slice("=>",1).strip_edges()
	if expression.is_empty(): return false
	for or_part in expression.split("||"):
		var all_true := true
		for and_part in or_part.split("&&"):
			var token: String = and_part.strip_edges()
			var negate := token.begins_with("!")
			token = token.trim_prefix("!").trim_prefix("f.")
			var value: bool = s.flags.get(token,false)
			if negate: value = not value
			if not value: all_true = false
		if all_true: return true
	return false

func era_epilogues(s: Dictionary) -> Array:
	var lines: Array = []
	if int(s.era) != 1: return lines
	for cast_key in table("SAGA_EPI"):
		for row in table("SAGA_EPI")[cast_key]:
			var predicate: String = str(row[0].get("$js",""))
			var match_result := false
			if predicate.contains("t<=-2"): match_result = int(s.saga.t.get(cast_key,0)) <= -2
			else: match_result = _flag_expression(s,predicate)
			if match_result:
				lines.append({"who":_cast_name(s,cast_key),"text":row[1]})
				break
	return lines

func next_squad_beat(s: Dictionary, mission_id: String, turn: int, squad: Array) -> Dictionary:
	if turn < 2 or turn > 3 or s.get("beat_mission","") == mission_id: return {}
	if int(s.era) == 1:
		for beat in table("SQUAD_BEATS"):
			if s.saga.seen.has("beat:"+str(beat.id)) or not squad.has(_cast_name(s,beat.who)) or not _when(s,beat.get("when",{}),beat.who): continue
			if beat.has("foe") and not mission(mission_id).get("foes",[]).any(func(f): return f[0] == beat.foe): continue
			var scene := {"kind":"beat","id":beat.id,"mission_id":mission_id,"who":beat.who,"name":_cast_name(s,beat.who),"title":"Comms · Turn %d" % turn,"eyebrow":mission(mission_id).get("n",mission_id),"text":beat.txt,"choices":[{"id":"beat:0","label":beat.a.label,"text":beat.a.txt,"fx":beat.a.get("saga",{}),"battle":beat.a.get("do",{})},{"id":"beat:1","label":beat.b.label,"text":beat.b.txt,"fx":beat.b.get("saga",{}),"battle":beat.b.get("do",{})}]}
			s.pending = scene
			return scene
	# --- wave10 story ---
	var family := str(mission(mission_id).get("type", "investigate"))
	var fallback: Dictionary = ChoiceScenes.mid_scene(s,mission_id,turn,family,table("W10_MID"))
	if not fallback.is_empty(): s.pending = fallback
	return fallback

func apply_choice(s: Dictionary, choice_id: String) -> Dictionary:
	ensure_state(s)
	var scene: Dictionary = s.get("pending",{})
	for c in scene.get("choices",[]):
		if c.get("id") != choice_id: continue
		for who in c.get("need",[]):
			if not _cast_active(s,who): return {"ok":false,"reason":"Required squad member unavailable"}
		for resource in c.get("cost",{}):
			if resource != "orderDark" and int(s.res.get(resource,0)) < int(c.cost[resource]): return {"ok":false,"reason":"Insufficient %s" % resource}
		for resource in c.get("cost",{}):
			if resource == "orderDark": s.orderDark = int(s.orderDark)+int(c.cost[resource])
			else: _gain(s,resource,-int(c.cost[resource]))
		_apply_effects(s,c.get("fx",{}),scene.get("who",""))
		# --- wave10 story ---
		ChoiceScenes.apply(s,scene,c)
		Arcs.chosen(s,scene,choice_id,table("N1_ARCS"))
		Villain11.chosen(s,scene,c)
		Scenes11.chosen(s,scene,c,self)
		if scene.kind == "briefing": s.approach = c.get("battle",c.get("fx",{}))
		if scene.kind == "beat": s.battle_choice = c.get("battle",{})
		if scene.kind == "talk":
			s.saga.seen.append(scene.id)
			if scene.get("forced",false): s.saga.forced_count = int(s.saga.get("forced_count",0))+1
			else: s.saga.talked = "%d|%d" % [int(s.step),int(s.story.done)]
		if scene.kind == "event": s.story.seen.append(scene.id); _unlock_event_lore(s,scene.id)
		if scene.kind == "beat": s.saga.seen.append("beat:"+str(scene.id)); s.beat_mission = scene.get("mission_id","")
		if scene.kind == "vote":
			if not s.has("council_seen"): s.council_seen = []
			s.council_seen.append(scene.id)
			for seat in table("SEATS"):
				var member: Dictionary = table("SEATS")[seat]
				if int(member.get("era",1)) != int(s.era): continue
				var change := 5 if c.get("pleases",[]).has(member.get("stance","")) else -15
				s.story.loyal[seat] = clampi(int(s.story.loyal.get(seat,60))+change,0,100)
		s.erase("pending")
		return {"ok":true,"choice":c,"state":s}
	return {"ok":false,"reason":"Choice unavailable"}

func journal(s: Dictionary) -> Dictionary:
	ensure_state(s)
	var record: Dictionary = Journal.entries(s,table("N1_CALLBACKS"),table("N1_ARCS"))
	Villain11.journal(s,record,table("W11_VILLAIN"))
	Scenes11.journal(s,record,table("W11_SCENES"))
	return record

func next_villain_beat(s: Dictionary) -> Dictionary:
	ensure_state(s)
	return Villain11.next(s,table("W11_VILLAIN"))

func era_interlude(s: Dictionary, from_era: int) -> Dictionary:
	var scene := Journal.interlude(s,from_era,table("N1_CALLBACKS"))
	s.pending = scene
	return scene

func _apply_effects(s: Dictionary, fx: Dictionary, who: String) -> void:
	if fx.has("chance") and randf() >= float(fx.chance):
		_apply_effects(s,fx.get("fail",{}),who)
		return
	for key in fx:
		var value = fx[key]
		match key:
			"flag":
				for flag in value if value is Array else [value]: s.flags[str(flag)] = true
			"t": s.saga.t[who] = clampi(int(s.saga.t.get(who,0))+int(value),-3,3)
			"trust":
				for cast_key in value: s.saga.t[cast_key] = clampi(int(s.saga.t.get(cast_key,0))+int(value[cast_key]),-3,3)
			"shadow": s.story.shadow = clampi(int(s.story.shadow)+int(value),0,10)
			"orderDark": s.orderDark = clampi(int(s.orderDark)+int(value),0,100)
			"loyalty":
				var seat: String = value.get("seat","")
				s.story.loyal[seat] = clampi(int(s.story.loyal.get(seat,60))+int(value.get("n",0)),0,100)
			"dark", "stress", "away", "retire":
				var r := _cast_person(s,who)
				if not r.is_empty():
					if key == "retire": r.status = "retired"; r.role = value
					else: r["wound" if key == "away" else key] = maxi(0,int(r.get("wound" if key == "away" else key,0))+int(value))
				elif key == "stress":
					for person in s.roster:
						if person.get("status") == "active": person.stress = maxi(0,int(person.get("stress",0))+int(value))
			"teach":
				var r := _cast_person(s,who)
				if not r.is_empty(): s.story.teach[r.get("cls","")] = r.n
			"mission", "personal":
				if not s.has("unlocked_missions"): s.unlocked_missions = []
				if not s.unlocked_missions.has(value): s.unlocked_missions.append(value)
			"recruit":
				var recruit: Dictionary = table("STORY_RECRUITS").get(value,{})
				if not recruit.is_empty() and not s.roster.any(func(r): return r.get("n") == recruit.get("n")):
					var person := recruit.duplicate(true); person.id = "u%d" % s.roster.size(); person.status = "active"; s.roster.append(person)
			"chance", "fail": pass
			"unitDark":
				var target: Dictionary = _effect_target(s,value.get("who",""))
				if not target.is_empty(): target.dark = maxi(0,int(target.get("dark",0))+int(value.get("n",0)))
			"wound":
				var target: Dictionary = _effect_target(s,value.get("who",""))
				if not target.is_empty(): target.wound = maxi(int(target.get("wound",0)),int(value.get("turns",0))*15)
			_:
				if s.res.has(key): _gain(s,key,int(value))

func _effect_target(s: Dictionary, who: String) -> Dictionary:
	var active: Array = s.roster.filter(func(r): return r.get("status") == "active")
	if who.begins_with("jedi_"): active = active.filter(func(r): return ["Guardian","Consular","Sentinel","Wayseeker","Defender"].has(r.get("cls","")))
	if active.is_empty(): return {}
	if who == "jedi_highestDark": active.sort_custom(func(a,b): return int(a.get("dark",0)) > int(b.get("dark",0)))
	else: active.sort_custom(func(a,b): return int(a.get("rank",0)) > int(b.get("rank",0)))
	return active[0]

func _gain(s: Dictionary, key: String, amount: int) -> void:
	s.res[key] = maxi(0,int(s.res.get(key,0))+amount)

func _when(s: Dictionary, condition: Dictionary, who: String) -> bool:
	if condition.has("era") and int(condition.era) != int(s.era): return false
	if condition.has("done") and int(s.story.done) < int(condition.done): return false
	if condition.has("act") and _act(s) < int(condition.act): return false
	if condition.has("flag") and not s.flags.get(condition.flag,false): return false
	if condition.has("notFlag") and s.flags.get(condition.notFlag,false): return false
	if condition.has("anyFlag") and not condition.anyFlag.any(func(f): return s.flags.get(f,false)): return false
	if condition.has("need"):
		for cast_key in condition.need:
			if not _cast_active(s,cast_key): return false
	if condition.has("minT") and int(s.saga.t.get(who,0)) < int(condition.minT): return false
	if condition.has("maxT") and int(s.saga.t.get(who,0)) > int(condition.maxT): return false
	if condition.has("type"):
		match condition.type:
			"era_start": return true
			"month": return int(s.month) >= int(condition.get("min",1))
			"after_mission": return int(s.story.done) >= int(condition.get("min",1))
			"act": return _act(s) >= int(condition.get("min",1))
			"flag": return s.flags.get(condition.get("flag",""),false)
			"notFlag": return not s.flags.get(condition.get("flag",""),false)
			"loyal": return int(s.story.loyal.get(condition.get("seat",""),60)) >= int(condition.get("min",0))
			"stat":
				var n: int = int(s.res.get(condition.get("key",""),0))
				var v: int = int(condition.get("val",0))
				return n >= v if condition.get("op") == ">=" else n <= v if condition.get("op") == "<=" else n == v
			"all":
				for child in condition.get("all",[]):
					if not _when(s,child,who): return false
				return true
	return true

func _act(s: Dictionary) -> int:
	var plan: Array = data[["data-story","data-era2","data-era3"][int(s.era)-1]].get("PLAN" if int(s.era)==1 else "PLAN%d" % int(s.era),[])
	var act := 1
	for i in mini(int(s.step),plan.size()):
		if plan[i].has("years"): act += 1
	return act

func _cast_person(s: Dictionary, cast_key: String) -> Dictionary:
	var id = s.saga.id.get(cast_key)
	for r in s.roster:
		if r.get("id") == id: return r
	return {}

func _cast_active(s: Dictionary, cast_key: String) -> bool:
	return _cast_person(s,cast_key).get("status") == "active"

func _cast_name(s: Dictionary, cast_key: String) -> String:
	return _cast_person(s,cast_key).get("n",table("CAST").get(cast_key,{}).get("n",cast_key))

func _saga_text(s: Dictionary, value: String, who: String) -> String:
	var result := value.replace("{n}",_cast_name(s,who))
	for cast_key in table("CAST"): result = result.replace("{"+str(cast_key)+"}",_cast_name(s,cast_key))
	return result

func record_mission_bonds(s: Dictionary, squad: Array, won: bool, saved_by: Dictionary = {}) -> void:
	for i in squad.size():
		for j in range(i+1,squad.size()):
			bond_points(s,str(squad[i]),str(squad[j]),6+(3 if won else 0))
	for saved in saved_by: bond_points(s,str(saved),str(saved_by[saved]),15)
	for padawan in s.pairs:
		var mentor: String = str(s.pairs[padawan])
		if squad.has(padawan) and squad.has(mentor):
			var r := _person_by_id(s,padawan)
			if not r.is_empty(): r.xp = int(r.get("xp",0))+int(table("PAIR").get("xp",8))

func set_pair(s: Dictionary, padawan_id: String, mentor_id: String) -> bool:
	ensure_state(s)
	var padawan := _person_by_id(s,padawan_id)
	var mentor := _person_by_id(s,mentor_id)
	if padawan.get("title") != "Padawan" or mentor.get("status") != "active" or not ["Knight","Master"].has(mentor.get("title")) or int(mentor.get("rank",0)) < int(table("PAIR").get("rank",3)): return false
	s.pairs[padawan_id] = mentor_id
	var key := padawan_id+"|"+mentor_id if padawan_id < mentor_id else mentor_id+"|"+padawan_id
	if int(s.bonds.get(key,{}).get("lvl",0)) < int(table("PAIR").get("bond",2)):
		s.bonds[key] = {"lvl":int(table("PAIR").get("bond",2)),"n":0,"dr":[],"offer":null,"owed":0}
	return true

func _person_by_id(s: Dictionary, id: String) -> Dictionary:
	for r in s.roster:
		if str(r.get("id")) == id: return r
	return {}

func bond_points(s: Dictionary, a: String, b: String, points: int) -> void:
	if a == b or not _has_person(s,a) or not _has_person(s,b): return
	var key := a+"|"+b if a < b else b+"|"+a
	var bond: Dictionary = s.bonds.get(key,{"lvl":0,"n":0,"dr":[],"offer":null,"owed":0})
	bond.n = int(bond.n)+points
	while int(bond.lvl) < 8 and int(bond.n) >= BOND_NEED[int(bond.lvl)]:
		bond.n = int(bond.n)-BOND_NEED[int(bond.lvl)]
		bond.lvl = int(bond.lvl)+1
		bond.owed = int(bond.owed)+1
	if int(bond.lvl) >= 8: bond.n = 0
	s.bonds[key] = bond

func _has_person(s: Dictionary, id: String) -> bool:
	for r in s.roster:
		if str(r.get("id")) == id: return true
	return false

func unlock_codex(s: Dictionary, kind: String, id: String) -> void:
	if not s.codex.has(kind): s.codex[kind] = {}
	s.codex[kind][id] = true

func _unlock_lore_for_mission(s: Dictionary, id: String) -> void:
	var lore: Array = table("MISSION_LORE").get(id,[])
	if lore.size() > 0:
		unlock_codex(s,"planet",str(lore[0]))
		if lore.size() > 1 and lore[1] is Array:
			for character in lore[1]: unlock_codex(s,"character",str(character))

func _unlock_event_lore(s: Dictionary, id: String) -> void:
	for character in table("EVENT_LORE").get(id,[]): unlock_codex(s,"character",str(character))

func codex_entries(s: Dictionary, category: String, unlocked_only: bool = true) -> Array:
	var entries: Array = []
	var category_data: Dictionary = table("CODEX").get(category,{})
	for id in category_data:
		if unlocked_only and not s.codex.get(category,{}).get(id,false): continue
		var entry: Dictionary = category_data[id]
		entries.append({"id":id,"name":entry.get("n",entry.get("name",id.capitalize())),"lore":entry.get("lore",""),"category":category})
	return entries
