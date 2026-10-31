extends Node

var player: AudioStreamPlayer
var sounds: Dictionary = {}
var volume := 0.55
var muted := false
var _voices: Array[AudioStreamPlayer] = []
var _voice_cursor := 0
var _ambience: AudioStreamPlayer

func _ready() -> void:
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -14.0
		add_child(voice)
		_voices.append(voice)
	player = _voices[0]
	for kind in ["shot", "saber", "push", "hit", "death", "click", "turn", "step", "whiz", "clash", "ignite"]:
		sounds[kind] = _synthesize(kind)
	_ambience = AudioStreamPlayer.new()
	_ambience.stream = _synthesize("ambience")
	_ambience.volume_db = -34.0
	add_child(_ambience)
	_ambience.finished.connect(func() -> void:
		if not muted and is_inside_tree(): _ambience.play())
	_ambience.play()

func _synthesize(kind: String) -> AudioStreamWAV:
	var rate := 22050
	var seconds := 0.13
	match kind:
		"saber", "push", "turn", "ignite": seconds = 0.38
		"death": seconds = 0.58
		"ambience": seconds = 3.0
		"step": seconds = 0.085
	var count := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = kind.hash()
	var filtered := 0.0
	for i in range(count):
		var t := float(i) / rate
		var phase := t / seconds
		var noise := rng.randf_range(-1.0, 1.0)
		filtered = lerpf(filtered, noise, 0.07)
		var envelope := pow(1.0 - phase, 1.8) * minf(1.0, t * 120.0)
		var wave := 0.0
		match kind:
			"shot": wave = sin(TAU * (1100.0 * t - 560.0 * t * t)) * 0.46 + noise * 0.2
			"saber": wave = sin(TAU * (145.0 * t + 30.0 * t * t)) * 0.4 + sin(TAU * 370.0 * t) * 0.18 + filtered * 0.42
			"push": wave = sin(TAU * (72.0 * t + 360.0 * t * t)) * 0.42 + filtered * 0.75
			"hit", "clash": wave = noise * 0.42 + sin(TAU * 120.0 * t) * 0.35
			"death": wave = sin(TAU * (240.0 * t - 130.0 * t * t)) * 0.35 + filtered * 0.55
			"step": wave = filtered * 0.9 + sin(TAU * 82.0 * t) * 0.25
			"whiz": wave = sin(TAU * (500.0 * t + 1600.0 * t * t)) * 0.35 + noise * 0.12
			"ignite": wave = sin(TAU * (90.0 * t + 450.0 * t * t)) * 0.32 + filtered * 0.4
			"click": wave = noise * 0.38
			"turn": wave = sin(TAU * (330.0 * t + 200.0 * t * t)) * 0.35
			"ambience":
				envelope = 0.5 - 0.5 * cos(TAU * phase)
				wave = sin(TAU * 48.0 * t) * 0.2 + sin(TAU * 72.0 * t) * 0.12 + filtered * 0.11
		var sample := int(clampf(wave * envelope * 13000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream

func play(kind: String) -> void:
	if muted or not sounds.has(kind): return
	var voice := _voices[_voice_cursor]
	_voice_cursor = (_voice_cursor + 1) % _voices.size()
	voice.stop()
	voice.stream = sounds[kind]
	voice.volume_linear = volume * (0.48 if kind in ["step", "whiz"] else 0.7)
	voice.pitch_scale = randf_range(0.96, 1.04)
	voice.play()

func _exit_tree() -> void:
	for voice in _voices: voice.stop()
	if _ambience != null: _ambience.stop()
	sounds.clear()
