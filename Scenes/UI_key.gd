extends Control

# Ajustá estos nombres según cómo le pusiste a los sprites en tu escena

@onready var p1_key_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var p2_key_sprite: AnimatedSprite2D = $"../UI_keyP2/AnimatedSprite2D"

func _ready() -> void:
	# Arrancan invisibles
	p1_key_sprite.visible = false
	p2_key_sprite.visible = false
	
	var players = get_tree().get_nodes_in_group("players") 
	for player in players:
		_conectar_jugador(player)

func _conectar_jugador(player_node: Node) -> void:
	if not player_node.is_connected("qte_started", Callable(self, "_on_qte_started")):
		player_node.connect("qte_started", Callable(self, "_on_qte_started"))
		
	if not player_node.is_connected("qte_ended", Callable(self, "_on_qte_ended")):
		player_node.connect("qte_ended", Callable(self, "_on_qte_ended"))

# AHORA RECIBE EL PLAYER ID
func _on_qte_started(player_id: int, qte_type: String) -> void:
	if player_id == 1:
		p1_key_sprite.visible = true
		p1_key_sprite.play("key_" + qte_type) 
	elif player_id == 2:
		p2_key_sprite.visible = true
		p2_key_sprite.play("key_" + qte_type) 

func _on_qte_ended() -> void:
	# Cuando termina la pelea, apagamos las dos
	p1_key_sprite.visible = false
	p1_key_sprite.stop()
	
	p2_key_sprite.visible = false
	p2_key_sprite.stop()
