extends Control
## Full-screen promotion presentation. Existing campaign actions remain below the rank grid.
const UI = preload("res://scripts/campaign/ui.gd")
const Classes = preload("res://scripts/class_registry.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Mentor = preload("res://scripts/campaign/mentor17.gd")
const Soldier = preload("res://scripts/effects_soldier.gd")
const Portraits = preload("res://scripts/story14_portraits.gd")
const Badge = preload("res://scripts/campaign/rankup_badge.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var campaign: RefCounted
var unit_id := ""
var scroll: ScrollContainer
var content: VBoxContainer
var confirm: Button
var chosen := ""
var cards: Dictionary = {}
var rank_rows: Dictionary = {}
var new_badge: Control
var flourish: Tween
signal changed
signal closed

func setup(c: RefCounted, id: String) -> void:
    campaign = c
    unit_id = id
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var shade := ColorRect.new()
    shade.color = Color("08151b")
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var safe := Phone.safe_margins(get_viewport_rect().size) if Phone.narrow(Phone.window_size()) else Vector4.ZERO
    margin.add_theme_constant_override("margin_left", 8 + int(safe.x))
    margin.add_theme_constant_override("margin_right", 8 + int(safe.z))
    margin.add_theme_constant_override("margin_top", 6 + int(safe.y))
    margin.add_theme_constant_override("margin_bottom", 6 + int(safe.w))
    add_child(margin)
    var frame := HBoxContainer.new()
    frame.add_theme_constant_override("separation", 8)
    margin.add_child(frame)
    var portrait_panel := UI.panel(Color("11242c"))
    portrait_panel.name = "RankupPortrait"
    var logical_width := Phone.logical_size(Phone.window_size()).x
    portrait_panel.custom_minimum_size.x = 152 if Phone.narrow(Phone.window_size()) and logical_width <= 700 else 185 if Phone.narrow(Phone.window_size()) else 300
    portrait_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    frame.add_child(portrait_panel)
    var portrait_column := VBoxContainer.new()
    portrait_column.add_theme_constant_override("separation", 2)
    portrait_panel.add_child(portrait_column)
    var r: Dictionary = campaign.soldier(unit_id)
    var eyebrow := UI.label("FIELD RECORD  /  PROMOTION", 10, UI.ACCENT)
    portrait_column.add_child(eyebrow)
    var portrait_height: float = minf(270.0, get_viewport_rect().size.y - 130.0)
    var portrait_width: float = minf(246.0, portrait_panel.custom_minimum_size.x - 28.0)
    var image := Portraits.picture(str(r.get("n", "")), Vector2(portrait_width, portrait_height))
    image.name = "UnitPortrait"
    image.texture = Portraits.promotion_texture(str(r.get("n", "")))
    image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    portrait_column.add_child(image)
    var name_label := UI.label(str(r.get("n", "")), 17, UI.GOLD)
    portrait_column.add_child(name_label)
    var path_label := UI.label("Paths: " + _path_names(r.get("classes", [])), 12, UI.TEXT)
    portrait_column.add_child(path_label)
    var right := VBoxContainer.new()
    right.name = "RankupRight"
    right.add_theme_constant_override("separation", 3)
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    frame.add_child(right)
    var header := HBoxContainer.new()
    right.add_child(header)
    var heading := UI.label("RANK UP  /  %s" % Classes.class_data(str(r.cls)).get("name", r.cls), 18, UI.GOLD)
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(heading)
    var back := UI.button("DONE", _close)
    back.custom_minimum_size = Vector2(72, 44)
    header.add_child(back)
    var transition := HBoxContainer.new()
    transition.name = "RankTransition"
    transition.add_theme_constant_override("separation", 5)
    right.add_child(transition)
    var side_name := Classes.side(str(r.cls))
    var level := int(r.get("rank", 1))
    var before := maxi(1, level - 1)
    transition.add_child(_rank_mark(side_name, before, 46))
    var from_label := UI.label(str(Classes.rank_data(side_name, before).get("title", "")), 13, UI.MUTED)
    from_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    transition.add_child(from_label)
    transition.add_child(UI.label("›", 22, UI.GOLD))
    new_badge = _rank_mark(side_name, level, 46)
    transition.add_child(new_badge)
    var to_label := UI.label(str(Classes.rank_data(side_name, level).get("title", "")), 15, UI.GOLD)
    to_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    transition.add_child(to_label)
    var gains := UI.label(_gain_text(r), 12, UI.ACCENT)
    gains.name = "StatGains"
    right.add_child(gains)
    scroll = preload("res://scripts/touch_scroll.gd").new()
    scroll.name = "RankupScroll"
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.follow_focus = false
    right.add_child(scroll)
    content = UI.column(4)
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(content)
    confirm = UI.button("SELECT AN ABILITY", _confirm, false)
    confirm.name = "RankupConfirm"
    confirm.custom_minimum_size.y = 44
    right.add_child(confirm)
    _refresh()
    _flourish()

func _rank_mark(side_name: String, level: int, pixels: float) -> Control:
    var badge := Badge.new()
    badge.side_name = side_name
    badge.level = level
    badge.custom_minimum_size = Vector2(pixels, pixels)
    return badge

func _gain_text(r: Dictionary) -> String:
    var current := Progression.battle_stats(r)
    var prior := r.duplicate(true)
    prior.rank = maxi(1, int(r.rank) - 1)
    var old := Progression.battle_stats(prior)
    var pieces := PackedStringArray()
    for key in ["hp", "aim", "will", "maxF", "deflect"]:
        var delta := int(current.get(key, 0)) - int(old.get(key, 0))
        if delta > 0: pieces.append("%s +%d" % [key.to_upper(), delta])
    return "STAT GAINS   " + ("   /   ".join(pieces) if not pieces.is_empty() else "POWER +%d" % (Classes.power(Classes.side(str(r.cls)), int(r.rank)) - Classes.power(Classes.side(str(r.cls)), int(prior.rank))))

func _flourish() -> void:
    new_badge.modulate.a = 0.0
    new_badge.scale = Vector2(0.7, 0.7)
    new_badge.pivot_offset = new_badge.custom_minimum_size * 0.5
    flourish = create_tween().set_parallel(true)
    flourish.tween_property(new_badge, "modulate:a", 1.0, 0.55)
    flourish.tween_property(new_badge, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed and flourish != null and flourish.is_running():
        flourish.kill()
        new_badge.modulate.a = 1.0
        new_badge.scale = Vector2.ONE

func _add_button(label_text: String, callback: Callable) -> void:
    var button := UI.button(label_text, callback)
    button.custom_minimum_size.y = 44
    content.add_child(button)

func _ability_name(id: String, with_detail: bool = true) -> String:
    for side in Classes.IDS:
        for path in Classes.IDS[side]:
            var definition: Dictionary = Classes.class_data(path).get("abilities", {}).get(id, {})
            if not definition.is_empty():
                var label_text := str(definition.get("promotion_name", definition.get("name", id)))
                if bool(definition.get("once_per_mission", false)) and not label_text.contains("Once per mission"): label_text += " · Once per mission"
                if not with_detail: return label_text
                var detail := str(definition.get("description", "")).replace("_", " ")
                var full := label_text + " · " + detail
                var width := get_viewport_rect().size.x if is_inside_tree() else 844.0
                if detail != "" and UI.font("display").get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x < width - 48:
                    return full
                return label_text
    return id

func _path_names(paths: Array) -> String:
    var names := PackedStringArray()
    for id in paths: names.append(str(Classes.class_data(str(id)).get("name", id)))
    return ", ".join(names)

func _droid_modules(r: Dictionary) -> void:
    if Classes.class_id(str(r.cls)) != "droid": return
    var data: Dictionary = Soldier.module_data()
    var selected := Soldier.selected_modules(r)
    content.add_child(UI.label("DROID MODULES  ·  CHOOSE A SLOT", 14, UI.GOLD))
    for slot in selected.size():
        var current := str(selected[slot])
        content.add_child(UI.label("SLOT %d: %s" % [slot + 1, str(data.choices.get(current, {}).get("name", current))], 14))
        for key in data.choices:
            if key in selected: continue
            _add_button("Slot %d → %s" % [slot + 1, str(data.choices[key].name)], _swap_module.bind(slot, str(key)))

func _ability_data(id: String) -> Dictionary:
    for side in Classes.IDS:
        for path in Classes.IDS[side]:
            var definition: Dictionary = Classes.class_data(path).get("abilities", {}).get(id, {})
            if not definition.is_empty(): return definition
    return {}

func _chain_text(definition: Dictionary) -> String:
    var pieces := PackedStringArray()
    for action in ["consume", "apply"]:
        for entry in definition.get("chain", {}).get(action, []):
            var tag := str(entry.get("tag", ""))
            if tag != "" and not pieces.has(tag): pieces.append(tag)
    return "  ·  ".join(pieces)

func _effect_text(definition: Dictionary) -> String:
    if str(definition.get("description", "")) != "": return str(definition.description)
    var pieces := PackedStringArray()
    if definition.has("shots"): pieces.append("%d weapon shots" % int(definition.shots))
    elif definition.has("status"): pieces.append(str(definition.status).capitalize() + " target")
    else: pieces.append(str(definition.get("effect", "Ability")).capitalize())
    if definition.has("aim_mod"): pieces.append("aim %+d" % int(definition.aim_mod))
    elif definition.has("aim"): pieces.append("aim %+d" % int(definition.aim))
    if definition.has("reaction"): pieces.append("reaction fire")
    return "  ·  ".join(pieces)

func _ability_card(id: String, active: bool, earned: bool = false) -> Control:
    var definition := _ability_data(id)
    var card: Control = Button.new() if active else PanelContainer.new()
    card.name = "Card_" + id
    card.custom_minimum_size.y = 94 if active else 46
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var fill := Color("1d333b") if earned else Color("182b34") if active else Color("142127")
    var border := UI.GOLD if earned else UI.ACCENT if active else UI.BORDER
    if card is Button:
        for state in ["normal", "hover", "pressed", "focus"]: card.add_theme_stylebox_override(state, UI.style(fill, border))
        (card as Button).pressed.connect(_select.bind(id))
    else:
        card.add_theme_stylebox_override("panel", UI.style(fill, border))
        card.modulate.a = 1.0 if earned else 0.55
        card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var stack := VBoxContainer.new()
    stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_theme_constant_override("separation", 0)
    card.add_child(stack)
    if active:
        stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        stack.offset_left = 12
        stack.offset_top = 6
        stack.offset_right = -12
        stack.offset_bottom = -6
    var title := UI.label("◆  " + _ability_name(id, false), 14, UI.GOLD if active or earned else UI.MUTED)
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    title.autowrap_mode = TextServer.AUTOWRAP_OFF
    title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    title.custom_minimum_size.y = 20
    stack.add_child(title)
    var effect := UI.label(_effect_text(definition), 12, UI.TEXT if active or earned else UI.MUTED)
    effect.name = "Effect_" + id
    effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if active else TextServer.AUTOWRAP_OFF
    effect.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING if active else TextServer.OVERRUN_TRIM_ELLIPSIS
    effect.custom_minimum_size.y = 38 if active else 18
    stack.add_child(effect)
    var chain_text := _chain_text(definition)
    if chain_text != "":
        var chains := UI.label(chain_text, 11, UI.ACCENT if active or earned else UI.MUTED)
        chains.mouse_filter = Control.MOUSE_FILTER_IGNORE
        chains.autowrap_mode = TextServer.AUTOWRAP_OFF
        chains.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        chains.custom_minimum_size.y = 16
        stack.add_child(chains)
    if active: cards[id] = card
    return card

func _select(id: String) -> void:
    var r: Dictionary = campaign.soldier(unit_id)
    if int(r.get("pick", 0)) == 0 or not Progression.tree_options(r, int(r.pick)).has(id): return
    chosen = id
    for key in cards:
        var card: Button = cards[key]
        var color := UI.GOLD if key == id else UI.ACCENT
        for state in ["normal", "hover", "pressed", "focus"]:
            card.add_theme_stylebox_override(state, UI.style(Color("28414c") if key == id else Color("182b34"), color))
    confirm.disabled = false
    confirm.text = "CONFIRM  ·  " + _ability_name(id, false)

func _confirm() -> void:
    if chosen == "": return
    var selected := chosen
    chosen = ""
    _pick(selected)

func _refresh() -> void:
    var offset := scroll.scroll_vertical
    UI.clear(content)
    cards.clear()
    rank_rows.clear()
    var r: Dictionary = campaign.soldier(unit_id)
    if r.is_empty(): return
    var side_name := Classes.side(str(r.cls))
    var rank := int(r.get("rank", 1))
    var pending := int(r.get("pick", 0))
    content.add_child(UI.label("ABILITY GRID  /  %s" % str(Classes.rank_data(side_name, rank).get("tier", "")), 12, UI.GOLD))
    for level in range(1, Classes.ranks(side_name).size() + 1):
        var row := VBoxContainer.new()
        row.name = "RankRow_%d" % level
        row.add_theme_constant_override("separation", 2)
        content.add_child(row)
        rank_rows[level] = row
        var title := "%02d   %s" % [level, str(Classes.rank_data(side_name, level).get("title", ""))]
        title += "   /   CHOOSE" if level == pending else "   /   EARNED" if level < pending or pending == 0 and level <= rank else "   /   LOCKED"
        row.add_child(UI.label(title, 11, UI.GOLD if level == pending else UI.ACCENT if level <= rank else UI.MUTED))
        var picks: Array = r.get("picks", [])
        if level == pending:
            var options := Progression.tree_options(r, level)
            var grid := GridContainer.new()
            grid.name = "ChoiceGrid"
            grid.columns = 1 if Phone.narrow(Phone.window_size()) and Phone.logical_size(Phone.window_size()).x < 800 else 2
            grid.add_theme_constant_override("h_separation", 4)
            grid.add_theme_constant_override("v_separation", 4)
            row.add_child(grid)
            for option in options: grid.add_child(_ability_card(str(option), true))
        elif level <= picks.size():
            row.add_child(_ability_card(str(picks[level - 1]), false, true))
        elif level > rank:
            var options := Progression.tree_options(r, level)
            row.add_child(UI.label("◆  " + (" / ".join(options.map(func(item): return _ability_name(str(item), false))) if not options.is_empty() else "Awaiting rank"), 11, UI.MUTED))
    var rank_data: Dictionary = Classes.rank_data(side_name, rank)
    if rank_data.has("aura"): content.add_child(UI.label("Aura ×%d  ·  third action once per mission" % int(rank_data.aura), 12))
    elif rank_data.has("saber_forms"): content.add_child(UI.label("Second Focus pip  ·  saber forms", 12))
    content.add_child(UI.label("BLEND SLOTS  %d / %d" % [r.get("classes", []).size(), Classes.blend_slots(side_name, rank)], 12, UI.ACCENT))
    if side_name == "jedi" and rank <= 2:
        if str(r.get("mentor_id", "")) != "":
            var master: Dictionary = campaign.soldier(str(r.mentor_id))
            content.add_child(UI.label("Mentor: %s  ·  taught %s" % [master.get("n", ""), _ability_name(str(r.get("taught_ability", "")), false)], 12, UI.GOLD))
        else:
            content.add_child(UI.label("CHOOSE A MASTER MENTOR", 12, UI.GOLD))
            for master in campaign.state.roster:
                if master == r or str(master.get("status", "")) != "active" or Classes.side(str(master.get("cls", ""))) != "jedi" or int(master.get("rank", 0)) < 5: continue
                var pupils := 0
                for other in campaign.state.roster:
                    if str(other.get("mentor_id", "")) == str(master.id) and str(other.get("status", "")) == "active" and int(other.get("rank", 0)) <= 2: pupils += 1
                if pupils >= 2: continue
                var signature := str(Classes.class_data(str(master.cls)).get("signature", ""))
                if signature != "": _add_button("Train with %s · %s" % [master.n, _ability_name(signature, false)], _mentor.bind(str(master.id), signature))
    for legacy in r.get("legacies", []):
        content.add_child(UI.label("Legacy: %s · %s at 50%% power" % [legacy.get("mentor", ""), _ability_name(str(legacy.get("ability", "")), false)], 12, UI.GOLD))
    _droid_modules(r)
    if r.get("classes", []).size() < Classes.blend_slots(side_name, rank):
        content.add_child(UI.label("CHOOSE ANOTHER PATH", 12, UI.GOLD))
        for id in Classes.IDS[side_name]:
            if Classes.can_blend(r, str(id)): _add_button("Train %s" % Classes.class_data(str(id)).get("name", id), _blend.bind(str(id)))
    var options := Progression.cross_options(r)
    if not options.is_empty():
        content.add_child(UI.label("CROSS-TRAINED ABILITIES", 12, UI.GOLD))
        for id in options: _add_button(_ability_name(str(id)), _cross_pick.bind(str(id)))
    if options.is_empty() and pending == 0:
        content.add_child(UI.label("Next ability choices unlock with rank and training.", 12, UI.MUTED))
    confirm.disabled = true
    confirm.text = "SELECT AN ABILITY" if pending > 0 else "ALL CURRENT CHOICES COMPLETE"
    if offset > 0: scroll.set_deferred("scroll_vertical", offset)
    elif pending > 0: call_deferred("_focus_pending", pending)

func _focus_pending(level: int) -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    if is_instance_valid(scroll) and rank_rows.has(level) and is_instance_valid(rank_rows[level]):
        scroll.scroll_vertical = maxi(0, int(rank_rows[level].position.y) + 4)

func _save() -> void:
    var flow := get_node_or_null("/root/CampaignFlow")
    if flow != null: flow.save()
    changed.emit()
    _refresh()

func _pick(id: String) -> void:
    if Progression.choose(campaign.soldier(unit_id), id): _save()

func _blend(id: String) -> void:
    if Classes.cross_train(campaign.soldier(unit_id), id): _save()

func _cross_pick(id: String) -> void:
    if Progression.choose_cross(campaign.soldier(unit_id), id): _save()

func _swap_module(slot: int, module_id: String) -> void:
    if Soldier.swap_module(campaign.soldier(unit_id), slot, module_id): _save()

func _mentor(id: String, skill: String) -> void:
    if Mentor.assign(campaign, id, unit_id, skill): _save()

func _close() -> void:
    closed.emit()
    queue_free()
