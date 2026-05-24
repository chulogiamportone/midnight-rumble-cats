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
		# 3. Si se quedó sin vidas, lo ponemos al lado del otro player para la Fatality
		else:
			_teleport_to_other_player(body)
		
func _respawn_player(player: CharacterBody2D) -> void:
	# Buscamos todos los markers que estén en la escena
	var markers = get_tree().get_nodes_in_group(markers_group)
	
	if markers.size() > 0:
		# Elegimos uno al azar
		var random_marker = markers[randi() % markers.size()]
		
		# Teletransportamos al jugador a la posición global del marker
		player.global_position = random_marker.global_position
		_stop_player_movement(player)
			
		print("Jugador ", player.player_id, " teletransportado al marker: ", random_marker.name)
	else:
		print("⚠️ Error: No se encontraron markers en el grupo '", markers_group, "'. Asegurate de haberlos agregado.")

func _teleport_to_other_player(dead_player: CharacterBody2D) -> void:
	# Buscamos a los jugadores en la escena
	var players = get_tree().get_nodes_in_group("players")
	var other_player: CharacterBody2D = null
	
	# Identificamos cuál es el jugador que sigue vivo
	for p in players:
		if p != dead_player and p is CharacterBody2D:
			other_player = p
			break
			
	if other_player != null:
		# Calculamos el lado en el que va a aparecer (para que siempre quede enfrente)
		var offset_x = 100.0
		# Si el jugador vivo está mirando a la izquierda, ponemos al muerto a su izquierda
		if other_player.animated_sprite_2d.flip_h or other_player.last_idle_dir == "left":
			offset_x = -100.0
			
		# Teletransportamos al perdedor
		dead_player.global_position = other_player.global_position + Vector2(offset_x, 0)
		
		# Nos aseguramos de frenar todo su movimiento residual
		_stop_player_movement(dead_player)
		print("Jugador ", dead_player.player_id, " movido al lado del ganador para la fatality.")

# Función auxiliar para no repetir código de frenado
func _stop_player_movement(player: CharacterBody2D) -> void:
	player.velocity = Vector2.ZERO
	if player.has_method("set_climbing_state"): 
		player.is_dashing = false
		player.is_jumping_in_area = false
		player.is_climbing = false
