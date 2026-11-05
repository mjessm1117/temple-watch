extends SceneTree
## Original-motion contract and a three-Jedi frame strip capture.

const Lookup = preload("res://scripts/characters/jedi_models.gd")
const IDS := ["kira", "tor", "satele", "ressa", "kell", "sava", "tem"]
const CLIPS := ["idle", "saberIdle", "gunIdle", "run", "walk", "swing", "swing2", "cast", "channel", "shoot", "hit", "death", "block", "throw", "aim"]
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func find(node: Node, kind: String) -> Node:
	if node.is_class(kind): return node
	for child in node.get_children():
		var result := find(child, kind)
		if result != null: return result
	return null

func pose_distance(skeleton: Skeleton3D, bones: Array[String], before: Dictionary) -> float:
	var distance := 0.0
	for bone in bones:
		var i := skeleton.find_bone(bone)
		if i < 0: continue
		var first: Transform3D = before[bone]
		var now := skeleton.get_bone_pose(i)
		distance += first.origin.distance_to(now.origin)
		distance += first.basis.get_rotation_quaternion().angle_to(now.basis.get_rotation_quaternion())
	return distance

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if "--strip" in args:
		await capture_strip()
		print("anim16 strip: %d checks, %d failures" % [checks, failures])
		quit(1 if failures else 0)
		return
	for id in IDS:
		var scene := Lookup.scene_for_id(id, null)
		check(scene != null, id + " loads")
		if scene == null: continue
		var model := scene.instantiate()
		root.add_child(model)
		var player := find(model, "AnimationPlayer") as AnimationPlayer
		var skeleton := find(model, "Skeleton3D") as Skeleton3D
		check(player != null and skeleton != null, id + " rig and player")
		if player == null or skeleton == null: model.queue_free(); continue
		Lookup.configure_animation(player)
		for clip in CLIPS:
			check(player.has_animation(clip), id + " original " + clip)
			if player.has_animation(clip): check(player.get_animation(clip).get_track_count() >= 20, id + " full bone tracks " + clip)
		for clip in ["idle", "run", "swing", "cast", "hit", "death"]:
			if not player.has_animation(clip): continue
			var bones: Array[String] = ["pelvis", "spine_01", "upperarm_l", "upperarm_r", "thigh_l", "thigh_r"]
			player.stop(); skeleton.reset_bone_poses()
			var initial: Dictionary = {}
			for bone in bones: initial[bone] = skeleton.get_bone_pose(skeleton.find_bone(bone))
			player.play(clip, 0.0)
			var maximum := 0.0
			for fraction in [0.2, 0.45, 0.7]:
				player.seek(player.get_animation(clip).length * fraction, true)
				maximum = maxf(maximum, pose_distance(skeleton, bones, initial))
			check(maximum > 0.025, id + " moving bones " + clip)
		for pair in [["saberIdle", "run"], ["run", "saberIdle"], ["saberIdle", "swing"], ["swing", "saberIdle"]]:
			check(player.get_blend_time(pair[0], pair[1]) > 0.0, id + " blend " + pair[0] + " to " + pair[1])
		for clip in ["idle", "saberIdle", "run", "walk"]:
			check(player.get_animation(clip).loop_mode == Animation.LOOP_LINEAR, id + " loops " + clip)
		player.stop(); player.play("run", 0.0)
		var foot_l := skeleton.find_bone("foot_l")
		var foot_r := skeleton.find_bone("foot_r")
		var low := INF; var high := -INF
		for frame in 24:
			player.seek(player.get_animation("run").length * float(frame) / 23.0, true)
			var left := skeleton.to_global(skeleton.get_bone_global_pose(foot_l).origin).y
			var right := skeleton.to_global(skeleton.get_bone_global_pose(foot_r).origin).y
			var floor := minf(left, right)
			low = minf(low, floor); high = maxf(high, floor)
		check(high - low < 0.05, id + " planted foot height stays within 5 cm")
		model.queue_free()
	print("anim16: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func capture_strip() -> void:
	var stage := Node3D.new(); root.add_child(stage)
	var world := WorldEnvironment.new(); stage.add_child(world)
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color("142334")
	world.environment = env
	var camera := Camera3D.new(); stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 3.7
	camera.position = Vector3(0, 1.5, 7.5); camera.look_at(Vector3(0, 1.12, 0)); camera.current = true
	var key := DirectionalLight3D.new(); stage.add_child(key)
	key.rotation = Vector3(-0.6, -0.55, 0); key.light_energy = 2.0
	var fill := DirectionalLight3D.new(); stage.add_child(fill)
	fill.rotation = Vector3(0.2, 2.4, 0); fill.light_energy = 0.9
	var players: Array[AnimationPlayer] = []
	for i in 3:
		var id: String = ["kira", "tor", "satele"][i]
		var model := Lookup.scene_for_id(id, null).instantiate() as Node3D
		stage.add_child(model); model.position.x = (i - 1) * 2.1; model.scale = Vector3.ONE * 1.2
		var player := find(model, "AnimationPlayer") as AnimationPlayer
		Lookup.configure_animation(player); players.append(player)
	for clip in ["idle", "saberIdle", "run", "swing"]:
		var strip := Image.create_empty(1320, 1260, false, Image.FORMAT_RGBA8)
		strip.fill(Color("142334"))
		for i in 6:
			for player in players:
				player.play(clip, 0.0)
				player.seek(player.get_animation(clip).length * float(i) / 5.0, true)
			for frame in 3: await process_frame
			await RenderingServer.frame_post_draw
			var frame_image := root.get_texture().get_image()
			for actor in 3:
				var center_x := frame_image.get_width() / 2 + int((actor - 1) * 2.1 * frame_image.get_height() / 3.7)
				var crop := frame_image.get_region(Rect2i(center_x - 160, 55, 320, frame_image.get_height() - 105))
				crop.resize(220, 420, Image.INTERPOLATE_LANCZOS)
				crop.convert(Image.FORMAT_RGBA8)
				strip.blit_rect(crop, Rect2i(0, 0, 220, 420), Vector2i(i * 220, actor * 420))
		var path := "res://../docs/godot/shots/wave16-anim-strip-%s.png" % clip
		check(strip.save_png(path) == OK, path)
	stage.queue_free()
