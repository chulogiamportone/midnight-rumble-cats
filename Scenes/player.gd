extends CharacterBody2D

# --- SEÑALES PARA LA INTERFAZ ---
signal health_updated(player_id: int, current_health: int, max_health: int) # <--- NUEVA SEÑAL
signal qte_started(player_id: int, action_name: String)
signal qte_ended()
signal lives_updated(player_id: int, current_lives: int) 
@onready var dead: Sprite2D = $"Dead"

@export var player_id: int = 1

@export var speed: float = 300.0
@export var climb_speed: float = 200.0
@export var jump_velocity: float = -500.0
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.2
@export var max_lives: int = 7 
@export var max_health: int = 20 # <--- CAMBIADO A 20 (Para que sean los 20 golpes)
@export var max_slip_speed: float = 80.0

var can_move: bool = false 
var is_immune: bool = false 

var current_lives: int = 7 
var current_health: int = 20 # <--- LA VARIABLE DE VIDA
var is_dashing: bool = false
var dash_timer: float = 0.0
var is_attacking: bool = false
var is_climbing: bool = false
var climbable_areas_count: int = 0
var facing_direction: float = 1.0

var is_jumping_in_area: bool = false
var reference_y: float = 0.0

var is_in_soft_gravity: bool = false
var soft_gravity_areas_count: int = 0

var input_left: String
var input_right: String
var input_up: String
var input_down: String
var input_jump: String
var input_dash: String
var input_attack: String

var last_idle_dir: String = "right" 

# --- VARIABLES DEL MINIJUEGO DE PELEA ---
var is_in_fight: bool = false
var fight_cooldown: bool = false 
var qte_target_actions: Array[String] = [] 
var current_opponent: CharacterBody2D = null
var can_mash: bool = false 

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var fight_effect_sprite: AnimatedSprite2D = $"../../FightEffectSprite" # Ajustá si cambió la ruta
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	current_lives = max_lives
	current_health = max_health # Llenamos la vida al inicio
	_setup_inputs()

func _setup_inputs() -> void:
	input_left = "move_left_p" + str(player_id)
	input_right = "move_right_p" + str(player_id)
	input_up = "move_up_p" + str(player_id)
	input_down = "move_down_p" + str(player_id)
	input_jump = "jump_p" + str(player_id)
	input_dash = "dash_p" + str(player_id)
	input_attack = "attack_p" + str(player_id)

func _physics_process(delta: float) -> void:
	if is_in_fight:
		_handle_qte_fight()
		
		if is_climbing:
			velocity.y = 0
		elif not is_on_floor():
			velocity.y += gravity * delta
			
		velocity.x = move_toward(velocity.x, 0, speed) 
		move_and_slide()
		return
		
	_check_climb_entry()
	_handle_jump_recovery()
	
	if is_dashing:
		_handle_dash(delta)
	elif is_climbing:
		_handle_climbing()
	else:
		if not is_on_floor():
			velocity.y += gravity * delta
			if is_in_soft_gravity and velocity.y > max_slip_speed:
				velocity.y = max_slip_speed
		_handle_movement()
		_handle_actions()

	move_and_slide()
	_update_animations()

func _update_animations() -> void:
	animated_sprite_2d.flip_h = false 

	if is_in_fight:
		if not fight_cooldown:
			fight_effect_sprite.play("fight") 
		return

	if is_attacking:
		return
		
	if is_dashing:
		return

	if velocity != Vector2.ZERO:
		if abs(velocity.x) > abs(velocity.y):
			last_idle_dir = "right" if velocity.x > 0 else "left"
		elif abs(velocity.y) > abs(velocity.x):
			last_idle_dir = "down" if velocity.y > 0 else "up"

	if is_climbing:
		if velocity != Vector2.ZERO:
			animated_sprite_2d.play("walk_" + _get_8way_direction(velocity))
		else:
			animated_sprite_2d.play("idle_" + last_idle_dir)
		return

	if is_on_floor():
		if velocity.x == 0:
			if not fight_cooldown: 
				animated_sprite_2d.play("idle_" + last_idle_dir)
		else:
			var dir = "right" if velocity.x > 0 else "left"
			animated_sprite_2d.play("walk_" + dir)
	else:
		pass

func _get_8way_direction(vel: Vector2) -> String:
	var dir := ""
	if vel.y < 0:
		dir += "up"
	elif vel.y > 0:
		dir += "down"
		
	if vel.x < 0:
		dir += ("_left" if dir != "" else "left")
	elif vel.x > 0:
		dir += ("_right" if dir != "" else "right")
		
	return dir

func _check_climb_entry() -> void:
	if not can_move:
		return
		
	if climbable_areas_count > 0 and not is_climbing:
		var v_direction := Input.get_axis(input_up, input_down)
		if v_direction != 0:
			is_climbing = true
			is_jumping_in_area = false
			velocity.x = 0
			velocity.y = 0

