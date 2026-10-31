extends Node

var player: AudioStreamPlayer
var sounds: Dictionary = {}
var volume := 0.55
var muted := false

func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)
	for kind in ["shot", "saber", "push", "hit", "death", "click", "turn"]:
		sounds[kind] = _synthesize(kind)

func _synthesize(kind: String) -> AudioStreamWAV:
	var sample_rate := 22050
	var seconds := 0.12
	if kind in ["push", "saber", "turn"]: seconds = 0.42
	if kind == "death": seconds = 0.65
	var count := int(sample_rate * seconds)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = kind.hash()
	for i in range(count):
		var t := float(i) / sample_rate
		var fade := pow(1.0 - float(i) / count, 1.5)
		var frequency := 150.0
		match kind:
			"shot": frequency = 920.0 - 670.0 * t / seconds
			"saber": frequency = 135.0 + 70.0 * sin(t * 15.0)
			"push": frequency = 85.0 + 290.0 * t / seconds
			"hit": frequency = 80.0
			"death": frequency = 280.0 - 190.0 * t / seconds
			"click": frequency = 750.0
			"turn": frequency = 330.0 + 220.0 * floor(t * 6.0)
		var noise := random.randf_range(-1.0, 1.0)
		var wave := sin(TAU * frequency * t) * 0.55 + noise * (0.35 if kind in ["push", "hit", "death"] else 0.12)
		var value := int(clampf(wave * fade * 12000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream

func play(kind: String) -> void:
	if muted or not sounds.has(kind): return
	player.stop()
	player.stream = sounds[kind]
	player.volume_linear = volume
	player.play()

func _exit_tree() -> void:
	player.stop()
	player.stream = null
	sounds.clear()
