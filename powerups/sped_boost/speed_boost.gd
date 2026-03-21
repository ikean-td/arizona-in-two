extends Area2D

@onready var player = %Player

var multiMax = 1.5 # Change in iters of 0.5 to increase max speed cap

func _on_player_interaction():
	if player.speedMulti < multiMax:
		player.speedMulti += 0.5 # Adds 0.5 to the mutli, equivalent to 50% extra speed
		queue_free()