func _handle_jump_recovery() -> void:
	if is_jumping_in_area:
		if climbable_areas_count == 0:
			is_jumping_in_area = false
			return
		
		if velocity.y >= 0 and global_position.y >= reference_y:
			global_position.y = reference_y
			velocity.y = 0
			is_climbing = true
			is_jumping_in_area = false

func _handle_movement() -> void:
	if not can_move:
		velocity.x = move_toward(velocity.x, 0, speed)
		return

	if Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity

	var direction := Input.get_axis(input_left, input_right)
	if direction != 0:
		facing_direction = direction
		velocity.x = direction * speed
		if direction > 0:
			animated_sprite_2d.flip_h = false
		else:
			animated_sprite_2d.flip_h = true
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

func _handle_climbing() -> void:
	var h_direction := Input.get_axis(input_left, input_right)
	var v_direction := Input.get_axis(input_up, input_down)
	if not can_move:
		return
	if h_direction != 0:
		facing_direction = h_direction
		velocity.x = h_direction * climb_speed
		if h_direction > 0:
			animated_sprite_2d.flip_h = false
		else:
			animated_sprite_2d.flip_h = true
	else:
		velocity.x = move_toward(velocity.x, 0, climb_speed)

	velocity.y = v_direction * climb_speed

	if Input.is_action_just_pressed(input_jump):
		is_climbing = false
		is_jumping_in_area = true
		reference_y = global_position.y
		velocity.y = jump_velocity

func _handle_actions() -> void:
	if not can_move:
		return

	if Input.is_action_just_pressed(input_dash) and not is_dashing:
		is_dashing = true
		dash_timer = dash_duration
		velocity.x = facing_direction * dash_speed
		velocity.y = 0

	if Input.is_action_just_pressed(input_attack) and not is_attacking:
		_perform_attack()

func _handle_dash(delta: float) -> void:
	dash_timer -= delta
	if dash_timer <= 0:
		is_dashing = false
		velocity.x = 0

func _perform_attack() -> void:
	is_attacking = true
	print("Jugador ", player_id, " ejecutando ataque")
	await get_tree().create_timer(0.3).timeout
	is_attacking = false

# --- NUEVA LÓGICA DE DAÑO EN QTE ---
func _handle_qte_fight() -> void:
	if not can_mash:
		return
		
	for action in qte_target_actions:
		# Si apretamos la tecla correcta
		if Input.is_action_just_pressed(action):
			# Le pegamos al oponente! (Le restamos vida)
			if is_instance_valid(current_opponent):
				current_opponent.receive_qte_hit()
			break 

# Esta función es llamada por el otro jugador cuando te acierta un golpe en el QTE
func receive_qte_hit() -> void:
	current_health -= 1
	emit_signal("health_updated", player_id, current_health, max_health)
	
	# Si mi vida llega a 0, perdí la pelea
	if current_health <= 0:
		# Le avisamos al oponente que ganó
		if is_instance_valid(current_opponent):
			current_opponent.win_fight()
			
		# Perdemos la vida
		lose_life(1)
		
		# Si me quedan vidas, me regenero y termino la pelea como perdedor
		if current_lives > 0:
			current_health = max_health # Rellenamos la barra
			emit_signal("health_updated", player_id, current_health, max_health)
			_end_fight_sequence(false)
		else:
			# --- SI MORÍ DEFINITIVAMENTE ---
			emit_signal("qte_ended")
			if fight_effect_sprite and fight_effect_sprite.visible:
				fight_effect_sprite.visible = false
				fight_effect_sprite.stop()
				
			# Aseguramos que el jugador y el oponente vuelvan a ser visibles
			self.visible = true
			if is_instance_valid(current_opponent):
				current_opponent.visible = true

func win_fight() -> void:
	print("¡Jugador ", player_id, " gana el choque!")
	_end_fight_sequence(true)

func _end_fight_sequence(is_winner: bool) -> void:
	self.visible = true
	if is_instance_valid(current_opponent):
		current_opponent.visible = true
		
	is_in_fight = false
	fight_cooldown = true
	current_opponent = null
	
	emit_signal("qte_ended")
	
	if fight_effect_sprite and fight_effect_sprite.visible:
		fight_effect_sprite.visible = false
		fight_effect_sprite.stop()
	
	if is_winner:
		fight_effect_sprite.play("fight_end")
		await get_tree().create_timer(1.0).timeout
		fight_cooldown = false
		animated_sprite_2d.play("idle_" + last_idle_dir)
	else:
		_respawn_and_grant_immunity()

