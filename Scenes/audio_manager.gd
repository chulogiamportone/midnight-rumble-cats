extends Node

var music_player: AudioStreamPlayer 
var sfx_container: Node 

var p1_character: String = ""
var p2_character: String = ""


var sounds: Dictionary = {
	"fight": preload("res://Audio/sfx/fight.mp3"),
	"mandarina": preload("uid://ddfr5f70m4fpj"),
	"fatality":preload("uid://b7nl05ipw60wc"),
	"food":preload("uid://bmb7b53200igc"),
	"meow":preload("uid://c5tgheo8np2gx"),
	"rocks":preload("uid://cvj1jd8xp15os"),
	"a1":preload("uid://cjwsaa8pfgti5"),
	"a2":preload("uid://bqii3s32jdahv"),
	"a3":preload("uid://d2xa7ibjisc6l"),
	"a4": preload("uid://cof67ppxtkfjl"),
	"a5":preload("uid://cmputroegwxpv") ,
	"a6":preload("uid://eregytc1wydy"),
	"a7":preload("uid://dqkhdjtgl4lmq")
	
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
