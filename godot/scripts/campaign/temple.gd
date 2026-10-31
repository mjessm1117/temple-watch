extends Control
const Campaign = preload("res://scripts/campaign/state.gd")
const Data = preload("res://scripts/campaign/data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Modules = preload("res://scripts/campaign/modules.gd")
const Legacy = preload("res://scripts/campaign/legacy.gd")
const UI = preload("res://scripts/campaign/ui.gd")
var campaign: Campaign = Campaign.new()
var page := "Command"
var selected_id := "u1"
var page_content: VBoxContainer
var status_label: Label
var notice_label: Label
var nav_buttons: Dictionary = {}

func _ready() -> void:
	campaign = get_node("/root/CampaignFlow").session()
	get_node("/root/CampaignFlow").active = true
	if campaign.soldier(selected_id).is_empty() and not campaign.state.roster.is_empty(): selected_id = str(campaign.state.roster[0].id)
	_build_shell()
	_show_page()
	if get_tree().current_scene == self: get_node("/root/CampaignFlow").temple_story.call_deferred()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var names := ["Command", "Roster", "Research", "Build", "Arsenal", "Teams", "Legacy"]
		if event.keycode >= KEY_1 and event.keycode <= KEY_7:
			page = names[event.keycode - KEY_1]; _show_page(); get_viewport().set_input_as_handled()
		elif event.keycode == KEY_G:
			_open_galaxy(); get_viewport().set_input_as_handled()

func _build_shell() -> void:
	var bg := ColorRect.new(); bg.color = UI.BG; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var outer := UI.column(14); outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 28; outer.offset_top = 22; outer.offset_right = -28; outer.offset_bottom = -22; add_child(outer)
	var head := HBoxContainer.new(); head.add_theme_constant_override("separation", 18); outer.add_child(head)
	var brand := UI.column(1); brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(brand)
	brand.add_child(UI.label("TEMPLE WATCH", 38, UI.ACCENT))
	brand.add_child(UI.label("JEDI TEMPLE  /  COMMAND CONSOLE", 15, UI.MUTED))
	status_label = UI.label("", 18, UI.GOLD)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	status_label.custom_minimum_size.x = 390
	head.add_child(status_label)
	var body := HBoxContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation", 14); outer.add_child(body)
	var nav_panel := UI.panel(); nav_panel.custom_minimum_size.x = 238; body.add_child(nav_panel)
	var nav := UI.column(8); nav_panel.add_child(nav)
	nav.add_child(UI.label("STATIONS", 15, UI.MUTED))
	for name in ["Command", "Roster", "Research", "Build", "Arsenal", "Teams", "Legacy"]:
		var b := UI.button(name, _change_page.bind(name)); nav.add_child(b); nav_buttons[name] = b
	nav.add_spacer(false)
	nav.add_child(UI.button("CODEX", get_node("/root/CampaignFlow").open_codex))
	nav.add_child(UI.button("GALAXY  →", _open_galaxy))
	nav.add_child(UI.button("MAIN MENU", func(): get_node("/root/CampaignFlow").go("menu")))
	nav.add_child(UI.label("1–7 stations  •  G galaxy", 13, UI.MUTED))
	var content_panel := UI.panel(); content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(content_panel)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; content_panel.add_child(scroll)
	page_content = UI.column(13); page_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(page_content)
	var side_panel := UI.panel(); side_panel.custom_minimum_size.x = 305; body.add_child(side_panel)
	var side := UI.column(12); side_panel.add_child(side)
	side.add_child(UI.label("TEMPLE STATUS", 16, UI.ACCENT))
	var res: Dictionary = campaign.state.res
	side.add_child(UI.label("%d  CREDITS" % int(res.credits), 25, UI.GOLD))
	side.add_child(UI.label("%d  INTEL     %d  KYBER" % [int(res.intel), int(res.kyber)], 18))
	side.add_child(UI.label("%d  SENATE FAVOR" % int(res.favor), 18))
	side.add_child(UI.label("%d  RECRUITS" % int(res.recruits), 18))
	side.add_child(UI.label("ORDER DARKNESS  %d / 100" % int(campaign.state.orderDark), 15, UI.DANGER))
	var active := 0; var wounded := 0
	for r in campaign.state.roster:
		if str(r.status) == "active": active += 1
		if int(r.wound) > 0: wounded += 1
	side.add_child(UI.label("%d ACTIVE  /  %d WOUNDED" % [active, wounded], 15, UI.MUTED))
	side.add_spacer(false)
	notice_label = UI.label("Select a station to manage the Order.", 15, UI.MUTED); side.add_child(notice_label)
	outer.add_child(UI.label("TEMPLE WATCH  •  REPUBLIC COMMAND", 13, UI.MUTED))

func _refresh_shell() -> void:
	UI.clear(self)
	nav_buttons.clear()
	_build_shell()
	_show_page()

func _change_page(name: String) -> void:
	page = name; _show_page()

func _show_page() -> void:
	UI.clear(page_content)
	for name in nav_buttons: nav_buttons[name].button_pressed = name == page
	status_label.text = "MONTH %d  ·  DAY %d  ·  WEEK %d" % [int(campaign.state.month), int(campaign.state.day), campaign.week()]
	page_content.add_child(UI.label(page.to_upper(), 30, UI.ACCENT))
	match page:
		"Command": _command()
		"Roster": _roster()
		"Research": _research()
		"Build": _build()
		"Arsenal": _arsenal()
		"Teams": _teams()
		"Legacy": _legacy()

func _card(title: String, description: String = "") -> VBoxContainer:
	var panel := UI.panel(UI.PANEL_ALT); page_content.add_child(panel)
	var box := UI.column(7); panel.add_child(box)
	box.add_child(UI.label(title, 21, UI.GOLD))
	if description != "": box.add_child(UI.label(description, 15, UI.MUTED))
	return box

func _command() -> void:
	_card("THE ORDER ENDURES", "Guide the roster, tend the wounded, fund research and decide where the next squad deploys.")
	var next := "A story mission awaits." if int(campaign.state.step) in [0, 2] else "%d crises await your decision." % campaign.state.options.size()
	var box := _card("NEXT DEPLOYMENT", next)
	box.add_child(UI.button("OPEN GALAXY  →", _open_galaxy))
	box.add_child(UI.button("Rest 7 days", _rest))
	var flow = get_node("/root/CampaignFlow")
	if not campaign.state.pending_mission.is_empty(): box.add_child(UI.button("Resume deployment", func(): flow.go("squad")))
	var era := int(campaign.state.era)
	if era < 3 and (campaign.state.flags.get("boss_or_won" if era == 1 else "boss_ru_won", false) or campaign.state.flags.get("temple_scarred" if era == 1 else "e2_bomb_fired", false)):
		box.add_child(UI.button("Begin the next era →", flow.advance_era))
	if campaign.state.options.is_empty(): _card("CHAPTER COMPLETE", "The Order’s record endures. Tend your roster, explore the Codex, or begin a new campaign from the main menu.")
	if str(campaign.state.build) != "": _card("CONSTRUCTION", "%s completes after the next mission." % Data.get_table("core", "WINGS")[str(campaign.state.build)].n)
	if str(campaign.state.research.cur) != "":
		var project: Dictionary = Data.get_table("research", "RESEARCH")[str(campaign.state.research.cur)]
		_card("RESEARCH IN PROGRESS", "%s  ·  %.0f / %d days" % [project.n, float(campaign.state.research.prog), int(project.days)])
	var news_box := _card("COMMAND LOG")
	if campaign.state.news.is_empty(): news_box.add_child(UI.label("The Temple is ready for orders.", 15, UI.MUTED))
	else:
		for entry in campaign.state.news.slice(-5): news_box.add_child(UI.label(str(entry), 15))

func _roster() -> void:
	page_content.add_child(UI.label("Assign soldiers to train or recover. Wounded soldiers cannot deploy.", 15, UI.MUTED))
	for r in campaign.state.roster:
		var status := "DEAD" if str(r.status) == "dead" else "WOUNDED · %d DAYS" % int(r.wound) if int(r.wound) > 0 else str(r.status).to_upper()
		var box := _card("%s  ·  %s  ·  RANK %d" % [r.n, r.cls, int(r.rank)], "%s   •   %d XP   •   %d KILLS   •   %d MISSIONS" % [status, int(r.xp), int(r.kills), int(r.missions)])
		var stats: Dictionary = Progression.battle_stats(r)
		box.add_child(UI.label("HP %d   AIM %d   WILL %d   MOVE %d" % [int(stats.get("hp", 0)), int(stats.get("aim", 0)), int(stats.get("will", 0)), int(stats.get("mob", 0))], 15))
		if int(r.get("pick", 0)) > 0:
			var row := HBoxContainer.new(); box.add_child(row)
			row.add_child(UI.label("Choose rank %d:  " % int(r.pick), 15, UI.ACCENT))
			for option in Progression.tree_options(r, int(r.pick)):
				var perk: Dictionary = Data.get_table("temple", "PERKS").get(str(option), {})
				row.add_child(UI.button(str(perk.get("name", option)), _pick.bind(str(r.id), str(option))))
		if str(r.status) == "active":
			var row := HBoxContainer.new(); box.add_child(row)
			row.add_child(UI.button("On call", _assign.bind(str(r.id), ""), str(r.assign) != ""))
			row.add_child(UI.button("Recover", _assign.bind(str(r.id), "rest"), int(campaign.state.wings.medical) > 0 and str(r.assign) != "rest"))
			row.add_child(UI.button("Train", _assign.bind(str(r.id), "train"), int(campaign.state.wings.training) > 0 and str(r.assign) != "train"))

func _research() -> void:
	if int(campaign.state.wings.archives) == 0:
		_card("ARCHIVES REQUIRED", "Build Archives to start one research project at a time.")
		return
	var current := str(campaign.state.research.cur)
	if current != "":
		var p: Dictionary = Data.get_table("research", "RESEARCH")[current]
		_card("CURRENT PROJECT", "%s   •   %.0f / %d days" % [p.n, float(campaign.state.research.prog), int(p.days)])
	for branch in Data.get_table("research", "RES_TREE"):
		var box := _card(str(branch.n).to_upper())
		for id in branch.ids:
			var p: Dictionary = Data.get_table("research", "RESEARCH")[str(id)]
			var done := campaign.researched(str(id)); var requirements := []
			for need in p.get("need", []):
				if not campaign.researched(str(need)): requirements.append(str(need))
			var cost: Dictionary = p.cost
			var line := "%s  ·  %d days  ·  %d Cr  +  %d Intel" % [p.n, int(p.days), int(cost.get("credits", 0)), int(cost.get("intel", 0))]
			if done: line += "  ·  COMPLETE"
			elif not requirements.is_empty(): line += "  ·  needs %s" % ", ".join(requirements)
			var row := HBoxContainer.new(); box.add_child(row)
			var label := UI.label(line, 15); label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(label)
			row.add_child(UI.button("Research", _start_research.bind(str(id)), not done and current == "" and requirements.is_empty() and int(p.get("era", 1)) <= int(campaign.state.era) and campaign.can_afford(cost)))

func _build() -> void:
	page_content.add_child(UI.label("One wing upgrade at a time. Construction finishes after the next mission.", 15, UI.MUTED))
	for key in Data.get_table("core", "WINGS"):
		var wing: Dictionary = Data.get_table("core", "WINGS")[key]
		var level := int(campaign.state.wings[key]); var next := level + 1
		var description := str(wing.desc) + "  •  upkeep %d Cr/month" % int(wing.up[level])
		var box := _card("%s  ·  LEVEL %d" % [wing.n, level], description)
		box.add_child(UI.label(str(wing.eff[level]), 15))
		if next < wing.cost.size():
			var cost := int(wing.cost[next]); var req := ""
			if wing.has("req") and next < wing.req.size(): req = str(wing.req[next])
			box.add_child(UI.button("Build level %d  ·  %d Cr%s" % [next, cost, "  ·  needs " + req if not campaign.researched(req) else ""], _build_wing.bind(str(key)), str(campaign.state.build) == "" and campaign.researched(req) and campaign.can_afford({"credits": cost})))
		if level > 0:
			var action: Dictionary = Data.get_table("temple", "MOD_ACTS").get(str(key), {})
			if not action.is_empty():
				Modules.ensure(campaign)
				box.add_child(UI.button("%s  ·  %s" % [action.n, "ready" if Modules.ready(campaign, str(key)) else "cooldown %d missions" % int(campaign.state.modules.cd.get(str(key), 0))], _module_action.bind(str(key)), Modules.ready(campaign, str(key)) and campaign.can_afford(action.cost)))
			var staffer := str(campaign.state.staff.get(str(key), ""))
			if staffer == "":
				for r in campaign.state.roster:
					if str(r.status) == "active" and str(r.assign) == "":
						box.add_child(UI.button("Staff with %s  ·  %s" % [r.n, wing.staff], _assign.bind(str(r.id), "staff:" + str(key))))
						break
			else: box.add_child(UI.label("Staffed by %s" % campaign.soldier(staffer).n, 15, UI.ACCENT))

func _arsenal() -> void:
	var row := HFlowContainer.new(); page_content.add_child(row)
	for r in campaign.state.roster:
		if str(r.status) != "dead": row.add_child(UI.button(str(r.n), _select_unit.bind(str(r.id))))
	var r: Dictionary = campaign.soldier(selected_id)
	if r.is_empty(): return
	var gear: Dictionary = r.gear
	var stats: Dictionary = Gear.battle_stats(campaign, selected_id)
	_card("%s  ·  %s" % [r.n, r.cls], "HP %d  ·  AIM %d  ·  DAMAGE %d–%d  ·  ARMOR %d" % [int(stats.get("hp", 0)), int(stats.get("aim", 0)), int(stats.dmg[0]), int(stats.dmg[1]), int(stats.get("armor", 0))])
	var box := _card("PRIMARY GEAR", "Current: %s" % (Data.get_table("gear", "SABERS")[int(gear.saber)].n if Progression.is_jedi(r) else Data.get_table("gear", "WEAPONS")[int(gear.w)].n))
	if Progression.is_jedi(r):
		var next := int(gear.saber) + 1
		if next < Data.get_table("gear", "SABERS").size():
			var item: Dictionary = Data.get_table("gear", "SABERS")[next]
			box.add_child(UI.button("Craft %s  ·  %d Cr + %d Kyber" % [item.n, int(item.cost), int(item.kyber)], _craft_saber.bind(selected_id)))
	else:
		var next := int(gear.w) + 1
		if next < Data.get_table("gear", "WEAPONS").size():
			var item: Dictionary = Data.get_table("gear", "WEAPONS")[next]
			box.add_child(UI.button("Buy %s  ·  %d Cr" % [item.n, int(item.cost)], _buy_weapon.bind(selected_id)))
	box = _card("ARMOR", "Equipped: %s" % Data.get_table("gear", "ARMOR")[str(gear.armor)].n)
	var armor_row := HFlowContainer.new(); box.add_child(armor_row)
	for key in Data.get_table("gear", "ARMOR"):
		var item: Dictionary = Data.get_table("gear", "ARMOR")[key]
		if str(item.who) in ["any", "jedi" if Progression.is_jedi(r) else "troop"]:
			armor_row.add_child(UI.button("%s · %d Cr" % [item.n, int(item.cost)], _buy_armor.bind(selected_id, str(key)), str(gear.armor) != str(key)))
	for kind in ["s", "w", "a"]:
		if Gear.slots(r, kind) == 0: continue
		var slot_name := "SABER" if kind == "s" else "WEAPON" if kind == "w" else "ARMOR"
		var equipped: Array = gear["smods" if kind == "s" else "mods" if kind == "w" else "amods"]
		box = _card("%s MODULES" % slot_name, "%d / %d slots  ·  click to fit" % [equipped.size(), Gear.slots(r, kind)])
		var module_row := HFlowContainer.new(); box.add_child(module_row)
		var pool: Dictionary = Data.get_table("gear", "SMODS" if kind == "s" else "W_MODS" if kind == "w" else "AMODS")
		for key in pool:
			var item: Dictionary = pool[key]
			module_row.add_child(UI.button("%s  ·  %d Cr" % [item.n, int(item.cost)], _fit_mod.bind(selected_id, kind, str(key)), not equipped.has(key) and equipped.size() < Gear.slots(r, kind)))
		for key in equipped:
			box.add_child(UI.button("Upgrade %s to next Mk" % pool[str(key)].n, _upgrade_mod.bind(selected_id, kind, str(key))))
	box = _card("UTILITY KIT", "Equipped: %s" % Data.get_table("gear", "UTIL")[str(gear.util)].n)
	var util_row := HFlowContainer.new(); box.add_child(util_row)
	for key in Data.get_table("gear", "UTIL"):
		var item: Dictionary = Data.get_table("gear", "UTIL")[key]
		util_row.add_child(UI.button("%s · %d Cr" % [item.n, int(item.cost)], _buy_utility.bind(selected_id, str(key)), str(gear.util) != str(key)))
	if Progression.is_jedi(r):
		box = _card("SABER FORM", "Current: %s" % Data.get_table("gear", "FORMS")[str(gear.form)].n)
		var form_row := HFlowContainer.new(); box.add_child(form_row)
		for key in Data.get_table("gear", "FORMS"):
			var form: Dictionary = Data.get_table("gear", "FORMS")[key]
			form_row.add_child(UI.button(str(form.n), _set_form.bind(selected_id, str(key)), campaign.researched(str(form.get("res", "")))))

func _teams() -> void:
	page_content.add_child(UI.label("Two strike teams at the start. Barracks levels 2 and 3 add one each.", 15, UI.MUTED))
	for team in campaign.state.teams:
		var names := []
		for id in [team.lead] + team.mem:
			var r: Dictionary = campaign.soldier(str(id))
			if not r.is_empty(): names.append(str(r.n))
		_card(str(team.n), "Leader and members: %s" % ", ".join(names))

func _legacy() -> void:
	_card("THE ORDER REMEMBERS", "Soldier deeds, bonds, identities and fallen legends persist in campaign saves. Retire a veteran at rank 4.")
	for r in campaign.state.roster:
		var identity := "%s%s  ·  %s  ·  %d kills  ·  %d missions" % [r.n, " “%s”" % r.nick if str(r.get("nick", "")) != "" else "", r.cls, int(r.kills), int(r.missions)]
		var box := _card(identity, "Rank %d  ·  %s" % [int(r.rank), str(r.status)])
		var nick := LineEdit.new(); nick.placeholder_text = "Enter a nickname and press Enter"; nick.max_length = int(Data.get_table("legacy", "NICK_MAX")); nick.text_submitted.connect(_set_nick.bind(str(r.id))); box.add_child(nick)
		if str(r.status) == "active" and int(r.rank) >= 4: box.add_child(UI.button("Retire to the Order", _retire.bind(str(r.id))))
	var bonds := _card("BONDS", "Comrades gain bond points when they survive missions together.")
	for pair in campaign.state.bonds:
		var bond: Dictionary = campaign.state.bonds[pair]
		if int(bond.lvl) > 0: bonds.add_child(UI.label("%s  ·  level %d / 8" % [str(pair).replace("|", " & "), int(bond.lvl)], 15))
	for legend in campaign.state.legends:
		_card("IN MEMORY · %s" % legend.n, "%s  ·  %s" % [legend.cls, legend.where])

func _open_galaxy() -> void:
	get_node("/root/CampaignFlow").save()
	get_tree().change_scene_to_file("res://scenes/galaxy.tscn")

func _pick(id: String, key: String) -> void:
	if Progression.choose(campaign.soldier(id), key): get_node("/root/CampaignFlow").save(); _show_page()
func _assign(id: String, job: String) -> void:
	if campaign.assign(id, job): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _start_research(id: String) -> void:
	if campaign.start_research(id): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _build_wing(id: String) -> void:
	if campaign.build_wing(id): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _select_unit(id: String) -> void:
	selected_id = id; _show_page()
func _buy_weapon(id: String) -> void:
	if Gear.buy_weapon(campaign, id): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _craft_saber(id: String) -> void:
	if Gear.craft_saber(campaign, id): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _buy_armor(id: String, key: String) -> void:
	if Gear.buy_armor(campaign, id, key): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _fit_mod(id: String, kind: String, key: String) -> void:
	if Gear.fit_module(campaign, id, kind, key): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _upgrade_mod(id: String, kind: String, key: String) -> void:
	if Gear.upgrade_module(campaign, id, kind, key): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _buy_utility(id: String, key: String) -> void:
	if Gear.buy_utility(campaign, id, key): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _set_form(id: String, key: String) -> void:
	if Gear.set_form(campaign, id, key): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _module_action(wing: String) -> void:
	if Modules.use(campaign, wing): get_node("/root/CampaignFlow").save(); _refresh_shell()
func _set_nick(value: String, id: String) -> void:
	if Legacy.set_nickname(campaign, id, value): get_node("/root/CampaignFlow").save(); _show_page()
func _retire(id: String) -> void:
	if Legacy.retire(campaign, id): get_node("/root/CampaignFlow").save(); _refresh_shell()

func _rest() -> void:
	campaign.advance_days(7)
	get_node("/root/CampaignFlow").save()
	_refresh_shell()
