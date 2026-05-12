extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("set_climbing_state"):
		body.set_climbing_state(true)

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("set_climbing_state"):
		body.set_climbing_state(false)
