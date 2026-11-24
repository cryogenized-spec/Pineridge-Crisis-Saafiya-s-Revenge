extends Node
# Recorded cues only: no generated test beeps or synthetic firing substitutes.
const CHANNELS := 7
const GAIN_DB := {
	"beretta_84fs_shot": -7.0,
	"cz75_shot": -12.0,
	"akm_shot": -12.0,
	"shotgun_12ga_shot": -12.0
}
var players: Array[AudioStreamPlayer] = []
var cached: Dictionary = {}
var cursor := 0

func _ready() -> void:
	for i in range(CHANNELS):
		var player := AudioStreamPlayer.new()
		player.volume_db = -16.0
		add_child(player)
		players.append(player)

func stream_for(id: String) -> AudioStream:
	if cached.has(id):
		return cached[id]
	for ext in ["wav","ogg","mp3"]:
		var path := "res://assets/audio/%s.%s" % [id,ext]
		if ResourceLoader.exists(path):
			var stream := ResourceLoader.load(path) as AudioStream
			if stream != null:
				cached[id] = stream
				return stream
	# Missing recordings are silent by design, never substituted with beeps.
	return null

func play_cue(id: String, offset_db: float = 0.0) -> void:
	if players.is_empty():
		return
	var recording := stream_for(id)
	if recording == null:
		return
	var player := players[cursor]
	cursor = (cursor + 1) % CHANNELS
	player.stop()
	player.stream = recording
	# +4 dB (~1.6× amplitude) above the prior pistol/AK cue volumes.
	player.volume_db = float(GAIN_DB.get(id,-16.0)) + offset_db
	player.play()
