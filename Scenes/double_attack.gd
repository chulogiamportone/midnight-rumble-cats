extends Area2D

@export var duration: float = 10.0
@export var target_scale: float = 1.5
@export var damage_value: int = 2

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verificación técnica mediante duck typing
	if body.has_method("_setup_inputs"):
		_apply_power_up(body)

func _apply_power_up(player: Node2D) -> void:
	# 1. Ocultar el objeto y desactivar colisiones para evitar múltiples activaciones
	visible = false
	set_deferred("monitoring", false)
	
	# 2. Aplicar los efectos directamente al nodo del jugador
	player.scale = Vector2(target_scale, target_scale)
	player.set_meta("qte_damage", damage_value)
	
	# 3. Temporizador independiente dentro del objeto
	await get_tree().create_timer(duration).timeout
	
	# 4. Revertir efectos si el jugador sigue existiendo en el árbol
	if is_instance_valid(player):
		player.scale = Vector2(1.0, 1.0)
		player.remove_meta("qte_damage")
		
	# 5. Destruir la instancia del power-up
	queue_free()
