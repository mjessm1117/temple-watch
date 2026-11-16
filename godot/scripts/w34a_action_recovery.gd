extends Node
## Release a stale battle input lock once the player phase has been idle for a second.
var hud
var idle_since_ms := -1

func _running(tween: Tween) -> bool:
	return tween != null and tween.is_running()

func _animation_running(g) -> bool:
	if _running(g.action_tween) or _running(g.camera_tween): return true
	if g.cam != null and (_running(g.cam.beat_tween) or _running(g.cam.preview_tween) or _running(g.cam.return_tween24)): return true
	for view in g.views.values():
		if view != null and _running(view.motion): return true
	return false

func _process(_delta: float) -> void:
	if hud == null or not is_instance_valid(hud.overlay): return
	var g = hud.g
	if g == null or g.mission == null or g.mission.phase != "player" or g.mission.result != "":
		idle_since_ms = -1
		return
	if _animation_running(g):
		idle_since_ms = -1
		return
	var stale_cinematic: bool = g.cinematic and (g.cam == null or not g.cam.preview_active)
	if not g.player_attack_pending and not g.playing_enemy_events and not stale_cinematic:
		idle_since_ms = -1
		return
	if idle_since_ms < 0: idle_since_ms = Time.get_ticks_msec()
	if Time.get_ticks_msec() - idle_since_ms < 1000: return
	print("W34A recovered stale action lock: attack=%s enemy=%s cinematic=%s" % [g.player_attack_pending, g.playing_enemy_events, g.cinematic])
	g.player_attack_pending = false
	g.playing_enemy_events = false
	if stale_cinematic: g.cinematic = false
	g.mission.presentation_active = false
	idle_since_ms = -1
	g._sync_input_busy24()
	g._refresh()
