extends Area2D

@export var lives_to_add: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verificación técnica mediante duck typing
	if body.has_method("_setup_inputs"):
		_try_add_life(body)

func _try_add_life(player: Node2D) -> void:
	# Verificamos que el jugador tenga las variables declaradas
	if "current_lives" in player and "max_lives" in player:
		
		# Validamos que no supere la vida máxima
		if player.current_lives < player.max_lives:
			player.current_lives += lives_to_add
			
			# Límite de seguridad por si lives_to_add es mayor a 1
			if player.current_lives > player.max_lives:
				player.current_lives = player.max_lives
				
			# Forzamos al jugador a emitir su propia señal para actualizar la interfaz
			player.emit_signal("lives_updated", player.player_id, player.current_lives)
			
	# El objeto se destruye siempre que un jugador lo toque, 
	# sin importar si le sumó la vida o no.
	queue_free()
