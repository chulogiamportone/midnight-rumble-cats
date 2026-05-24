extends Camera2D

@export var player_1: Node2D
@export var player_2: Node2D

@export var smooth_speed: float = 8.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 1.2
@export var zoom_margin: float = 1.5
@export var zoom_speed: float = 5.0

# --- NUEVAS VARIABLES PARA LA FATALITY ---
@export var fatality_zoom: float = 1.80 # El nivel de zoom cercano para la fatality (más alto = más cerca)
var is_in_fatality: bool = false

var base_resolution: Vector2

func _ready() -> void:
	base_resolution = get_viewport_rect().size

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_1) or not is_instance_valid(player_2):
		return
	
	_update_position(delta)
	_update_zoom(delta)

func _update_position(delta: float) -> void:
	var target_position: Vector2 = (player_1.global_position + player_2.global_position) / 2.0
	if is_in_fatality:
		target_position.y=target_position.y-100
	global_position = global_position.lerp(target_position, smooth_speed * delta)

func _update_zoom(delta: float) -> void:
	var target_zoom_value: float
	
	if is_in_fatality:
		# Si estamos en fatality, forzamos el zoom cercano configurado
		target_zoom_value = fatality_zoom
		
	else:
		# Cálculo de distancia absoluto en ambos ejes (Tu lógica original)
		var distance_x: float = abs(player_1.global_position.x - player_2.global_position.x)
		var distance_y: float = abs(player_1.global_position.y - player_2.global_position.y)
		
		# Cálculo de la proporción de zoom necesaria según la resolución
		var zoom_x: float = base_resolution.x / (distance_x * zoom_margin) if distance_x > 0 else max_zoom
		var zoom_y: float = base_resolution.y / (distance_y * zoom_margin) if distance_y > 0 else max_zoom
		
		# Selección del menor valor para garantizar que ambos ejes permanezcan visibles
		target_zoom_value = clamp(min(zoom_x, zoom_y), min_zoom, max_zoom)
	
	var target_zoom: Vector2 = Vector2(target_zoom_value, target_zoom_value)
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)
