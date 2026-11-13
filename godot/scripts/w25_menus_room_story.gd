extends Control
const UI = preload("res://scripts/campaign/ui.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Legacy = preload("res://scripts/campaign/legacy.gd")
const DATA = "res://data/story/room_story25.json"
var flow: Node
var beat: Dictionary
var pair_ids: Array = []

static func flavour(room_id: String) -> String:
	var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if not rows is Array: return ""
	for row in rows:
		if str(row.get("id", "")) == "ambient_flavours":
			return str(row.get("flavours", {}).get(room_id, ""))
	return ""

static func due(campaign: RefCounted, room_id: String) -> Dictionary:
	var room := room_id.to_lower().strip_edges()
	room = {"u2":"memorial", "sp0":"archives", "sp2":"council", "medical_halls":"medical", "kyber_forge":"forge", "comms_hub":"comms", "memorial_vault":"memorial", "council_chamber":"council"}.get(room, room)
	var s: Dictionary = campaign.state
	var seen: Dictionary = s.get("w25_room_seen", {})
	var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if not rows is Array: return {}
	for row in rows:
		if str(row.get("room", "")) != room or seen.has(str(row.id)): continue
		if int(s.get("story", {}).get("done", 0)) < int(row.get("done", 0)): continue
		if row.get("fallen", false) and not s.get("roster", []).any(func(r): return str(r.get("status", "")) == "dead"): continue
		if row.get("pair", false) and s.get("roster", []).filter(func(r): return str(r.get("status", "")) == "active").size() < 2: continue
		return row.duplicate(true)
	return {}

func present(owner: Node, row: Dictionary) -> void:
	flow = owner
	beat = row
	name = "RoomStory25"
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	var s: Dictionary = flow.campaign.state
	var fallen := "their comrade"
	for person in s.roster:
		if str(person.get("status", "")) == "dead": fallen = str(person.get("n", fallen)); break
	var living: Array = s.roster.filter(func(r): return str(r.get("status", "")) == "active")
	if beat.get("pair", false): pair_ids = [str(living[0].id), str(living[1].id)]
	var a := str(living[0].get("n", "Kira Venn")) if not living.is_empty() else "Kira Venn"
	var b := str(living[1].get("n", "Tor Saalen")) if living.size() > 1 else "Tor Saalen"
	if beat.get("pair", false): beat.name = "%s & %s" % [a, b]
	elif beat.get("fallen", false): beat.name = a
	else:
		for person in s.roster:
			if str(person.get("n", "")) == str(beat.name) and str(person.get("status", "")) == "dead":
				beat.text = str(beat.text).replace(str(beat.name).get_slice(" ", 0), a.get_slice(" ", 0))
				beat.name = a
				break
	beat.text = str(beat.text).replace("{fallen}", fallen).replace("{a}", a).replace("{b}", b)
	for choice in beat.choices:
		choice.label = str(choice.label).replace("{fallen}", fallen).replace("{a}", a).replace("{b}", b)
		choice.follow = str(choice.follow).replace("{fallen}", fallen).replace("{a}", a).replace("{b}", b)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.22)
	shade.mouse_filter = MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.style(UI.SURFACE_RAISED, UI.ACCENT))
	card.name = "RoomStoryCard"
	card.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	var safe := Phone.safe_margins(get_viewport_rect().size)
	card.offset_left = 10 + safe.x
	card.offset_right = -10 - safe.z
	card.offset_bottom = -10 - safe.w
	card.offset_top = -minf(370.0, get_viewport_rect().size.y * 0.62)
	if get_viewport_rect().size.x > 900:
		card.anchor_left = 0.5; card.anchor_right = 0.5
		card.offset_left = -330; card.offset_right = 330
	card.mouse_filter = MOUSE_FILTER_STOP
	add_child(card)
	var col := UI.column(6)
	card.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var title := UI.label(str(beat.title), 18, UI.GOLD)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(title)
	var back := UI.button("BACK", _close)
	back.name = "RoomStoryBack"
	head.add_child(back)
	var scroll := preload("res://scripts/touch_scroll.gd").new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	col.add_child(scroll)
	var body := UI.column(5)
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(body)
	body.add_child(UI.label(str(beat.name), 14, UI.ACCENT))
	body.add_child(UI.label(str(beat.text), 15, UI.TEXT))
	for i in beat.choices.size():
		var choice: Dictionary = beat.choices[i]
		var button := UI.button(str(choice.label), _choose.bind(i))
		button.name = "RoomChoice%d" % i
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 48
		body.add_child(button)

func _choose(index: int) -> void:
	var choice: Dictionary = beat.choices[index]
	var s: Dictionary = flow.campaign.state
	if not choice.get("fx", {}).is_empty(): flow.story._apply_effects(s, choice.fx, "")
	if int(choice.get("bond", 0)) > 0 and pair_ids.size() == 2:
		Legacy.bond_points(flow.campaign, str(pair_ids[0]), str(pair_ids[1]), int(choice.bond))
	if not s.has("w25_room_journal"): s.w25_room_journal = []
	s.w25_room_journal.append(str(choice.follow))
	flow.save()
	_close()

func _close() -> void:
	queue_free()
