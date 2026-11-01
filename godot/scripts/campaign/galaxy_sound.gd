extends AudioStreamPlayer
## Quiet UI sonar, routed through the existing Master bus.
func _ready() -> void:
	var wav := AudioStreamWAV.new(); wav.format = AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate = 22050
	var bytes := PackedByteArray(); bytes.resize(1764)
	for i in 882:
		var t := float(i)/22050.0
		bytes.encode_s16(i*2,int(sin(TAU*880*t)*sin(PI*float(i)/882.0)*2400))
	wav.data = bytes; stream = wav; volume_db = -21
