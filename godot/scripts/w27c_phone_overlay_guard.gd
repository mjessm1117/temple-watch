extends Node
## Runs after the phone alert layer so its older notices cannot cover aim or enemy actions.
var hud

func _process(_delta: float) -> void:
	if hud == null or not is_instance_valid(hud.overlay): return
	var g = hud.g
	if g == null or g.mission == null: return
	if g.hud_controls != null and g.hud_controls.preview_card26 != null:
		g.hud_controls.preview_card26.hide()
	var enemy_active: bool = g.mission.phase == "enemy" or g.playing_enemy_events
	var aiming: bool = hud.odds_plate.visible and g.action in ["shoot", "strike"]
	if is_instance_valid(hud.alerts):
		if enemy_active or aiming:
			hud.alerts.set_process(false)
			hud.alerts.card.hide()
			hud.alerts.queue.clear()
		else:
			hud.alerts.set_process(true)
	if enemy_active or aiming:
		hud.night.phase_plate.hide()
		hud.night.activity_plate.hide()
		hud.feedback.busy.hide()
		if g.has_meta("story_comms"):
			var comms = g.get_meta("story_comms")
			if comms != null and is_instance_valid(comms.card) and comms.card.visible:
				if enemy_active and hud.deferred_story_comms.is_empty():
					hud.deferred_story_comms = {"speaker": str(comms.who_label.text), "words": str(comms.text_label.text)}
				comms.card.hide()
	if enemy_active:
		var reason := str(g.phase_banner.text).strip_edges()
		var outcome := str(hud.night.activity.text).strip_edges()
		if reason.is_empty(): reason = "Enemy is acting"
		if outcome == reason: outcome = ""
		hud.enemy_text.text = reason + ("\n" + outcome if outcome != "" else "")
		hud.enemy_card.show()
		g.phase_banner.hide()
		hud.group_reveal.hide()
	elif aiming:
		hud.enemy_card.hide()
	elif g.has_method("impact_budget27") and g.player_attack_pending:
		var impact_budget: Dictionary = g.call("impact_budget27")
		if int(impact_budget.get("draws_per_beat", 0)) > 0: hud.feedback.busy.hide()
