extends Node

var music_player: AudioStreamPlayer 
var sfx_container: Node 

var sounds: Dictionary = {
	"fight": preload("res://Audio/sfx/fight.mp3"),
	"mandarina": preload("uid://ddfr5f70m4fpj"),
	"fatality":preload("uid://b7nl05ipw60wc")
}

func _ready() -> void:
	# Inicialización de nodos en tiempo de ejecución
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	sfx_container = Node.new()
	sfx_container.name = "SFXContainer"
	add_child(sfx_container)

func play_music(music: AudioStream) -> void:
	if music_player.stream == music:
		return

	music_player.stream = music
	music_player.play()

func play_sfx(sound_name: String, volume: float = 0.0) -> void:
	if not sounds.has(sound_name):
		print("No existe sonido: ", sound_name)
		return

	var player: AudioStreamPlayer = AudioStreamPlayer.new()

	player.stream = sounds[sound_name]
	player.volume_db = volume

	sfx_container.add_child(player)

	player.play()

	player.finished.connect(func() -> void:
		player.queue_free()
	)
