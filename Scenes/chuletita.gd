extends Node2D

@export var player_1: CharacterBody2D
@export var player_2: CharacterBody2D
@export var camera: Camera2D # <--- NUEVA VARIABLE PARA LA CÁMARA
@export var background: ColorRect 
@export var title_label: TextureRect    

@export var icons_container: HBoxContainer 
@export var tex_up: Texture2D
@export var tex_down: Texture2D
@export var tex_left: Texture2D
@export var tex_right: Texture2D

var is_fatality_active: bool = false
var combo_sequence: Array[String] = []
var current_step: int = 0
var winner_id: int = 0
var loser_node: CharacterBody2D
var winner_node: CharacterBody2D

@onready var p_1: Node2D = $UI/P1
@onready var p_2: Node2D = $UI/P2
@onready var objets: Node2D = $Objets



func _ready() -> void:
	background.visible = false
	if title_label: title_label.visible = false
	if icons_container: icons_container.visible = false

	if is_instance_valid(player_1):
		player_1.connect("fatality_triggered", Callable(self, "_on_fatality_triggered"))
	if is_instance_valid(player_2):
		player_2.connect("fatality_triggered", Callable(self, "_on_fatality_triggered"))

func _on_fatality_triggered(loser_id: int) -> void:
	is_fatality_active = true
	AudioManager.play_sfx("fatality",20.0)
	if loser_id == 1:
		loser_node = player_1
		winner_node = player_2
		winner_id = 2
	else:
		loser_node = player_2
		winner_node = player_1
		winner_id = 1

	# --- BLOQUEO ABSOLUTO DEL JUGADOR PERDEDOR ---
	
	loser_node.can_move = false
	loser_node.is_in_fight = false
	loser_node.can_mash = false
	loser_node.velocity = Vector2.ZERO
	# Forzamos a que se quede quieto en su lugar mirando a donde estaba
	loser_node.animated_sprite_2d.play("idle_" + loser_node.last_idle_dir)

	# --- FRENAMOS AL GANADOR (para que no se mueva, pero el manager leerá sus teclas) ---
	winner_node.can_move = false
	winner_node.is_in_fight = false
	winner_node.can_mash = false
	winner_node.velocity = Vector2.ZERO

	
	# Activamos el zoom de la cámara
	if is_instance_valid(camera):
		camera.is_in_fatality = true

	background.visible = true
	if title_label:
		title_label.visible = true
		p_1.visible=false
		p_2.visible=false
		objets.visible=false
	if icons_container: 
		icons_container.visible = true
	
	_generate_combo()

func _generate_combo() -> void:
	combo_sequence.clear()
	current_step = 0
	
	var possible_actions = ["move_up_p", "move_down_p", "move_left_p", "move_right_p"]
	
	for i in range(4):
		var base_action = possible_actions[randi() % possible_actions.size()]
		var action = base_action + str(winner_id)
		combo_sequence.append(action)
		
		var tex_rect = icons_container.get_child(i) as TextureRect
		
		match base_action:
			"move_up_p": tex_rect.texture = tex_up
			"move_down_p": tex_rect.texture = tex_down
			"move_left_p": tex_rect.texture = tex_left
			"move_right_p": tex_rect.texture = tex_right
			
		tex_rect.modulate = Color(1.0, 1.0, 1.0, 1.0) 

func _input(event: InputEvent) -> void:
	if not is_fatality_active:
		return
		
	if current_step < combo_sequence.size():
		var expected_action = combo_sequence[current_step]
		
		if event.is_action_pressed(expected_action):
			var tex_rect = icons_container.get_child(current_step) as TextureRect
			tex_rect.modulate = Color(0.3, 0.3, 0.3, 0.4) 
			
			current_step += 1
			
			if current_step >= combo_sequence.size():
				_execute_fatality()

func _execute_fatality() -> void:
	is_fatality_active = false
	
	if icons_container: icons_container.visible = false
	
	winner_node.animated_sprite_2d.play("attack")
	
	await get_tree().create_timer(1.0).timeout
	
	# --- RESTAURAMOS LA CÁMARA POR SI ACASO ANTES DE CAMBIAR DE ESCENA ---
	if is_instance_valid(camera):
		camera.is_in_fatality = false
		
	background.visible = false
	if title_label: title_label.visible = false
	
	loser_node.die()
