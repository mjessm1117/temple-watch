extends SceneTree

const Effects = preload("res://scripts/fx.gd")
const Audio = preload("res://scripts/audio.gd")
const UnitView = preload("res://scripts/unit_view.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	var fx := Effects.new()
	root.add_child(fx)
	fx.bolt(Vector3(0, 1, 0), Vector3(3, 1, 0), false, true)
	fx.saber(Vector3(0, 1, 0), Vector3(1, 1, 0))
	fx.shockwave(Vector3(0, 1, 0), Vector3(2, 1, 0))
	check(fx.get_child_count() > 0, "effects create visual nodes")
	var audio := Audio.new()
	root.add_child(audio)
	audio.play("shot")
	audio.play("hit")
	check(audio._voices[0].playing and audio._voices[1].playing, "overlapping effects have separate voices")
	check(audio.sounds.has("step") and audio.sounds.has("whiz"), "movement and miss sounds synthesized")
	var view := UnitView.new()
	root.add_child(view)
	view.setup({"id": 1, "side": "player", "class_name": "Guardian"}, load("res://assets/models/units/jedi.glb"), Vector3.ZERO)
	view.face(Vector3(2, 0, 0))
	check(view.turn_motion != null, "turn is animated")
	view.set_cover(2)
	check(view._cover_level == 2, "full cover pose accepted")
	view.stagger_to(Vector3(1, 0, 0))
	check(view.motion != null, "push stagger moves the view")
	await create_timer(0.5).timeout
	check(fx._scorches.size() == 1, "miss leaves bounded scorch")
	check(fx._scorches.size() <= 32, "scorch cap")
	fx.hit_stop(0.03)
	check(Engine.time_scale < 1.0, "hit stop slows presentation")
	await create_timer(0.08, true, false, true).timeout
	check(is_equal_approx(Engine.time_scale, 1.0), "hit stop restores time scale")
	print("FX TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
