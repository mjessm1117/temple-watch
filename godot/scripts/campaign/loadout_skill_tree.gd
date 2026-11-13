extends VBoxContainer
const S = preload("res://scripts/campaign/loadout_style.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Classes = preload("res://scripts/class_registry.gd")
const Roster = preload("res://scripts/campaign/strat_roster.gd")
var host: Control
var soldier_id := ""
var selected_key := ""
var selected_rank := 0
var cards: Dictionary = {}
var columns: Dictionary = {}
var confirm: Button
var comparison: Label
var rows: Dictionary = {}

func setup(owner_screen: Control, id: String) -> void:
	host = owner_screen; soldier_id = id; name = "SkillTree"
	add_theme_constant_override("separation", 5)
	build()

func build() -> void:
	S.clear(self); cards.clear(); columns.clear(); rows.clear(); selected_key = ""; selected_rank = 0
	var r: Dictionary = host.flow.session().soldier(soldier_id)
	var locked := bool(host.flow.session().state.get("skill_picks_locked", false))
	add_child(UI.label("%s  /  SKILL TREE  ·  %s" % [str(r.cls).to_upper(), "PROMOTION PICKS" if locked else "FREE UNTIL DEPLOY"], 15, S.GOLD))
	comparison = UI.label("Tap an open ability to compare · tap again to equip.", 11, S.CYAN)
	comparison.custom_minimum_size.y = 44
	comparison.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(comparison)
	var side_name := "jedi" if Progression.is_jedi(r) else "soldier"
	var class_row: Dictionary = Classes.class_data(str(r.get("cls", "")))
	var specs: Dictionary = class_row.get("tree", {}).get("specs", {})
	var catalog := Classes.ability_catalog()
	var phone := host.size.x < 900
	var ranks: BoxContainer = S.column(7) if phone else HBoxContainer.new()
	ranks.name = "RankColumns"; add_child(ranks)
	var col_width := clampf((maxf(450.0, host.size.x - 215.0) - 14.0) / 3.0, 145.0, 238.0)
	for rank in range(1, Classes.ranks(side_name).size() + 1):
		var column := S.column(4); column.name = "Rank%d" % rank
		if phone: ranks.add_child(column)
		elif rank > 3: add_child(column)
		else:
			column.custom_minimum_size.x = col_width; ranks.add_child(column)
		columns[rank] = column; rows[rank] = column
		var tier := Roster.rank_tier_label({"cls":r.cls, "rank":rank})
		var rank_title := str(Classes.rank_data(side_name, rank).get("tier", ""))
		var tier_text := tier.to_upper() if tier == rank_title else "%s / %s" % [tier.to_upper(), rank_title.to_upper()]
		var picked_id := str(r.get("picks", [])[rank - 1]) if r.get("picks", []).size() >= rank else ""
		var picked_name := str(catalog.get(picked_id, {}).get("name", picked_id)) if picked_id != "" else "None"
		var heading := UI.label("R%d  /  %s  ·  Pick: %s" % [rank, tier_text, picked_name], 11, S.CYAN)
		heading.name = "Tier"; heading.clip_text = false; heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(heading)
		var entries := _rank_entries(r, rank, specs)
		var pair: BoxContainer = HBoxContainer.new() if not phone and rank <= 3 else S.column(4)
		pair.name = "Pair%d" % rank; column.add_child(pair)
		for entry in entries:
			var key := str(entry.id)
			var width := (col_width - 4) * 0.5 if not phone and rank <= 3 else 0.0
			var card := _card(r, rank, key, str(entry.branch), width, locked, catalog)
			pair.add_child(card)
			if not cards.has(key): cards[key] = card
			cards["%d:%s" % [rank, key]] = card
	confirm = host.skill_confirm
	confirm.disabled = true

func _rank_entries(r: Dictionary, rank: int, specs: Dictionary) -> Array:
	var result := []
	if rank <= 2:
		for id in Progression.tree_options(r, rank): result.append({"id":id, "branch":"Foundation" if rank == 1 else "Tactics"})
		return result
	if rank == 3:
		for branch in specs:
			var id := str(specs[branch].get("sig", ""))
			if id in Progression.tree_options(r, rank): result.append({"id":id, "branch":str(specs[branch].get("n", branch))})
		return result
	for branch in specs:
		var sample := r.duplicate(); sample.spec = branch
		for id in Progression.tree_options(sample, rank):
			if not result.any(func(entry): return str(entry.id) == str(id)):
				result.append({"id":id, "branch":str(specs[branch].get("n", branch))})
	return result

func _card(r: Dictionary, rank: int, key: String, branch: String, width: float, locked: bool, catalog: Dictionary) -> Button:
	var ability: Dictionary = catalog.get(key, {})
	var picked: bool = r.get("picks", []).size() >= rank and str(r.get("picks", [])[rank - 1]) == key
	var options: Array = Progression.tree_options(r, rank)
	var available: bool = (not locked or rank > 3) and Progression.set_choice(r.duplicate(true), rank, key, not locked)
	var reason := ""
	if rank > Progression.skill_rank(r): reason = "Reach " + str(Classes.rank_data("jedi" if Progression.is_jedi(r) else "soldier", rank).get("tier", "rank %d" % rank))
	elif key not in options: reason = "Choose %s at rank 3" % branch
	elif rank > r.get("picks", []).size() + 1: reason = "Choose earlier rank"
	elif locked and rank <= 3 and not picked: reason = "Picks locked after deploy"
	elif locked and rank <= r.get("picks", []).size() and not picked: reason = "Already chosen"
	var card := S.button("", _preview.bind(rank, key), available)
	card.name = "Skill_" + key; card.custom_minimum_size = Vector2(maxf(width, 44.0), 136 if width > 0 else 144)
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	UI.style_button(card)
	card.add_theme_stylebox_override("normal", S.box(Color("22434b") if picked else Color("172b32"), S.GOLD if picked else S.EDGE, 4))
	card.add_theme_stylebox_override("disabled", S.box(Color("142025"), Color("344047"), 4))
	card.tooltip_text = str(ability.get("description", "")); card.mouse_filter = Control.MOUSE_FILTER_PASS
	var info := S.column(0)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE; card.add_child(info)
	info.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info.offset_left = 4; info.offset_right = -4; info.offset_top = 2; info.offset_bottom = -2
	var top := HBoxContainer.new(); top.mouse_filter = Control.MOUSE_FILTER_IGNORE; info.add_child(top)
	var icon := TextureRect.new(); icon.name = "SkillIcon"
	icon.texture = S.icon(_icon(ability)); icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(icon)
	var state := UI.label("PICKED" if picked else reason if reason != "" else "OPEN", 10, S.GOLD if picked else S.MUTED if reason != "" else S.GREEN)
	state.name = "LockReason"
	state.clip_text = true; state.autowrap_mode = TextServer.AUTOWRAP_OFF
	state.size_flags_horizontal = SIZE_EXPAND_FILL; state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; top.add_child(state)
	var name_label := UI.label(str(ability.get("name", key)).to_upper() + "  ·  " + branch, 10, S.TEXT)
	name_label.name = "AbilityName"; name_label.clip_text = true; name_label.autowrap_mode = TextServer.AUTOWRAP_OFF; info.add_child(name_label)
	var description := UI.label(str(ability.get("description", _effect_line(ability))), 9, S.TEXT)
	description.name = "Description"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 3
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.custom_minimum_size.y = 46 if width <= 0 else 34
	info.add_child(description)
	var chain: Label = UI.label("", 8, S.GREEN)
	chain.name = "Chain"; chain.mouse_filter = Control.MOUSE_FILTER_IGNORE; info.add_child(chain)
	var chain_data: Dictionary = ability.get("chain", {}) if ability.get("chain", {}) is Dictionary else {}
	var chip_names := []
	for kind in ["apply", "consume"]:
		var tags: Variant = chain_data.get(kind, [])
		if not tags is Array: continue
		for tag in tags:
			if not tag is Dictionary or str(tag.get("tag", "")) == "": continue
			chip_names.append(("+" if kind == "apply" else "↳") + str(tag.tag))
	chain.text = "  ".join(chip_names)
	chain.clip_text = false; chain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chain.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	return card

func _preview(rank: int, key: String) -> void:
	var r: Dictionary = host.flow.session().soldier(soldier_id)
	var locked := bool(host.flow.session().state.get("skill_picks_locked", false))
	if locked and rank <= 3: return
	if not Progression.set_choice(r.duplicate(true), rank, key, not locked): return
	if selected_key == key and selected_rank == rank:
		_confirm(); return
	selected_key = key; selected_rank = rank
	var catalog := Classes.ability_catalog()
	var current: Dictionary = catalog.get(key, {})
	var options: Array = Progression.tree_options(r, rank)
	var other := str(options[0] if str(options[0]) != key else options[1]) if options.size() > 1 else ""
	var rival: Dictionary = catalog.get(other, {})
	comparison.text = "%s  %s %s   VS   %s  %s %s" % [str(current.get("name", key)), _main_number(current), _metric(current), str(rival.get("name", other)), _main_number(rival), _metric(rival)] if other != "" else "%s  ·  %s" % [str(current.get("name", key)), str(current.get("description", _effect_line(current)))]
	confirm.disabled = false
	var selected_card: Control = rows[rank].get_node("Pair%d/Skill_%s" % [rank, key])
	for id in cards:
		cards[id].modulate = S.GOLD if cards[id] == selected_card else Color.WHITE

func _confirm() -> void:
	if selected_key == "": return
	var r: Dictionary = host.flow.session().soldier(soldier_id)
	var chosen_rank := selected_rank
	if chosen_rank == 0: return
	if not Progression.set_choice(r, chosen_rank, selected_key, not bool(host.flow.session().state.get("skill_picks_locked", false))): return
	selected_key = ""; selected_rank = 0; host.flow.save(); host._refresh(); host.arsenal._show_skills()

static func _icon(ability: Dictionary) -> String:
	match str(ability.get("effect", "")):
		"attack", "backup": return "strike" if bool(ability.get("melee", false)) else "shoot"
		"blast", "wave", "area_attack": return "grenade"
		"heal", "mass_heal": return "stabilize"
		"buff", "area_buff", "aura", "guard", "hunker", "hold_line": return "barrier"
		"status": return "mark"
		"displace": return "push"
		"ap", "handoff", "leap", "shadow": return "dash"
		"focus": return "meditate"
	return "sense"

static func _main_number(ability: Dictionary) -> String:
	if ability.is_empty(): return "—"
	if ability.get("damage", null) is Array: return "%d–%d" % [int(ability.damage[0]), int(ability.damage[1])]
	for field in ["heal", "defense", "shots", "damage_mod", "aim", "chance", "distance", "amount", "range", "cooldown"]:
		if ability.has(field) and ability[field] is int or ability.has(field) and ability[field] is float:
			var value := float(ability[field])
			return (str(value) if not is_equal_approx(value, float(int(value))) else str(int(value))) + ("%" if field in ["chance", "aim", "defense"] else "")
	return "+1"

static func _metric(ability: Dictionary) -> String:
	if ability.is_empty(): return ""
	if ability.get("damage", null) is Array: return "damage"
	for field in ["heal", "defense", "shots", "damage_mod", "aim", "chance", "distance", "amount", "range", "cooldown"]:
		if ability.has(field) and ability[field] is int or ability.has(field) and ability[field] is float:
			return {"defense":"defense", "chance":"hit", "distance":"tiles", "amount":"actions", "damage_mod":"damage", "cooldown":"turn cooldown"}.get(field, field)
	return str(ability.get("effect", "effect")).replace("_", " ")

static func _effect_line(ability: Dictionary) -> String:
	var kind := str(ability.get("effect", "skill"))
	match kind:
		"attack": return "weapon hit" if ability.get("damage", null) is String else "target damage"
		"blast", "wave", "area_attack": return "area damage"
		"heal": return "heal one ally"
		"mass_heal": return "heal squad"
		"buff", "area_buff", "aura": return "boost allies"
		"guard", "hunker", "hold_line": return "guard position"
		"status": return str(ability.get("status", "mark")).trim_suffix("ed") + " foe"
		"displace": return "push target"
		"handoff", "ap": return "grant action"
		"shadow", "leap": return "reposition"
		"focus": return "restore Focus"
	return kind.replace("_", " ")
