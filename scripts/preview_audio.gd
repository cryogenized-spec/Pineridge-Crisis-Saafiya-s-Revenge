extends Node
# Replaceable event audio. Multiple overlapping voices and sounds are supported.
const CHANNELS := 7
const CUES := {
	"pickup":440.0,"set_down":280.0,"alert":660.0,
	"reaction":210.0,"reset":520.0,"fire":350.0,
	"down":190.0,"beretta_84fs_shot":350.0,
	"cz75_shot":390.0,"beretta_reload":300.0,
	"cz75_reload":310.0,"akm_reload":270.0,
	"saafiya_death":175.0,"crowd_shout":270.0
}
var players: Array[AudioStreamPlayer] = []
var cached: Dictionary = {}
var cursor := 0

func _ready() -> void:
	for i in range(CHANNELS):
		var p := AudioStreamPlayer.new()
		p.volume_db=-16.0
		add_child(p)
		players.append(p)

func stream_for(id: String) -> AudioStream:
	if cached.has(id):
		return cached[id]
	for ext in ["wav","ogg","mp3"]:
		var path := "res://assets/audio/%s.%s" % [id,ext]
		if ResourceLoader.exists(path):
			var found := ResourceLoader.load(path) as AudioStream
			if found != null:
				cached[id]=found
				return found
	# Explicitly placeholder tones; no weapon or language sound imitation.
	var rate := 22050
	var count := int(rate*0.11)
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	var hz := float(CUES.get(id,330.0))
	for i in range(count):
		var t := float(i)/float(rate)
		var fade := sin(PI*float(i)/float(count))
		bytes.encode_s16(i*2,int(4800.0*sin(TAU*hz*t)*fade))
	var wave := AudioStreamWAV.new()
	wave.format=AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate=rate
	wave.data=bytes
	cached[id]=wave
	return wave

func play_cue(id: String) -> void:
	if players.is_empty():
		return
	var selected := players[cursor]
	cursor=(cursor+1)%CHANNELS
	selected.stop()
	selected.stream=stream_for(id)
	selected.play()
