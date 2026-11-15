extends Node

const SOUNDS := {
	"hurt": "res://audio/hurt.mp3",
	"lose_life": "res://audio/lose_life.mp3",
	"shoot": "res://audio/shoot.mp3",
	"explosion": "res://audio/explosion.mp3",
}
const VOICE_COUNT := 8

var streams := {}
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in SOUNDS:
		var path: String = SOUNDS[key]
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream:
				streams[key] = stream
	for i in VOICE_COUNT:
		var voice := AudioStreamPlayer.new()
		voice.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(voice)
		voices.append(voice)


func play(key: String, volume_db: float = -8.0, pitch: float = 1.0) -> void:
	var stream = streams.get(key)
	if stream == null or voices.is_empty():
		return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = pitch
	voice.play()
