class_name Zone
extends Node2D
## A node containing a section, or zone, of a single world which can connect to
## other zones of the world.
##
## Zones are loaded and unloaded by the [ZoneManager] node.[br][br]
##
## The direction on the "filename" and "area" properties indicate which
## direction the scene change goes in. For example, the [member left_zone_filename]
## property indicates that the specified zone is to the left of this zone.[br][br]
##
## "Filename" properties indicate what the new scene is called.[br]
## "Area" properties are used to create interaction areas for scene changes,
## and their [CollisionShape2D] node should be named "CollisionShape2D".


## Signals when this zone should be changed and what direction the next zone is in.
signal change_area_interacted(this_zone: Zone, direction: ZoneManager.ZONE_DIRECTION)

## Base file path for where the zones are located.
const ZONE_PATH: StringName = "res://world/"


# These directions identify which direction the scene change goes in
# The filename variable is used to set what new scene should be loaded
# The area variable is used to identify when an interaction has occurred

## The filename of for the zone to the [b]left[/b] of this zone.
@export var left_zone_filename: StringName
## The interaction area for the zone to the [b]left[/b] of this zone.
@export var left_zone_area: Area2D

## The filename for the zone [b]above[/b] this zone.
@export var up_zone_filename: StringName
## The interaction area for the zone [b]above[/b] this zone.
@export var up_zone_area: Area2D

## The filename of for the zone to the [b]right[/b] of this zone.
@export var right_zone_filename: StringName
## The interaction area for the zone to the [b]right[/b] of this zone.
@export var right_zone_area: Area2D

## The filename for the zone [b]below[/b] this zone.
@export var down_zone_filename: StringName
## The interaction area for the zone [b]below[/b] this zone.
@export var down_zone_area: Area2D


## The default spawn location, positioned at [member Node2D.position].[br]
## NOTE: This property is only required to be set for scenes which are the first
## loaded scene when the game starts.
@export var default_spawn: Node2D


# The background TileMapLayer.
# Used to update the camera limits in adjust_camera_limits().
@onready var _tile_map_layer: TileMapLayer = $BackgroundTileMapLayer


# Connect to the interaction areas
func _ready() -> void:
	if left_zone_area != null:
		_connect_location(left_zone_area, ZoneManager.ZONE_DIRECTION.LEFT)
	
	if up_zone_area != null:
		_connect_location(up_zone_area, ZoneManager.ZONE_DIRECTION.UP)
	
	if right_zone_area != null:
		_connect_location(right_zone_area, ZoneManager.ZONE_DIRECTION.RIGHT)
	
	if down_zone_area != null:
		_connect_location(down_zone_area, ZoneManager.ZONE_DIRECTION.DOWN)


## Updates the limits on the passed in [Camera2D] to match this zone's area.
func adjust_camera_limits(camera: Camera2D) -> void:
	# Get the tile size
	var tile_size := _tile_map_layer.tile_set.tile_size
	
	# Get the map rectangle
	var map_rect := _tile_map_layer.get_used_rect()
	
	# The minimum x and y values will be at the top-left corner
	var x_min := (map_rect.position.x * tile_size.x)
	var y_min := (map_rect.position.y * tile_size.y)
	
	# The maximum x and y values are offset by the rectangle's size
	# to get the bottom-right corner
	var x_max := x_min + (map_rect.size.x * tile_size.x)
	var y_max := y_min + (map_rect.size.y * tile_size.y)
	
	# Set the limits
	camera.limit_left = x_min
	camera.limit_top = y_min
	camera.limit_right = x_max
	camera.limit_bottom = y_max


## Emits the [signal change_area_interacted] signal for the [ZoneManager] node.
func _change_zone(direction: ZoneManager.ZONE_DIRECTION) -> void:
	change_area_interacted.emit(self, direction)


# Connects an Area2D's body_entered signal to the _change_zone() function
func _connect_location(location: Area2D, direction: ZoneManager.ZONE_DIRECTION) -> void:
	# Connect to the body_entered signal
	location.body_entered.connect(_on_area_2d_body_entered.bind(direction))


# Handles Area2D body_entered signals
func _on_area_2d_body_entered(body: Node2D, direction: ZoneManager.ZONE_DIRECTION) -> void:
	# Skip non-player interactions
	if not body.is_in_group("Player"):
		return
	
	_change_zone(direction)
