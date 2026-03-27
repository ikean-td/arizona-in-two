extends Area2D

@onready var player = %Player

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.gain_powerup("bounces")
	queue_free()
