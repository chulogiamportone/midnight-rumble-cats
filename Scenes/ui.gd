extends CanvasLayer

@onready var p1_label: Label = $VidasP1
@onready var p2_label: Label = $VidasP2
@onready var p1_key_sprite: AnimatedSprite2D = $UI_keyP1/AnimatedSprite2D
@onready var p2_key_sprite: AnimatedSprite2D = $UI_keyP2/AnimatedSprite2D
@onready var countdown_label: Label = $InitialLabel

@onready var p1_progress_bar: ProgressBar = $Bar1
@onready var p2_progress_bar: ProgressBar =  $Bar2
@onready var p_1: AnimatedSprite2D = $p1
@onready var p_2: AnimatedSprite2D = $p2

func _ready() -> void:
	# Las teclas arrancan invisibles, pero LAS BARRAS de vida ya no
	p1_key_sprite.visible = false
	p2_key_sprite.visible = false
	p_1.play("5")
	p_2.play("5")
	var players = get_tree().get_nodes_in_group("players")
	
	for player in players:
		if not player.is_connected("lives_updated", Callable(self, "_on_lives_updated")):
			player.connect("lives_updated", Callable(self, "_on_lives_updated"))
		
		if not player.is_connected("qte_started", Callable(self, "_on_qte_started")):
			player.connect("qte_started", Callable(self, "_on_qte_started"))
			
		if not player.is_connected("qte_ended", Callable(self, "_on_qte_ended")):
			player.connect("qte_ended", Callable(self, "_on_qte_ended"))
			
		# --- NUEVA CONEXIÓN PARA LA VIDA ---
		if not player.is_connected("health_updated", Callable(self, "_on_health_updated")):
			player.connect("health_updated", Callable(self, "_on_health_updated"))
		
		# Forzamos la actualización inicial de UI
		_on_lives_updated(player.player_id, player.current_lives)
		_on_health_updated(player.player_id, player.current_health, player.max_health)

	_play_countdown()

func _on_lives_updated(player_id: int, current_lives: int) -> void:
	if player_id == 1:
		p1_label.text = "Gato 1: " + str(current_lives) + " Vidas"
		if current_lives==5 or current_lives==6:
			p_1.play("4")
		if current_lives==3 or current_lives==4:
			p_1.play("3")
		if current_lives==2:
			p_1.play("2")
		if current_lives==1:
			p_1.play("1")
	elif player_id == 2:
		p2_label.text = "Gato 2: " + str(current_lives) + " Vidas"
		if current_lives==5 or current_lives==6:
			p_2.play("4")
		if current_lives==3 or current_lives==4:
			p_2.play("3")
		if current_lives==2:
			p_2.play("2")
		if current_lives==1:
			p_2.play("1")

# --- NUEVA FUNCIÓN PARA LA BARRA DE VIDA PERMANENTE ---
func _on_health_updated(player_id: int, current_health: int, max_health: int) -> void:
	if player_id == 1:
		p1_progress_bar.max_value = max_health
		p1_progress_bar.value = current_health
	elif player_id == 2:
		p2_progress_bar.max_value = max_health
		p2_progress_bar.value = current_health

func _on_qte_started(player_id: int, qte_type: String) -> void:
	# En el QTE ahora solo mostramos la tecla, la vida ya está en pantalla
	if player_id == 1:
		p1_key_sprite.visible = true
		p1_key_sprite.play("key_" + qte_type) 
	elif player_id == 2:
		p2_key_sprite.visible = true
		p2_key_sprite.play("key_" + qte_type) 

func _on_qte_ended() -> void:
	# Solo ocultamos las teclas al terminar
	p1_key_sprite.visible = false
	p1_key_sprite.stop()
	p2_key_sprite.visible = false
	p2_key_sprite.stop()

func _play_countdown() -> void:
	countdown_label.visible = true
	
	countdown_label.text = "3"
	await get_tree().create_timer(1.0).timeout
	
	countdown_label.text = "2"
	await get_tree().create_timer(1.0).timeout
	
	countdown_label.text = "1"
	await get_tree().create_timer(1.0).timeout
	countdown_label.add_theme_font_size_override("font_size", 120)
	countdown_label.add_theme_color_override("font_color",Color(1.0, 0.0, 0.0, 1.0))
	countdown_label.text = "Fight!"
	await get_tree().create_timer(0.6).timeout
	countdown_label.add_theme_font_size_override("font_size", 100)
	countdown_label.add_theme_color_override("font_color",Color(1.0, 1.0, 1.0, 1.0))
	countdown_label.text = "I mean..."
	await get_tree().create_timer(0.6).timeout
	countdown_label.add_theme_font_size_override("font_size", 120)
	countdown_label.add_theme_color_override("font_color",Color(1.0, 0.0, 0.0, 1.0))
	countdown_label.text = "Meaow!"
	
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.has_method("start_game"):
			player.start_game()
			
	await get_tree().create_timer(1.0).timeout
	countdown_label.visible = false
