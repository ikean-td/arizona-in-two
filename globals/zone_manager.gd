extends Node
## An autoloaded node which manages [Zone] scenes.
##
## This node has functions to display and change out [Zone] scenes to create
## multiple area divisions in one world.


## The possible zone directions.[br]
## [Zone] nodes use these directions to mark which direction the player goes to
## get to a new zone.[br]
## For instance, the [member Zone.left_zone_location] property maps to the
## [constant LEFT] value.[br]
## NOTE: The [constant NONE] direction is used when there is no previous scene.
## This indicates that no repositioning should be done in [method change_zone].
enum ZONE_DIRECTION {
	LEFT,
	UP,
	RIGHT,
	DOWN,
	NONE,
}


## Holds modified zones temporarily in memory.[br][br]
## Pairs are formatted as their root node name as a [StringName] to their root
## [Zone] node.
var modified_zones: Dictionary[StringName, Zone]


## Changes the current zone to the next zone, specified by [param new_zone_packed]
## and then repositions the player near the corresponding teleport in the new zone
## based on [param direction].[br]
## NOTE: If [param direction] is [constant NONE], then the default position, or
## the original position of the player in the zone scene, is used.
func change_zone(new_zone_packed: PackedScene, direction: ZONE_DIRECTION) -> void:
	# Pause processing (avoid weird intermediate processing)
	get_tree().paused = true
	
	# Save player effects if there was a previous zone
	var original_effects: Dictionary
	if direction != ZONE_DIRECTION.NONE:
		# Get the original player from the current scene
		var original_player: CharacterBody2D = get_tree().current_scene.find_child("Player", false)
		
		# Get effects
		original_effects = get_player_effects(original_player)
	
	# Save the modified zone temporarily if there was a previous zone
	if direction != ZONE_DIRECTION.NONE:
		# Save a copy in memory
		var modified_zone_root: Zone = get_tree().current_scene
		modified_zones[modified_zone_root.name] = modified_zone_root
		
		# Remove from the current scene tree, but do not delete the node
		modified_zone_root.get_parent().call_deferred("remove_child", modified_zone_root)
	
	
	# Instantiate and change to the new zone
	# (NOTE: change_scene_to_node is used to keep a copy of the scene)
	var new_zone: Zone = new_zone_packed.instantiate()
	
	# Check if the new zone has a modified version saved
	if new_zone.name in modified_zones:
		# Switch to the modified root
		new_zone = modified_zones[new_zone.name]
	
	get_tree().call_deferred("change_scene_to_node", new_zone)
	await get_tree().scene_changed
	
	
	# Get the player node in the new scene
	var player: CharacterBody2D = new_zone.find_child("Player", false)
	
	# Assert for debugging when a player node is not found in the new scene
	# as assert statements are removed in production builds
	assert(player != null, "Player node not found in the new Zone scene!")
	
	# Readd player effects if they were saved
	if direction != ZONE_DIRECTION.NONE:
		apply_player_effects(player, original_effects)
	
	
	# Move the player close to the opposite transition location
	
	# NOTE: The CollisionShape2D node is assumed to be named "CollisionShape2D"
	var collider_position: Vector2
	var offset: Vector2
	
	# Get the collider and calculate which direction it should go in
	match direction:
		# Left -> Right
		ZONE_DIRECTION.LEFT:
			# NOTE: A 2x multiplier is used to further distance the player
			# offset (x) = -1 * width of the CollisionShape2D
			var collider: CollisionShape2D = new_zone.right_zone_area.find_child("CollisionShape2D")
			collider_position = collider.position
			offset = Vector2(-2 * collider.shape.get_rect().size.x, 0)
		
		# Up -> Down
		ZONE_DIRECTION.UP:
			# offset (y) = -1 * height of the CollisionShape2D
			var collider: CollisionShape2D = new_zone.down_zone_area.find_child("CollisionShape2D")
			collider_position = collider.position
			offset = Vector2(0, -2 * collider.shape.get_rect().size.y)
		
		# Right -> Left
		ZONE_DIRECTION.RIGHT:
			# offset (x) = width of the CollisionShape2D
			var collider: CollisionShape2D = new_zone.left_zone_area.find_child("CollisionShape2D")
			collider_position = collider.position
			offset = Vector2(2 * collider.shape.get_rect().size.x, 0)
		
		# Down -> Up
		ZONE_DIRECTION.DOWN:
			# offset (y) = height of the CollisionShape2D
			var collider: CollisionShape2D = new_zone.up_zone_area.find_child("CollisionShape2D")
			collider_position = collider.position
			offset = Vector2(0, 2 * collider.shape.get_rect().size.y)
		
		# Handle NONE direction (pass through the current player position)
		ZONE_DIRECTION.NONE:
			collider_position = player.position
			offset = Vector2.ZERO
	
	# Set the player position (area_position + offset)
	player.position = collider_position + offset
	
	
	# Adjust the camera's limits
	# NOTE: It's assumed that Camera2D will be a direct child node under the player node
	var camera: Camera2D = player.find_child("Camera2D", false)
	new_zone.adjust_camera_limits(camera)
	
	# Snap the camera to the new location
	camera.reset_smoothing()
	
	
	# Resume processing
	get_tree().paused = false


## Returns a [Dictionary] containing the effects that the player currently has.[br]
## This return value can be used to add effects back onto the player via [method apply_player_effects].
func get_player_effects(player: CharacterBody2D) -> Dictionary:
	var effects := Dictionary()
	
	# Save effects saved as booleans
	effects["BOUNCE_EFFECT"] = player.bounce_powerup
	effects["SHOTGUN_EFFECT"] = player.shotgun_powerup
	
	# Save the remaining duration on these effects
	effects["BOUNCE_REMAINING"] = player.find_child("BouncesPowerTimer").time_left
	effects["SHOTGUN_REMAINING"] = player.find_child("ShotgunPowerTimer").time_left
	
	# Save effects which directly modify attributes
	effects["RAPID_FIRE_MULTIPLIER"] = player.shot_speed_multiplier
	effects["SPEED_MULTIPLIER"] = player.speedMulti
	
	return effects


## Adds effects from the [Dictionary] output from [method get_player_effects]
## onto the player.
func apply_player_effects(player: CharacterBody2D, effects: Dictionary) -> void:
	# Load effects saved as booleans
	player.bounce_powerup = effects["BOUNCE_EFFECT"]
	player.shotgun_powerup = effects["SHOTGUN_EFFECT"]
	
	# If any effects were occuring, update their remaining duration and start their timer
	if effects["BOUNCE_EFFECT"]:
		var timer: Timer = player.find_child("BouncesPowerTimer")
		_restart_effect_timer(timer, effects["BOUNCE_REMAINING"])
	
	if effects["SHOTGUN_EFFECT"]:
		var timer: Timer = player.find_child("ShotgunPowerTimer")
		_restart_effect_timer(timer, effects["SHOTGUN_REMAINING"])
	
	# Apply modified attributes
	player.shot_speed_multiplier = effects["RAPID_FIRE_MULTIPLIER"]
	player.speedMulti = effects["SPEED_MULTIPLIER"]


## Restarts the effect timer with [param remaining_time] as [member Timer.wait_time].
## After the timer ends, the original [member Timer.wait_time] is restored.[br]
## This is used in [method apply_player_effects] to restart effect timers.
func _restart_effect_timer(timer: Timer, remaining_time: float) -> void:
	var original_time := timer.wait_time
	timer.wait_time = remaining_time
	
	# Use the copy of the normal duration to fix the duration
	timer.timeout.connect(
			func(): timer.wait_time = original_time
	)
	
	# Start the timer
	timer.start()
