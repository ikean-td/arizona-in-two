extends Control

func _ready() -> void:
	pass # Replace with function body.

func _on_exit_pressed() -> void:
	var game: PackedScene = load("res://Menu UI/menu.tscn")
	SceneSwitcher.switch_scene(game)