func _respawn_and_grant_immunity() -> void:
	var markers = get_tree().get_nodes_in_group("respawn")
	if markers.size() > 0:
		var random_marker = markers[randi() % markers.size()]
		global_position = random_marker.global_position
	
	velocity = Vector2.ZERO
	is_dashing = false
	is_jumping_in_area = false
	
	is_immune = true
	fight_cooldown = false 
	animated_sprite_2d.play("idle_" + last_idle_dir)
	
	var tween = create_tween().set_loops(15) 
	tween.tween_property(animated_sprite_2d, "modulate:a", 0.3, 0.1) 
	tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.1) 
	
	await get_tree().create_timer(3.0).timeout
	
	is_immune = false
	animated_sprite_2d.modulate.a = 1.0

func lose_life(amount: int) -> void:
	current_lives -= amount
	emit_signal("lives_updated", player_id, current_lives)
	print("Jugador ", player_id, " pierde una vida. Vidas restantes: ", current_lives)
	
	if current_lives <= 0:
		die()

func die() -> void:
	print("Jugador ", player_id, " eliminado por completo")
	
	# Desactivamos el movimiento y marcamos que ya no está en pelea
	can_move = false
	is_in_fight = false
	velocity = Vector2.ZERO
	
	# Reproducimos la animación de muerte
	animated_sprite_2d.play("dead")
	dead.visible=true
	var tween = create_tween()
	
	# Le decimos que anime la propiedad "position"
	# Destino: su position actual + Vector2(0, -150) (150 píxeles hacia arriba)
	# Duración: 1.5 segundos
	tween.tween_property(self, "position", position + Vector2(0, -150), 1.5)
	
	await tween.finished
	# Esperamos a que la animación termine
	dead.visible=false
	# Cambiamos a la siguiente escena (Asegúrate de colocar la ruta correcta de tu escena)
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")

func set_climbing_state(active: bool) -> void:
	if active:
		climbable_areas_count += 1
		if velocity.y >= 0:
			is_climbing = true
			is_jumping_in_area = false
			velocity.y = 0
			velocity.x = 0
	else:
		climbable_areas_count -= 1
		if climbable_areas_count <= 0:
			climbable_areas_count = 0
			is_climbing = false
			is_jumping_in_area = false

func set_soft_gravity_state(active: bool) -> void:
	if active:
		soft_gravity_areas_count += 1
		is_in_soft_gravity = true
	else:
		soft_gravity_areas_count -= 1
		if soft_gravity_areas_count <= 0:
			soft_gravity_areas_count = 0
			is_in_soft_gravity = false

func _on_fight_trigger_area_body_entered(body: Node2D) -> void:
	if not can_move or is_immune:
		return
		
	if body is CharacterBody2D and body != self and body.get("player_id") != self.player_id:
		if body.get("is_immune") == true:
			return
			
		if body.has_method("start_qte_fight_with"):
			var contact_point = (global_position + body.global_position) / 2.0
			start_qte_fight_with(body, contact_point)

func start_qte_fight_with(opponent: CharacterBody2D, contact_point: Vector2) -> void:
	if is_in_fight or fight_cooldown or opponent.is_in_fight or opponent.fight_cooldown:
		return
	
	var qte_types = ["up", "down", "left", "right", "vertical", "horizontal"]
	
	var my_type = qte_types[randi() % qte_types.size()]
	var opponent_type = qte_types[randi() % qte_types.size()]
	
	self._setup_qte_state(opponent, my_type, contact_point, true)
	opponent._setup_qte_state(self, opponent_type, contact_point, false)

func _setup_qte_state(opponent_node: CharacterBody2D, qte_type: String, contact_point: Vector2, is_effect_owner: bool) -> void:
	is_in_fight = true
	current_opponent = opponent_node
	can_mash = false 
	qte_target_actions.clear()
	
	match qte_type:
		"up": qte_target_actions.append("move_up_p" + str(player_id))
		"down": qte_target_actions.append("move_down_p" + str(player_id))
		"left": qte_target_actions.append("move_left_p" + str(player_id))
		"right": qte_target_actions.append("move_right_p" + str(player_id))
		"vertical":
			qte_target_actions.append("move_up_p" + str(player_id))
			qte_target_actions.append("move_down_p" + str(player_id))
		"horizontal":
			qte_target_actions.append("move_left_p" + str(player_id))
			qte_target_actions.append("move_right_p" + str(player_id))
	
	if current_opponent.global_position.x > global_position.x:
		last_idle_dir = "right"
	else:
		last_idle_dir = "left"

	if is_effect_owner:
		if fight_effect_sprite:
			fight_effect_sprite.top_level = true 
			fight_effect_sprite.global_position = contact_point
			fight_effect_sprite.visible = true
			fight_effect_sprite.play("fight") 
		self.visible = false
		current_opponent.visible = false

	emit_signal("qte_started", player_id, qte_type)

	await get_tree().create_timer(0.6).timeout
	can_mash = true

func start_game() -> void:
	can_move = true
	
	
	
