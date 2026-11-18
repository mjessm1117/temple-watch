extends Node
## Runs after the legacy overlay guard to keep its old enemy notice suppressed.
var hud

func _process(_delta: float) -> void:
	if hud == null or not is_instance_valid(hud.overlay): return
	if hud.g == null or hud.g.mission == null: return
	if hud.g.mission.phase == "enemy" or hud.g.playing_enemy_events:
		preload("res://scripts/w36hud_enemy_card.gd").update_enemy(hud)
