extends Control

@onready var background_1: TextureRect = $"../TextureRect"
@onready var background_2: TextureRect = $TextureRect
@onready var animated_sprite_2d: AnimatedSprite2D = $TextureRect/C1/AnimatedSprite2D
@onready var animated_sprite_2d2: AnimatedSprite2D = $TextureRect/C2/AnimatedSprite2D
@onready var animated_sprite_2d3: AnimatedSprite2D = $TextureRect/C3/AnimatedSprite2D

@onready var label_1: Label = $TextureRect/C1/Label1
@onready var label_2: Label = $TextureRect/C2/Label2
@onready var label_3: Label = $TextureRect/C3/Label3

@onready var slots: Array = [$TextureRect/C1/ColorRect, $TextureRect/C2/ColorRect, $TextureRect/C3/ColorRect]
@onready var sprites: Array[AnimatedSprite2D] = [animated_sprite_2d, animated_sprite_2d2, animated_sprite_2d3]
@onready var labels: Array[Label] = [label_1, label_2, label_3]

@onready var cursor_p1: Control = $TextureRect/CursorP1
@onready var cursor_p2: Control = $TextureRect/CursorP2

@onready var carga: Control = $"../Carga"
@onready var carga_animation: AnimatedSprite2D = $"../Carga/AnimatedSprite2D"

var characters: Array[String] = ["blaqui", "orange", "whity"]

var p1_index: int = 0
var p2_index: int = 2

var p1_locked: bool = false
var p2_locked: bool = false

var color_p1: Color = Color.RED
var color_p2: Color = Color.BLUE
var color_both: Color = Color.PURPLE
var color_default: Color = Color.WHITE

var main_scene_path: String = "res://Scenes/chuletita.tscn"

func _ready() -> void:
	background_2.modulate.a = 0.0
	_update_cursors()

func ejecutar_transicion(duracion_segundos: float = 1.0) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(background_2, "modulate:a", 1.0, duracion_segundos)

func _process(_delta: float) -> void:
	if background_2.modulate.a < 1.0:
		return
	_handle_input()

func _handle_input() -> void:
	if not p1_locked:
		if Input.is_action_just_pressed("move_left_p1"):
			p1_index = _get_next_valid_index(p1_index, -1, p2_index, p2_locked)
			_update_cursors()
		elif Input.is_action_just_pressed("move_right_p1"):
			p1_index = _get_next_valid_index(p1_index, 1, p2_index, p2_locked)
			_update_cursors()
		elif Input.is_action_just_pressed("jump_p1"):
			p1_locked = true
			if p2_index == p1_index and not p2_locked:
				_bump_player(2)
			_update_cursors()
			_update_animations()
			_check_start()

	if not p2_locked:
		if Input.is_action_just_pressed("move_left_p2"):
			p2_index = _get_next_valid_index(p2_index, -1, p1_index, p1_locked)
			_update_cursors()
		elif Input.is_action_just_pressed("move_right_p2"):
			p2_index = _get_next_valid_index(p2_index, 1, p1_index, p1_locked)
			_update_cursors()
		elif Input.is_action_just_pressed("jump_p2"):
			p2_locked = true
			if p1_index == p2_index and not p1_locked:
				_bump_player(1)
			_update_cursors()
			_update_animations()
			_check_start()

func _get_next_valid_index(current: int, direction: int, other_idx: int, is_other_locked: bool) -> int:
	var next_idx = current + direction
	while next_idx >= 0 and next_idx < slots.size():
		if is_other_locked and next_idx == other_idx:
			next_idx += direction
		else:
			return next_idx
	return current

func _bump_player(player_num: int) -> void:
	if player_num == 1:
		for i in range(slots.size()):
			if i != p2_index:
				p1_index = i
				break
	elif player_num == 2:
		for i in range(slots.size()):
			if i != p1_index:
				p2_index = i
				break

func _update_cursors() -> void:
	if p1_index < slots.size():
		cursor_p1.global_position = slots[p1_index].global_position
	if p2_index < slots.size():
		cursor_p2.global_position = slots[p2_index].global_position
	_update_animations()

func _update_animations() -> void:
	for i in range(sprites.size()):
		var sprite = sprites[i]
		var label = labels[i]
		
		var is_p1_here = (p1_index == i)
		var is_p2_here = (p2_index == i)
		
		var is_locked_here = (is_p1_here and p1_locked) or (is_p2_here and p2_locked)
		var is_hovered_here = (is_p1_here and not p1_locked) or (is_p2_here and not p2_locked)
		
		if is_locked_here:
			sprite.play("andry")
		elif is_hovered_here:
			sprite.play("hover")
		else:
			sprite.play("select")
			
		if is_p1_here and is_p2_here:
			label.add_theme_color_override("font_color", color_both)
		elif is_p1_here:
			label.add_theme_color_override("font_color", color_p1)
		elif is_p2_here:
			label.add_theme_color_override("font_color", color_p2)
		else:
			label.add_theme_color_override("font_color", color_default)

func _check_start() -> void:
	if p1_locked and p2_locked:
		await get_tree().create_timer(2.0).timeout
		self.visible=false
		_load_screen()
		
func _load_screen()->void:
	carga.visible=true
	carga_animation.play("cute")
	await get_tree().create_timer(5.0).timeout
	_start_match()

func _start_match() -> void:
	carga.visible=false
	AudioManager.p1_character = characters[p1_index]
	AudioManager.p2_character = characters[p2_index]
	get_tree().change_scene_to_file(main_scene_path)
