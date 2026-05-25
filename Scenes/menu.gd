extends Control

const CHULETITA = preload("uid://cp2vhfdrfhcow")
@onready var player_select: Control = $PlayerSelect

func _on_play_pressed() -> void:
	player_select.visible=true
	player_select.ejecutar_transicion()


func _on_exit_button_up() -> void:
	pass # Replace with function body.
