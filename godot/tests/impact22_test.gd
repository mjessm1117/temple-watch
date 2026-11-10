extends SceneTree

const Effects = preload("res://scripts/fx.gd")
const Audio = preload("res://scripts/audio.gd")
const UnitView = preload("res://scripts/unit_view.gd")
const Prefs = preload("res://scripts/campaign/strat_preferences.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func argument(key: String, fallback: String = "") -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with(key + "="): return value.get_slice("=", 1)
	return fallback

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	if argument("--capture-only") != "":
		await capture_only()
		return
	var prior_speed: Variant = Prefs.get_value("speed")
	var prior_motion: Variant = Prefs.get_value("motion")
	Prefs.set_value("speed", 1.0)
	Prefs.set_value("motion", false)
	var sound := Audio.new()
	root.add_child(sound)
	check(sound._music_state == "calm" and sound._music[0].playing, "calm score starts on battle entry")
	check(sound.sounds.size() >= 20, "synthesized cue inventory")
	for cue_kind in ["hit", "crit", "kill", "blast", "saber_clash", "alert", "villain", "radio", "objective_hit", "victory", "defeat"]:
		check(sound.sounds[cue_kind].data.size() >= 5000, cue_kind + " has audible samples")
	var hit_sample: int = sound.sounds.hit.data.decode_s16(200)
	var blast_sample: int = sound.sounds.blast.data.decode_s16(200)
	check(hit_sample != blast_sample, "blast has distinct sub bass waveform")
	for pair in [["villain", "radio"], ["alert", "victory"], ["victory", "defeat"], ["crit", "kill"]]:
		check(sound.sounds[pair[0]].data != sound.sounds[pair[1]].data, "%s differs from %s" % pair)
	sound.cue("villain")
	check(sound._voices[0].playing, "story cue uses battle voice")
	sound.set_music_state("contact")
	check(sound._music_state == "contact" and sound._music_fade == 0.0, "contact crossfade begins")
	await create_timer(0.48).timeout
	check(sound._music_fade >= 0.99 and sound._music[1].playing, "contact crossfade finishes in budget")
	sound.set_music_state("enemy")
	check(sound._music_state == "enemy" and sound._music[0].playing, "enemy phase music starts")
	sound.set_music_state("victory")
	check(sound._music_state == "victory" and sound._music[1].playing, "victory loop starts")
	sound.muted = true
	await create_timer(0.04).timeout
	check(sound._music[1].volume_linear == 0.0 and sound._ambience.volume_linear == 0.0, "mute silences score and ambience")
	sound.muted = false
	sound.volume = 0.2
	sound._ambience.stop()
	await process_frame
	check(sound._music[1].volume_linear <= 0.0261, "score follows volume")
	await create_timer(0.04).timeout
	check(sound._ambience.playing, "ambience resumes after unmute")
	sound.set_music_state("off")
	check(sound._music_state == "off", "music can turn off")
	var fx := Effects.new()
	root.add_child(fx)
	var camera := Camera3D.new()
	root.add_child(camera)
	fx.setup(camera, null)
	check(fx._tier() == "low", "suite exercises Low effects")
	fx._ensure_billboards()
	var sparks_before := fx.get_child_count()
	var pooled_before: int = fx._billboards.cursor
	fx.burst(Vector3(0, 1, 0), Color.WHITE, 32)
	check(fx.get_child_count() == sparks_before and (fx._billboards.cursor - pooled_before + fx._billboards.capacity) % fx._billboards.capacity == 4, "Low sparks remain capped at four pooled slots")
	fx.contact(Vector3(0, 1, 0))
	check(fx.get_node_or_null("HitCore") != null and fx.get_node_or_null("HitRim") != null, "normal hit spawns two emissive shapes")
	fx.blast(Vector3(1, 1, 0))
	check(fx.get_node_or_null("BlastCore") != null and fx.get_node_or_null("BlastShell") != null and fx._billboards.capacity == 12, "blast has core, shell, ring and pooled sparks")
	var fx_constants: Dictionary = fx.get_script().get_script_constant_map()
	check(float(fx_constants.get("BLAST_CORE_SECONDS", 0)) >= 0.15 and float(fx_constants.get("BLAST_SHELL_SECONDS", 0)) >= 0.4, "two readable blast stages")
	check(float(fx_constants.get("CAMERA_IMPULSE_MAX", 1)) <= 0.16, "camera impulse capped")
	check(float(fx_constants.get("HIT_STOP_LIMIT", 1)) <= 0.3, "crit and kill stop fits budget")
	check(float(fx.get_script().call("blast_screen_scale", Vector2(390, 844))) == 0.55 and float(fx.get_script().call("blast_screen_scale", Vector2(844, 390))) == 1.0, "blast fits portrait and landscape")
	await create_timer(0.26).timeout
	check(fx.get_node_or_null("BlastCore") == null and fx.get_node_or_null("BlastShell") != null, "blast changes from core to shell")
	check(fx.get_node_or_null("HitCore") == null, "contact flash clears within 0.26 s")
	await create_timer(0.34).timeout
	check(fx.get_node_or_null("BlastShell") == null, "blast shell clears within 0.6 s")
	check(camera.position.length() < 0.001, "camera impulse returns to origin")
	fx.hit_stop(0.03)
	check(Engine.time_scale < 1.0, "crit or kill can stop time")
	await create_timer(0.06, true, false, true).timeout
	check(is_equal_approx(Engine.time_scale, 1.0), "hit stop restores time scale")
	var view := UnitView.new()
	root.add_child(view)
	view.setup({"id":1, "side":"player", "class_name":"Guardian", "model":"jedi"}, load("res://assets/models/units/jedi.glb"), Vector3.ZERO)
	check(view.hum != null and view.hum.playing and view.saber_active, "saber hum loops while active")
	if view.hum != null:
		check(view.hum.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "saber hum stream loops")
		view.set_saber_active(false)
		check(not view.hum.playing and not view.saber_active, "blade off silences hum")
	view.act("hit")
	check(view.pose_motion != null and view.pose_motion.get_total_elapsed_time() < 0.1, "hit recoil begins immediately")
	view.travel([Vector3(1, 0, 0)])
	for i in 60:
		if view.footfalls >= 1: break
		await process_frame
	check(view.footfalls >= 1 and view.foot != null, "move punctuated by footfall")
	check(view.get_children().any(func(child: Node): return child is MeshInstance3D and child != view.ring), "move spawns dust mesh")
	view.queue_free()
	await process_frame
	var bodies: Array[Node3D] = []
	for i in 7:
		var corpse := UnitView.new()
		root.add_child(corpse)
		corpse.model = Node3D.new()
		corpse.add_child(corpse.model)
		corpse.fall()
		bodies.append(corpse)
	var view_script: Script = bodies[6].get_script()
	var view_constants: Dictionary = view_script.get_script_constant_map()
	var corpse_list: Array = view_script.get("_corpses")
	check(int(view_constants.get("CORPSE_CAP", 0)) == 6 and corpse_list.size() <= 6, "corpse budget stays at six")
	check(float(view_constants.get("FALL_SECONDS", 0)) >= 0.7 and float(view_constants.get("CORPSE_LIFETIME", 0)) >= 6.0, "kill fall and body stay readable")
	await create_timer(0.85).timeout
	check(is_instance_valid(bodies[6]) and bodies[6].model.rotation.z > 1.2, "fallen body remains at 0.85 s")
	await process_frame
	check(not is_instance_valid(bodies[0]) and is_instance_valid(bodies[6]), "oldest corpse evicted first")
	for body in bodies:
		if is_instance_valid(body): body.queue_free()
	fx.queue_free()
	camera.queue_free()
	sound.queue_free()
	await process_frame
	Prefs.set_value("speed", prior_speed)
	Prefs.set_value("motion", prior_motion)
	print("impact22: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func capture_only() -> void:
	var size_name := argument("--size", "844x390")
	var dimensions := size_name.split("x")
	var size := Vector2i(int(dimensions[0]), int(dimensions[1]))
	root.size = size
	root.content_scale_size = size
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.set_process(false)
	game.phase_banner.hide()
	game.hud_controls.night.phase_plate.hide()
	var target: Dictionary = game.mission.living("player")[0]
	var victim: Node3D = game.views[int(target.id)]
	var at := victim.global_position + Vector3.UP * 1.1
	game.pivot = victim.global_position
	game.zoom = 10.0
	game._update_camera()
	var kind := argument("--capture-only")
	if kind == "hit":
		game.fx.bolt(at + Vector3(-2.5, 0.25, 0), at, false, false)
		victim.act("hit")
		await create_timer(0.17).timeout
	elif kind == "blast":
		game.fx.ability("grenade", at + Vector3(-2.5, 0, 0), at)
		await create_timer(0.17).timeout
	elif kind == "kill":
		victim.fall()
		await create_timer(1.2).timeout
	game.phase_banner.hide()
	game.hud_controls.night.phase_plate.hide()
	await RenderingServer.frame_post_draw
	var output := argument("--output")
	var result := root.get_texture().get_image().save_png(output)
	print("IMPACT22 CAPTURE %s %s %s" % [kind, size_name, error_string(result)])
	game.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
