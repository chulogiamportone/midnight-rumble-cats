extends CharacterBody2D

@export var player_id: int = 1

@export var speed: float = 300.0
@export var climb_speed: float = 200.0
@export var jump_velocity: float = -500.0
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.2
@export var max_health: int = 100
@export var max_slip_speed: float = 80.0

var current_health: int
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

var last_idle_dir: String = "right" # Guarda la última dirección para el Idle de 4 posiciones

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	current_health = max_health
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
	_check_climb_entry()
	_handle_jump_recovery()
	
	if is_dashing:
		_handle_dash(delta)
	elif is_climbing:
		_handle_climbing()
	else:
		if not is_on_floor():
			velocity.y += gravity * delta
			# Limitador de velocidad vertical para efecto de deslizamiento
			if is_in_soft_gravity and velocity.y > max_slip_speed:
				velocity.y = max_slip_speed
		_handle_movement()
		_handle_actions()

	move_and_slide()
	_update_animations() # <-- Lógica de animación centralizada

func _update_animations() -> void:
	# Anulamos el flip_h del movimiento para no distorsionar tus nuevos sprites direccionales
	animated_sprite_2d.flip_h = false 

	# 1. Prioridad máxima: Acciones que bloquean otras animaciones
	if is_attacking:
		# animated_sprite_2d.play("attack")
		return
		
	if is_dashing:
		# animated_sprite_2d.play("dash")
		return

	# Actualizamos la memoria del IDLE (4 posiciones) basándonos en la velocidad actual
	if velocity != Vector2.ZERO:
		if abs(velocity.x) > abs(velocity.y):
			last_idle_dir = "right" if velocity.x > 0 else "left"
		elif abs(velocity.y) > abs(velocity.x):
			last_idle_dir = "down" if velocity.y > 0 else "up"

	# 2. Prioridad media: Escalada (8 Direcciones)
	if is_climbing:
		if velocity != Vector2.ZERO:
			# Llama a la función que arma el nombre (ej. "walk_up_left")
			animated_sprite_2d.play("walk_" + _get_8way_direction(velocity))
		else:
			animated_sprite_2d.play("idle_" + last_idle_dir)
		return

	# 3. Prioridad estándar: Suelo (Solo Izquierda/Derecha) y Aire
	if is_on_floor():
		if velocity.x == 0:
			animated_sprite_2d.play("idle_" + last_idle_dir)
		else:
			var dir = "right" if velocity.x > 0 else "left"
			animated_sprite_2d.play("walk_" + dir)
	else:
		pass
		# animated_sprite_2d.play("jump") # Cuando estés en el aire

# Función auxiliar que detecta las 8 direcciones según el vector de velocidad
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

func take_damage(amount: int) -> void:
	current_health -= amount
	print("Jugador ", player_id, " recibe daño. Salud restante: ", current_health)
	if current_health <= 0:
		die()

func die() -> void:
	print("Jugador ", player_id, " eliminado")
	queue_free()

# --- MÉTODOS PARA SEÑALES DE AREA2D DEL MAPA ---
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
