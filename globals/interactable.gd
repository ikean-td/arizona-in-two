extends Node2D

@export var area: Area2D


func player_entered(_body):
	get_parent()._on_player_interaction()

func _ready():
	area.body_entered.connect(player_entered)
