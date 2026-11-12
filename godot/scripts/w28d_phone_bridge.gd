extends RefCounted
## Publishes Godot rectangles; the shell converts them to CSS points.

static func publish(hud) -> void:
	if not OS.has_feature("web") or not is_instance_valid(hud.overlay): return
	var items: Array[Dictionary] = []
	for node in hud.overlay.find_children("*", "Button", true, false):
		var button := node as Button
		if not button.is_visible_in_tree() or button.disabled: continue
		var box := button.get_global_rect()
		var clipped := false
		var parent: Node = button.get_parent()
		while parent != null and parent != hud.overlay:
			if parent is ScrollContainer and not (parent as ScrollContainer).get_global_rect().encloses(box): clipped = true
			parent = parent.get_parent()
		items.append({"name": button.name, "text": button.text, "ability": str(button.get("ability_id")), "clipped": clipped, "x": box.position.x, "y": box.position.y, "w": box.size.x, "h": box.size.y})
	var labels: Array[Dictionary] = []
	for label in [hud.threat_chip, hud.objective_summary, hud.action_name, hud.group_reveal]:
		if not label.is_visible_in_tree() or label.text == "": continue
		var box: Rect2 = label.get_global_rect()
		labels.append({"name": label.name, "x": box.position.x, "y": box.position.y, "w": box.size.x, "h": box.size.y})
	var move_touches := 0
	for button in hud.ability_buttons:
		if button.ability_id == "move": move_touches = int(button.get_meta("w28d_touch_count", 0))
	var data := {"controls": items, "labels": labels, "root": [hud.root_control.size.x, hud.root_control.size.y], "scale": hud.root_control.get_window().content_scale_factor, "safe": [hud.overlay.position.x, hud.overlay.position.y, hud.root_control.size.x - hud.overlay.position.x - hud.overlay.size.x, hud.root_control.size.y - hud.overlay.position.y - hud.overlay.size.y], "selected": hud.g.selected_id, "action": hud.g.action, "moveTouches": move_touches, "turn": hud.g.mission.turn, "phase": hud.g.mission.phase, "missionFamily": str(hud.g.mission.spec.get("family", "")), "objective": hud.objective_summary.text, "endConfirm": hud.end_confirm, "endTurnArmed": hud.g.end_turn_armed, "playingEnemyEvents": hud.g.playing_enemy_events, "cinematic": hud.g.cinematic, "attackPending": hud.g.player_attack_pending, "phaseBannerVisible": hud.g.phase_banner.visible, "phasePlateVisible": hud.night.phase_plate.visible, "inputBusy": hud.g.call("is_input_busy24") if hud.g.has_method("is_input_busy24") else false}
	JavaScriptBridge.eval("window.tw_hud_data = " + JSON.stringify(data))
