extends Node

func switch_scene(scene): # Accepts a PackedScene parameter
	var node = scene.instantiate() # Gets the node of the PackedScene
	# Changes the scene to the node
	get_tree().call_deferred("change_scene_to_file", node.get_scene_file_path())
