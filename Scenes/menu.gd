extends Control

const CHULETITA = preload("uid://cp2vhfdrfhcow")

func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(CHULETITA)


func _on_exit_button_up() -> void:
	pass # Replace with function body.
