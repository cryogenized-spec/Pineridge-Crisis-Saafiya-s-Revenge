extends Node
# Replaceable, deliberately abstract cues, not recordings of weapons.
var player: AudioStreamPlayer
const CUES := {"pickup":440.0,"set_down":280.0,"alert":660.0,"reaction":210.0,"reset":520.0,"fire":350.0,"down":190.0}

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.volume_db = -16.0
	add_child(player)

func play_cue(id: String) -> void:
	if player == null:
		return
	for ext in ["wav","ogg","mp3"]:
		var path := "res://assets/audio/%s.%s" % [id,ext]
		if ResourceLoader.exists(path):
			var stream := ResourceLoader.load(path) as AudioStream
			if stream != null:
				player.stream = stream
				player.play()
				return
	var hz := float(CUES.get(id,330.0))
	var rate := 22050
	var count := int(rate*0.12)
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	for i in range(count):
		var t := float(i)/rate
		var envelope := sin(PI*float(i)/count)
		var sample := int(6200.0*sin(TAU*hz*t)*envelope)
		bytes.encode_s16(i*2,sample)
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = rate
	wave.data = bytes
	player.stream = wave
	player.play()
