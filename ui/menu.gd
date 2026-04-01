extends Control

func _on_start_pressed() -> void:
	var game: PackedScene = load("uid://q8fu5ytuitps")
	# Use change_zone to also fix the camera to the map's bounds
	ZoneManager.change_zone(game, ZoneManager.ZONE_DIRECTION.NONE)
	#SceneSwitcher.switch_scene(game)

func _on_settings_pressed() -> void:
	var setting: PackedScene = load("uid://cyyylb4r6n4c")
	SceneSwitcher.switch_scene(setting)

func _on_quit_pressed() -> void:
	get_tree().quit()
