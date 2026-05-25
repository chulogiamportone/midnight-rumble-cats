extends Area2D

@export var fall_duration: float = 0.3

# Shader para el recorte de abajo hacia arriba
var clip_shader_code = """
shader_type canvas_item;
uniform float clip_percent : hint_range(0.0, 1.0) = 1.0;
void fragment() {
	if (UV.y > clip_percent) {
		discard;
	}
}
"""


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.get("is_dead") == false:
		_handle_pit_fall(body)

func _handle_pit_fall(player: CharacterBody2D) -> void:
	player.can_move = false
	player.velocity = Vector2.ZERO
	player.is_dead = true
	
	var original_pos = player.global_position
		

	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(player, "global_position", global_position, fall_duration)
	
	await tween.finished
	
	player.global_position = original_pos

	
	if player.current_lives > 1:
		player.lose_life(1)
		player.current_health = player.max_health
		player.emit_signal("health_updated", player.player_id, player.current_health, player.max_health)
		
		if player.has_method("_temporary_death"):
			player._temporary_death()
	else:
		player.lose_life(1)
		_teleport_to_other_player(player)

func _teleport_to_other_player(dead_player: CharacterBody2D) -> void:
	var players = get_tree().get_nodes_in_group("players")
	var other_player: CharacterBody2D = null
	
	for p in players:
		if p != dead_player and p is CharacterBody2D:
			other_player = p
			break
			
	if other_player != null:
		var offset_x = 100.0
		if other_player.animated_sprite_2d.flip_h or other_player.last_idle_dir == "left":
			offset_x = -100.0
			
		dead_player.global_position = other_player.global_position + Vector2(offset_x, 0)
		_stop_player_movement(dead_player)

func _stop_player_movement(player: CharacterBody2D) -> void:
	player.velocity = Vector2.ZERO
	if player.has_method("set_climbing_state"): 
		player.is_dashing = false
		player.is_jumping_in_area = false
		player.is_climbing = false
