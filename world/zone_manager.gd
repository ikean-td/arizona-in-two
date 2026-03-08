class_name ZoneManager
extends Node2D
## A node which manages [Zone] scenes.
##
## This node has functions to display and change out [Zone] scenes to create
## multiple area divisions in one world.


## The possible zone directions.[br]
## [Zone] nodes use these directions to mark which direction the player goes to
## get to a new zone.[br]
## For instance, the [member Zone.left_zone_location] property maps to the LEFT value.
enum ZONE_DIRECTION {
	LEFT,
	UP,
	RIGHT,
	DOWN,
}

## Base file path to where the zones are located
const ZONE_PATH: StringName = "res://world/"

## The first [Zone] scene to show when [method _ready] is ran.
@export var starting_zone: StringName


## The player node.[br]
## It is assumed that a [Camera2D] node will be under this node.
## Found and set in [method _ready].
var player: Node2D = null


# Gets the player node, shows the starting zone, and then adjusts the camera
func _ready() -> void:
	# Find the player in the tree
	player = get_parent().find_child("Player")
	
	# Load the starting zone (Use call_deferred to avoid weird error messages)
	#_change_zone(null, ZONE_DIRECTION.LEFT)
	call_deferred("_change_zone", null, ZONE_DIRECTION.LEFT)


## Changes the current zone to the next zone, specified by [param direction] and
## then moves the player to the position specified at the new [Zone.default_spawn].[br]
## NOTE: When [param current_zone] is null, the [member starting_zone] scene is loaded.
func _change_zone(current_zone: Zone, direction: ZONE_DIRECTION) -> void:
	# Pause processing (avoid weird intermediate processing)
	get_tree().paused = true
	
	# Get the new zone
	var new_zone: Zone = null
	var new_zone_filename: StringName = ""
	
	# If no current zone was given, then load the starting zone
	# Otherwise, load by matching the provided direction with the current zone's properties
	if current_zone == null:
		new_zone_filename = starting_zone
	else:
		match direction:
			# Match the direction
			ZONE_DIRECTION.LEFT:
				new_zone_filename = current_zone.left_zone_filename
			ZONE_DIRECTION.UP:
				new_zone_filename = current_zone.up_zone_filename
			ZONE_DIRECTION.RIGHT:
				new_zone_filename = current_zone.right_zone_filename
			ZONE_DIRECTION.DOWN:
				new_zone_filename = current_zone.down_zone_filename
		
		# Remove the existing zone
		current_zone.queue_free()
	
	# Instantiate and add the new zone
	var new_zone_packed: PackedScene = load(ZONE_PATH + new_zone_filename + ".tscn")
	new_zone = new_zone_packed.instantiate()
	add_child(new_zone)
	
	# Position the new zone
	new_zone.position = Vector2(0, 0)
	
	if current_zone == null:
		# Move the player to the default spawn position
		player.position = new_zone.default_spawn.position
	else:
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
		
		# Set the player position (area_position + offset)
		player.position = collider_position + offset
	
	
	# Adjust the camera's limits
	# NOTE: It's assumed that Camera2D will be a direct child node under the player node
	var camera: Camera2D = player.find_child("Camera2D", false)
	new_zone.adjust_camera_limits(camera)
	
	# Snap the camera to the new location
	camera.reset_smoothing()
	
	# Connect to the interact signal
	new_zone.change_area_interacted.connect(_on_zone_change_area_interacted)
	
	# Resume processing
	get_tree().paused = false


## Connects to [signal Zone.change_area_interacted] and passes it to [method _change_zone].
func _on_zone_change_area_interacted(calling_zone: Zone, direction: ZoneManager.ZONE_DIRECTION) -> void:
	#_change_zone(calling_zone, direction)
	call_deferred("_change_zone", calling_zone, direction)
