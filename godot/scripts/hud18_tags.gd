extends Control
## World anchored tags and chain feedback. All game state stays in the mission.
const Shot = preload("res://scripts/shot.gd")
const Icon = preload("res://scripts/hud18_icon.gd")
const EXPLAIN := {"MARKED":"Allies gain +20 aim and crit chance against this target.", "EXPOSED":"This target loses cover.", "STAGGERED":"No reactions or overwatch; defense drops by 15.", "LIFTED":"Held by the Force; cannot act and takes extra damage.", "PINNED":"Cannot move and has reduced aim.", "IONIZED":"Shields down; droids stunned; tech and blasts hit harder.", "BURNING":"Takes damage each turn and can spread in explosions.", "TAUNTED":"Must attack the unit that taunted it.", "INSPIRED":"Gains aim and cannot panic.", "SHIELDED":"A shield absorbs incoming damage.", "ATTUNED":"The next Force ability is free and reaches farther.", "READY":"Gains one extra overwatch shot."}
var g
var icons: Dictionary = {}
var snapshots: Dictionary = {}
var callouts: Array[Dictionary] = []
var overflow_positions: Dictionary = {}
var explanation: PanelContainer
var explanation_text: Label

static func shown(tags: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key in tags: keys.append(str(key))
	keys.sort()
	var visible := keys.slice(0, 3)
	if keys.size() > 3: visible.append("+%d" % (keys.size() - 3))
	return visible

static func chain_text(tag: String, entry: Variant) -> String:
	var bonus := "combo"
	if entry is Dictionary:
		for effect in entry.get("bonus", []):
			if effect is Dictionary:
				if effect.has("aim"): bonus = "+%d aim" % int(effect.aim)
				elif effect.has("amount"): bonus = "+%d %s" % [int(effect.amount), str(effect.get("type", "effect"))]
	return "%s → %s" % [tag, bonus]

func setup(game) -> void:
	g = game
	name = "ComboTagOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	explanation = PanelContainer.new(); explanation.name = "TagExplanation"
	explanation.visible = false; explanation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	explanation.custom_minimum_size = Vector2(235, 58)
	var style := StyleBoxFlat.new(); style.bg_color = Color("0d1c29f2"); style.border_color = Color("e4c988")
	style.set_border_width_all(1); style.set_content_margin_all(7)
	explanation.add_theme_stylebox_override("panel", style); add_child(explanation)
	explanation_text = Label.new(); explanation_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation_text.add_theme_font_size_override("font_size", 13)
	explanation_text.mouse_filter = Control.MOUSE_FILTER_IGNORE; explanation.add_child(explanation_text)

func _input(event: InputEvent) -> void:
	if not explanation.visible: return
	if event is InputEventScreenTouch and event.pressed or event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point: Vector2 = event.position
		if not explanation.get_global_rect().has_point(point): explanation.hide()

func _process(_delta: float) -> void:
	if g == null or g.mission == null: return
	var now := Time.get_ticks_msec() / 1000.0
	for unit in g.mission.units:
		var id := int(unit.get("id", -1))
		var held: Dictionary = unit.get("combo_tags", {})
		if snapshots.has(id):
			for tag in snapshots[id]:
				if not held.has(tag) and str(g.mission.phase) == "player":
					callouts.append({"id": id, "text": _consume_text(str(tag)), "until": now + 1.2, "start": now})
		snapshots[id] = held.duplicate()
		var visible: bool = int(unit.get("hp", 0)) > 0 and (str(unit.get("side", "")) != "enemy" or bool(unit.get("awake", false)) or bool(unit.get("spotted", false)))
		_sync_icons(id, unit, held if visible else {})
	for i in range(callouts.size() - 1, -1, -1):
		if now >= float(callouts[i].until): callouts.remove_at(i)
	queue_redraw()

func _consume_text(tag: String) -> String:
	var def: Dictionary = g.mission.abilities.get(g.action, {})
	for entry in def.get("chain", {}).get("consume", []):
		if (str(entry.get("tag", "")) if entry is Dictionary else str(entry)) == tag:
			return chain_text(tag, entry)
	return "%s → combo" % tag

func _sync_icons(id: int, unit: Dictionary, held: Dictionary) -> void:
	var tags := shown(held)
	var old: Array = icons.get(id, [])
	if old.size() != tags.size() or _different(old, tags):
		for node in old: node.queue_free()
		old = []
		for tag in tags:
			var icon: Button = Icon.new(); icon.name = "Tag_%d_%s" % [id, tag]
			icon.tag = tag; add_child(icon)
			icon.pressed.connect(_explain.bind(tag, icon))
			old.append(icon)
		icons[id] = old
	if old.is_empty(): return
	var point := _screen(unit, 1.85)
	var on_screen := point.x >= 0.0 and point.x <= size.x and point.y >= 0.0 and point.y <= size.y
	var x := clampf(point.x - old.size() * 22.0, 0.0, maxf(0.0, size.x - old.size() * 44.0))
	var bottom_limit := size.y - (96.0 if g.hud_controls.phone != null else 8.0) - 44.0
	var y := minf(point.y - 52.0, bottom_limit)
	on_screen = on_screen and y >= (48.0 if g.hud_controls.phone != null else 4.0)
	for index in old.size():
		old[index].visible = on_screen
		old[index].position = Vector2(x + index * 44.0, y)

func _different(old: Array, tags: Array[String]) -> bool:
	for i in tags.size():
		if old[i].tag != tags[i]: return true
	return false

func _screen(unit: Dictionary, height: float) -> Vector2:
	var p := Shot.pos(unit)
	return g.camera.unproject_position(Vector3(float(unit.x), Shot.elevation(g.mission, p) * 0.7 + height, float(unit.y)))

func _explain(tag: String, icon: Button) -> void:
	if tag.begins_with("+"):
		var id := int(icon.name.get_slice("_", 1))
		var names: Array[String] = []
		for key in g.mission.unit_by_id(id).get("combo_tags", {}): names.append(str(key))
		names.sort()
		var hidden: int = maxi(1, names.size() - 3)
		var index: int = int(overflow_positions.get(id, 0)) % hidden
		overflow_positions[id] = index + 1
		var selected: String = names[3 + index]
		explanation_text.text = "%s — %s" % [selected, EXPLAIN.get(selected, "Combo status.")]
	else: explanation_text.text = tag + " — " + EXPLAIN.get(tag, "Combo status.")
	explanation.position = Vector2(clampf(icon.position.x, 4.0, maxf(4.0, size.x - 245.0)), clampf(icon.position.y - 67.0, 108.0, size.y - 70.0))
	explanation.size = Vector2(235, 58)
	explanation.show()

func _draw() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for callout in callouts:
		var unit: Dictionary = g.mission.unit_by_id(int(callout.id))
		if unit.is_empty(): continue
		var progress: float = clampf((now - float(callout.start)) / 1.2, 0.0, 1.0)
		var at := _screen(unit, 3.65) - Vector2(0, progress * 20.0)
		var badges: Array = icons.get(int(callout.id), [])
		if not badges.is_empty() and badges[0].visible:
			at = Vector2(badges[0].position.x + badges.size() * 22.0, badges[0].position.y - 5.0 - progress * 20.0)
		var text_value: String = callout.text
		var width := ThemeDB.fallback_font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		at.x = clampf(at.x, width * 0.5 + 8.0, size.x - width * 0.5 - 8.0)
		var color := Color("ffe39b"); color.a = minf(1.0, (1.0 - progress) * 4.0)
		draw_rect(Rect2(at - Vector2(width * 0.5 + 7.0, 18), Vector2(width + 14.0, 25)), Color(0.04, 0.10, 0.15, color.a * 0.85), true)
		draw_string(ThemeDB.fallback_font, at - Vector2(width * 0.5, 0), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
