extends Node2D

var spawn_interval: float = 15.0
var max_spawn_attempts: int = 50 # Límite de iteraciones para buscar un espacio vacío

var scene_life: PackedScene
var scene_fall: PackedScene
var scene_double_attack: PackedScene

var area_tejas: Area2D
var area_techo: Area2D
var area_tanque: Area2D

var spawn_timer: Timer

func _ready() -> void:
	randomize() 
	
	area_tejas = get_node_or_null("../Build/Tejas")
	area_techo = get_node_or_null("../Build/Techo")
	area_tanque = get_node_or_null("../Build/Tanque")
	
	scene_life = preload("res://Scenes/life.tscn")
	scene_fall = preload("res://Scenes/fall.tscn")
	scene_double_attack = preload("res://Scenes/double_attack.tscn")
	
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

func _on_spawn_timer_timeout() -> void:
	var item_to_spawn: PackedScene = null
	var area_to_spawn: Area2D = null
	var item_extents: Vector2 = Vector2.ZERO
	
	var item_roll = randf() * 100.0
	if item_roll < 50.0:
		# --- 50% POZOS (FALL) ---
		item_to_spawn = scene_fall
		item_extents = Vector2(200.0, 130.0) # Extents = Mitad de 400x260
		area_to_spawn = _get_random_area([area_tejas, area_techo])
		AudioManager.play_sfx("rocks")
			
	elif item_roll < 80.0:
		# --- 30% DOBLE ATAQUE ---
		item_to_spawn = scene_double_attack
		item_extents = Vector2(50.0, 50.0) # Extents = Mitad de 100x100
		
		if area_tanque and randf() < 0.05:
			area_to_spawn = area_tanque
		else:
			area_to_spawn = _get_random_area([area_tejas, area_techo])
		AudioManager.play_sfx("meow")
	else:
		# --- 20% VIDA (LIFE) ---
		item_to_spawn = scene_life
		item_extents = Vector2(50.0, 50.0) # Extents = Mitad de 100x100
		
		if area_tanque and randf() < 0.05:
			area_to_spawn = area_tanque
		else:
			area_to_spawn = _get_random_area([area_tejas, area_techo])
		AudioManager.play_sfx("food")
	if item_to_spawn != null and area_to_spawn != null:
		_try_spawn_item(item_to_spawn, area_to_spawn, item_extents)

func _get_random_area(areas: Array) -> Area2D:
	var valid_areas = []
	for a in areas:
		if a != null:
			valid_areas.append(a)
	if valid_areas.size() > 0:
		return valid_areas.pick_random()
	return null

func _try_spawn_item(item_scene: PackedScene, area: Area2D, extents: Vector2) -> void:
	var collision_polygon: CollisionPolygon2D = null
	for child in area.get_children():
		if child is CollisionPolygon2D:
			collision_polygon = child
			break
			
	if collision_polygon == null or collision_polygon.polygon.size() == 0:
		return
		
	var points = collision_polygon.polygon
	
	# 1. Calcular el bounding box del polígono
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y
	
	for pt in points:
		if pt.x < min_x: min_x = pt.x
		if pt.x > max_x: max_x = pt.x
		if pt.y < min_y: min_y = pt.y
		if pt.y > max_y: max_y = pt.y
		
	# 2. Reducir el bounding box según el tamaño exacto del objeto
	var safe_min_x = min_x + extents.x
	var safe_max_x = max_x - extents.x
	var safe_min_y = min_y + extents.y
	var safe_max_y = max_y - extents.y
	
	if safe_min_x >= safe_max_x or safe_min_y >= safe_max_y:
		push_warning("El área " + area.name + " es más pequeña que el objeto.")
		return
		
	var spawned = false
	
	# 3. Rejection Sampling: Buscar una coordenada válida
	for i in range(max_spawn_attempts):
		var rand_x = randf_range(safe_min_x, safe_max_x)
		var rand_y = randf_range(safe_min_y, safe_max_y)
		var local_pos = Vector2(rand_x, rand_y)
		
		# Validar que el punto pertenezca estructuralmente al polígono
		if Geometry2D.is_point_in_polygon(local_pos, points):
			var global_spawn_pos = collision_polygon.to_global(local_pos)
			var new_rect = Rect2(global_spawn_pos - extents, extents * 2.0)
			
			# Validar que no se superponga con otros objetos ya existentes
			if not _check_overlap(new_rect):
				var item_instance = item_scene.instantiate()
				add_child(item_instance)
				item_instance.global_position = global_spawn_pos
				spawned = true
				break
				
	if not spawned:
		print("No se encontró espacio libre tras ", max_spawn_attempts, " intentos. Omitiendo spawn.")

func _check_overlap(new_rect: Rect2) -> bool:
	for child in get_children():
		if child is Timer:
			continue
			
		var child_extents = Vector2(50.0, 50.0) # Tamaño por defecto (Life / Double Attack)
		
		# Identificar si el objeto existente es un pozo para usar sus dimensiones
		if child.scene_file_path != null and "fall" in child.scene_file_path.to_lower():
			child_extents = Vector2(200.0, 130.0)
			
		var child_rect = Rect2(child.global_position - child_extents, child_extents * 2.0)
		
		if new_rect.intersects(child_rect):
			return true
			
	return false
