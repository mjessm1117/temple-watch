extends RefCounted
## One small card per enemy actor, shared by every action in that actor's sequence.

static func current(game: Node3D) -> PanelContainer:
	if not game.has_meta("w31e_actor_card"): return null
	var card: Variant = game.get_meta("w31e_actor_card")
	return card if card is PanelContainer and is_instance_valid(card) else null

static func clear(game: Node3D, immediate: bool = false) -> void:
	var card := current(game)
	if game.has_meta("w31e_actor_card"): game.remove_meta("w31e_actor_card")
	if card == null: return
	card.hide()
	if immediate or not card.is_inside_tree():
		card.queue_free()
		return
	var tween := card.create_tween()
	tween.tween_property(card, "modulate:a", 0.0, 0.12)
	tween.tween_callback(card.queue_free)

static func show_actor(game: Node3D, actor_unit: Dictionary, intent_reason: String) -> PanelContainer:
	if game.cam.skip_requested or int(actor_unit.get("hp", 0)) <= 0: return null
	clear(game)
	var card := PanelContainer.new()
	card.name = "W31EEnemyTurnCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.anchor_left = 0.0; card.anchor_right = 0.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101c2ade")
	style.border_color = Color("e6a66d")
	style.set_border_width_all(1)
	style.set_content_margin_all(5)
	card.add_theme_stylebox_override("panel", style)
	var lines := VBoxContainer.new()
	lines.name = "CardLines"
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(lines)
	var title := Label.new()
	title.name = "ActorIntent"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 13)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_color_override("font_color", Color("ffe2ac"))
	var name := str(actor_unit.get("name", "ENEMY")).to_upper()
	var role := str(actor_unit.get("class_name", "")).to_upper()
	var reason := intent_reason.strip_edges()
	title.text = "%s%s — %s" % [name, " · " + role if role != "" and not name.contains(role) else "", reason.to_upper().get_slice(" ", 0) if reason != "" else "ACTING"]
	lines.add_child(title)
	var detail := Label.new()
	detail.name = "IntentDescription"
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail.add_theme_font_size_override("font_size", 12)
	detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail.add_theme_color_override("font_color", Color("d4e1e9"))
	detail.text = reason if reason != "" else "Taking action"
	lines.add_child(detail)
	var result := Label.new()
	result.name = "ActionResult"
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	result.add_theme_font_size_override("font_size", 12)
	result.add_theme_color_override("font_color", Color("9ef6b3"))
	lines.add_child(result)
	var reveal := Label.new()
	reveal.name = "RevealLine"
	reveal.add_theme_font_size_override("font_size", 11)
	reveal.add_theme_color_override("font_color", Color("f2d99a"))
	reveal.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lines.add_child(reveal)
	card.set_meta("actor_id", int(actor_unit.get("id", -1)))
	game.overlay.add_child(card)
	game.set_meta("w31e_actor_card", card)
	preload("res://scripts/w36hud_enemy_card.gd").place(game, card, int(actor_unit.get("id", -1)))
	return card

static func result(game: Node3D, actor_id: int, word: String) -> void:
	var card := current(game)
	if card == null or int(card.get_meta("actor_id", -1)) != actor_id: return
	if game.cam.skip_requested:
		clear(game, true)
		return
	var label: Label = card.get_node("CardLines/ActionResult")
	label.text = word
