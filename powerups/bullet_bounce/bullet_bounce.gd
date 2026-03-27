extends Area2D

@onready var player = %Player

func _on_player_interaction():
	player.shouldBounce = true
	queue_free()
