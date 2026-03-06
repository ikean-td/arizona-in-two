extends Control

func _ready() -> void:
	pass

func _on_start_pressed() -> void:
	var game: PackedScene = load("res://main/main.tscn")
	SceneSwitcher.switch_scene(game)

func _on_settings_pressed() -> void:
	var setting: PackedScene = load("res://Menu UI/settings.tscn")
	SceneSwitcher.switch_scene(setting)

func _on_quit_pressed() -> void:
	get_tree().quit()
