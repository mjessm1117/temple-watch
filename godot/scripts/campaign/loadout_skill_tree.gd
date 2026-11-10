extends VBoxContainer
const S = preload("res://scripts/campaign/loadout_style.gd")
const UI = preload("res://scripts/campaign/ui.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Classes = preload("res://scripts/class_registry.gd")
var host: Control
var soldier_id := ""
var selected_key := ""
var cards: Dictionary = {}
var columns: Dictionary = {}
var confirm: Button
var comparison: Label

func setup(owner_screen: Control, id: String) -> void:
	host = owner_screen; soldier_id = id; name = "SkillTree"
	add_theme_constant_override("separation", 5)
	build()

func build() -> void:
	S.clear(self); cards.clear(); columns.clear()
	var r: Dictionary = host.flow.session().soldier(soldier_id)
	var locked := bool(host.flow.session().state.get("skill_picks_locked", false))
	add_child(UI.label("%s  /  SKILL TREE  ·  %s" % [str(r.cls).to_upper(), "LOCKED" if locked else "FREE UNTIL DEPLOY"], 15, S.GOLD))
	comparison = UI.label("Tap a node to compare · tap again to equip.", 11, S.CYAN)
	comparison.clip_text = true; add_child(comparison)
	var ranks := HBoxContainer.new(); ranks.name = "RankColumns"
	ranks.add_theme_constant_override("separation", 7); add_child(ranks)
	var available := maxf(450.0, host.size.x - 215.0)
	var col_width := clampf((available - 14.0) / 3.0, 145.0, 238.0)
	for rank in range(1, 4):
		var column := S.column(3); column.name = "Rank%d" % rank
		column.custom_minimum_size.x = col_width; ranks.add_child(column); columns[rank] = column
		var rank_label := UI.label("R%d  /  %s" % [rank, "SPECIALIZATION" if rank == 3 else "FOUNDATION" if rank == 1 else "TACTICS"], 10, S.CYAN)
		column.add_child(rank_label)
		var pair := HBoxContainer.new(); pair.name = "Pair%d" % rank
		pair.add_theme_constant_override("separation", 4); column.add_child(pair)
		var options: Array = Progression.tree_options(r, rank)
		for key in options:
			var other := str(options[0] if str(options[0]) != str(key) else options[1]) if options.size() > 1 else ""
			var card := _card(r, rank, str(key), other, (col_width - 4) * 0.5, locked)
			pair.add_child(card); cards[str(key)] = card
	var later := S.column(3); later.name = "LaterRanks"; later.custom_minimum_size.x = col_width
	ranks.add_child(later)
	later.add_child(UI.label("R4+  /  FUTURE RANKS", 10, S.MUTED))
	var future := S.panel(); future.custom_minimum_size.y = 138
	future.add_theme_stylebox_override("panel", S.box(Color("142025"), Color("344047"), 5)); later.add_child(future)
	var future_label := UI.label("◇  LOCKED\nEarn ranks in battle to reveal the next branches.", 11, S.MUTED)
	future_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; future.add_child(future_label)
	confirm = host.skill_confirm
	confirm.disabled = true

func _card(r: Dictionary, rank: int, key: String, other: String, width: float, locked: bool) -> Button:
	var ability: Dictionary = Classes.ability_catalog().get(key, {})
	var other_ability: Dictionary = Classes.ability_catalog().get(other, {})
	var picked: bool = key in r.get("picks", [])
	var available: bool = rank <= Progression.skill_rank(r) and rank <= r.get("picks", []).size() + 1 and not locked
	var card := S.button("", _preview.bind(rank, key), available)
	card.name = "Skill_" + key; card.custom_minimum_size = Vector2(width, 136)
	UI.style_button(card)
	card.add_theme_stylebox_override("normal", S.box(Color("22434b") if picked else Color("172b32"), S.GOLD if picked else S.EDGE, 4))
	card.add_theme_stylebox_override("disabled", S.box(Color("142025"), Color("344047"), 4))
	card.tooltip_text = str(ability.get("description", ""))
	var info := S.column(0); info.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info.offset_left = 4; info.offset_right = -4; info.offset_top = 2; info.offset_bottom = -2
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE; card.add_child(info)
	var top := HBoxContainer.new(); info.add_child(top)
	var icon := TextureRect.new(); icon.name = "SkillIcon"
	icon.texture = S.icon(_icon(ability)); icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(icon)
	var state := UI.label("✓" if picked else "○", 12, S.GOLD if picked else S.MUTED)
	state.size_flags_horizontal = SIZE_EXPAND_FILL; state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; top.add_child(state)
	var name_label := UI.label(str(ability.get("name", key)).to_upper(), 10, S.TEXT)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.y = 20; info.add_child(name_label)
	var number := UI.label(_main_number(ability), 19, S.GOLD if picked else S.CYAN)
	number.name = "Number"; info.add_child(number)
	var effect := UI.label(_effect_line(ability), 8, S.TEXT)
	effect.clip_text = true; info.add_child(effect)
	var compare := UI.label("VS " + _main_number(other_ability) + " " + _short_metric(other_ability) if other != "" else "FOUNDATION", 8, S.MUTED)
	compare.name = "Compare"; compare.clip_text = true; info.add_child(compare)
	var chain := UI.label(_chain_line(ability, r, rank), 8, S.GREEN)
	chain.name = "Chain"; chain.clip_text = true; info.add_child(chain)
	return card

func _preview(rank: int, key: String) -> void:
	var r: Dictionary = host.flow.session().soldier(soldier_id)
	if bool(host.flow.session().state.get("skill_picks_locked", false)): return
	if rank > r.get("picks", []).size() + 1: return
	if selected_key == key:
		_confirm(); return
	selected_key = key
	var catalog := Classes.ability_catalog()
	var current: Dictionary = catalog.get(key, {})
	var options: Array = Progression.tree_options(r, rank)
	var other := str(options[0] if str(options[0]) != key else options[1]) if options.size() > 1 else ""
	var rival: Dictionary = catalog.get(other, {})
	comparison.text = "%s  %s %s   VS   %s  %s %s" % [str(current.get("name", key)), _main_number(current), _metric(current), str(rival.get("name", other)), _main_number(rival), _metric(rival)]
	confirm.disabled = false
	for id in cards:
		cards[id].modulate = S.GOLD if id == selected_key else Color.WHITE

func _confirm() -> void:
	if selected_key == "": return
	var r: Dictionary = host.flow.session().soldier(soldier_id)
	var chosen_rank := 0
	for rank in range(1, 4):
		if selected_key in Progression.tree_options(r, rank): chosen_rank = rank; break
	if chosen_rank == 0: return
	if not Progression.set_choice(r, chosen_rank, selected_key, not bool(host.flow.session().state.get("skill_picks_locked", false))): return
	selected_key = ""; host.flow.save(); host._refresh(); host.arsenal._show_skills()

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

static func _short_metric(ability: Dictionary) -> String:
	return {"defense":"DEF", "damage":"DMG", "chance":"HIT", "aim":"AIM", "heal":"HEAL", "shots":"SHOTS", "damage_mod":"DMG"}.get(_metric(ability), _metric(ability).to_upper().left(4))

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

static func _chain_line(ability: Dictionary, r: Dictionary, rank: int) -> String:
	var chain: Dictionary = ability.get("chain", {})
	var applied: Array = chain.get("apply", [])
	if not applied.is_empty(): return "→ " + str(applied[0].get("tag", "COMBO"))
	if rank < 3:
		var next := Progression.tree_options(r, rank + 1)
		if not next.is_empty():
			var next_name := str(Classes.ability_catalog().get(str(next[0]), {}).get("name", "R%d" % (rank + 1)))
			return "→ " + str(next_name.split(" ")[-1]).to_upper()
	return "LINK → squad follow-up"
