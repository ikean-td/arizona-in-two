extends Area2D

@onready var player = %Player

var max_multiplier = 2

func _on_player_interaction():
	
	# Caps the increase to 2x speed
	if player.shot_speed_multiplier < max_multiplier:
		# Larger values will make it shoot faster, e.g if it shoots 1 time per sec
		# making shot_speed_multiplier = 2 will make it shoot every 0.5 seconds
		player.shot_speed_multiplier *= 2
		queue_free()
