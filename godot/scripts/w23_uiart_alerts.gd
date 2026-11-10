extends Control
## One non-blocking queue for portrait turn, reveal, activity, and radio notices.
const UI = preload("res://scripts/campaign/ui.gd")
var game
var night
var card: PanelContainer
var heading: Label
var message: Label
var queue: Array[Dictionary] = []
var remaining := 0.0
var phase_seen := false
var banner_seen := false
var activity_text := ""
var threat_reveal_until := 0
var threat_note_text := ""

func setup(g, night_hud, parent: Control) -> void:
	game = g
	night = night_hud
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(self)
	card = UI.panel(UI.SURFACE_RAISED)
	card.name = "BattleAlertCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.visible = false
	add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	heading = UI.label("", UI.TYPE_CAPTION, UI.GOLD)
	heading.custom_minimum_size.x = 72
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(heading)
	message = UI.label("", UI.TYPE_CAPTION, UI.TEXT)
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message.max_lines_visible = 4
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(message)
	set_safe_area(parent.size)

func set_safe_area(area: Vector2) -> void:
	if not is_instance_valid(card): return
	card.position = Vector2(12, 48)
	card.size = Vector2(maxf(180, area.x - 24), 82)

func queue_radio(speaker: String, words: String, priority: int = 1) -> void:
	_enqueue("RADIO · " + speaker.to_upper(), words, 2.8 if priority >= 2 else 2.2)

func _enqueue(title: String, words: String, duration: float) -> void:
	if words.is_empty(): return
	queue.append({"title": title, "words": words, "duration": duration})
	if queue.size() > 8: queue.pop_front()

func _process(delta: float) -> void:
	if not is_instance_valid(night) or not is_instance_valid(game): return
	var notes = game.get_node_or_null("ThreatNotes11")
	if notes != null and notes.get("panel") != null:
		notes.panel.modulate.a = 0.0
		notes.panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if int(notes.reveal_until) > threat_reveal_until and str(notes.reveal_text) != "":
			threat_reveal_until = int(notes.reveal_until)
			threat_note_text = str(notes.label.text)
			_enqueue("CONTACT", threat_note_text, 2.0)
		elif notes.panel.visible and str(notes.label.text) != threat_note_text:
			threat_note_text = str(notes.label.text)
			_enqueue("TACTICS", threat_note_text, 2.5)
	if night.phase_plate.visible:
		if not phase_seen: _enqueue("BATTLE", night.phase_text.text, 1.6)
		phase_seen = true
		night.phase_plate.visible = false
	else:
		phase_seen = false
	if game.phase_banner.visible:
		if not banner_seen: _enqueue("TURN", game.phase_banner.text, 1.3)
		banner_seen = true
		game.phase_banner.visible = false
	else:
		banner_seen = false
	if night.activity_plate.visible:
		if night.activity.text != activity_text:
			activity_text = night.activity.text
			_enqueue("ACTIVITY", activity_text, 1.5)
		night.activity_plate.visible = false
	var aiming: bool = game.get("hud_controls") != null and game.hud_controls.aim_ui != null and game.hud_controls.aim_ui.panel.visible
	if aiming:
		card.visible = false
		return
	remaining -= delta
	if remaining > 0: return
	if queue.is_empty():
		card.visible = false
		return
	var item: Dictionary = queue.pop_front()
	heading.text = str(item.title)
	message.text = str(item.words)
	remaining = float(item.duration)
	card.visible = true
