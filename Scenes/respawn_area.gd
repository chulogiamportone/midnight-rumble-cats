extends Area2D

# Podés cambiar esto desde el editor si decidís usar otro nombre para el grupo
@export var markers_group: String = "respawn"

# Acordate de conectar la señal body_entered del Area2D a esta función
func _on_body_entered(body: Node2D) -> void:
	# Verificamos si es un jugador
	if body is CharacterBody2D and body.get("player_id") != null:
		
		# 1. Le restamos una vida usando la función que ya tenés en el player
		if body.has_method("lose_life"):
			body.lose_life(1)
		
		# 2. Si todavía le quedan vidas (mayor a 0), lo devolvemos al mapa
		if body.current_lives > 0:
			_respawn_player(body)

func _respawn_player(player: CharacterBody2D) -> void:
	# Buscamos todos los markers que estén en la escena
	var markers = get_tree().get_nodes_in_group(markers_group)
	
	if markers.size() > 0:
		# Elegimos uno al azar
		var random_marker = markers[randi() % markers.size()]
		
		# Teletransportamos al jugador a la posición global del marker
		player.global_position = random_marker.global_position
		
		# Opcional pero recomendado: Frenar la velocidad del jugador 
		# para que no salga volando si entró al portal saltando o haciendo dash
		player.velocity = Vector2.ZERO
		
		# Frenar su estado de dash o salto para evitar bugs visuales
		if player.has_method("set_climbing_state"): # Chequeo rápido por las dudas
			player.is_dashing = false
			player.is_jumping_in_area = false
			player.is_climbing = false
			
		print("Jugador ", player.player_id, " teletransportado al marker: ", random_marker.name)
	else:
		print("⚠️ Error: No se encontraron markers en el grupo '", markers_group, "'. Asegurate de haberlos agregado.")
