extends RefCounted
## Position a single enemy callout inside the phone safe area and away from its actor.

static func place(game: Node3D, card: Control, actor_id: int = -1) -> void:
	if not is_instance_valid(card) or not is_instance_valid(game): return
	var viewport := game.get_viewport().get_visible_rect().size
	var safe := preload("res://scripts/phone_layout.gd").safe_margins(viewport)
	var portrait := viewport.y > viewport.x
	var width := minf(236.0, viewport.x - safe.x - safe.z - (24.0 if portrait else 220.0))
	width = maxf(140.0, width)
	var height := 76.0
	var top := safe.y + (74.0 if portrait else 54.0)
	var left := safe.x + (8.0 if portrait else 150.0)
	if game.hud_controls != null and game.hud_controls.phone != null:
		var tray: Control = game.hud_controls.phone.ability_tray
		if is_instance_valid(tray): left = maxf(left, tray.get_global_rect().end.x + 8.0)
	var right := viewport.x - safe.z - width - (60.0 if portrait else 60.0)
	var choices := [Rect2(Vector2(left, top), Vector2(width, height)), Rect2(Vector2(right, top), Vector2(width, height))]
	var actor := Vector2(-10000, -10000)
	if actor_id >= 0 and game.views.has(actor_id):
		var view: Node3D = game.views[actor_id]
		if is_instance_valid(view): actor = game.camera.unproject_position(view.global_position + Vector3.UP * 1.0)
	var chosen: Rect2 = choices[1]
	if not chosen.grow(10).has_point(actor): pass
	elif not choices[0].grow(10).has_point(actor): chosen = choices[0]
	else:
		# If both top corners catch the actor, keep the same corner and move below it.
		chosen.position.y = clampf(actor.y + 14.0, top, viewport.y - safe.w - height - 8.0)
		if chosen.grow(4).has_point(actor): chosen.position.y = maxf(safe.y + 4.0, actor.y - height - 14.0)
	card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card.position = chosen.position - card.get_parent().global_position
	card.size = chosen.size

static func show_callout(h, actor_name: String, reason: String, result: String) -> void:
	var actor_id := -1
	for unit in h.g.mission.units:
		if str(unit.get("name", "")).to_lower() == actor_name.to_lower(): actor_id = int(unit.get("id", -1)); break
	var active: PanelContainer = preload("res://scripts/w31e_enemy_card.gd").current(h.g)
	if active != null:
		if actor_id >= 0: active.set_meta("actor_id", actor_id)
		active.get_node("CardLines/ActorIntent").text = actor_name.to_upper()
		active.get_node("CardLines/IntentDescription").text = reason
		active.get_node("CardLines/ActionResult").text = result
		h.enemy_card.hide()
		place(h.g, active, int(active.get_meta("actor_id", -1)))
		return
	h.enemy_card.set_meta("w36_hook", true)
	h.enemy_text.text = actor_name.to_upper() + " · " + reason + ("\n" + result if result != "" else "")
	h.enemy_card.show()
	place(h.g, h.enemy_card, actor_id)

static func update_enemy(h) -> bool:
	if not (h.g.mission.phase == "enemy" or h.g.playing_enemy_events): return false
	h.enemy_was_active = true
	var notes = h.g.get_node_or_null("ThreatNotes11")
	var reveal := ""
	if notes != null and Time.get_ticks_msec() < int(notes.reveal_until):
		if str(notes.reveal_text).begins_with("GROUP "):
			reveal = str(notes.reveal_text).get_slice(" · ", 0)
		if notes.get("panel") != null: notes.panel.modulate.a = 0.0
	var active: PanelContainer = preload("res://scripts/w31e_enemy_card.gd").current(h.g)
	if active != null:
		h.enemy_card.hide()
		active.get_node("CardLines/RevealLine").text = reveal
		place(h.g, active, int(active.get_meta("actor_id", -1)))
	else:
		var reason := str(h.g.phase_banner.text).strip_edges()
		var result := str(h.night.activity.text).strip_edges() if h.night.activity != null else ""
		if reason == "ALERT!" or reason == "": reason = "Enemy is acting"
		if result == reason or result == "ALERT!": result = ""
		if not h.enemy_card.has_meta("w36_hook"):
			h.enemy_text.text = reason + ("\n" + result if result != "" else "")
		if reveal != "" and not h.enemy_text.text.contains(reveal):
			h.enemy_text.text = h.enemy_text.text.get_slice("\nGROUP ", 0) + "\n" + reveal
		h.enemy_card.show()
		place(h.g, h.enemy_card)
	h.g.phase_banner.hide()
	h.night.phase_plate.hide(); h.night.activity_plate.hide()
	h.group_reveal.hide()
	if is_instance_valid(h.alerts): h.alerts.card.hide()
	return true
