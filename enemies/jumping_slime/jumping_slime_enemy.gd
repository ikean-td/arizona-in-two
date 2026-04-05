extends CharacterBody2D
## A jumping slime enemy.
##
## When placed in a scene, the slime's movement calculations are paused until
## the rectangle defined in [VisibleOnScreenEnabler2D] enters the screen.[br][br]
##
## When movement is enabled, the slime will move randomly in its idle state and
## will damage the player on contact. If a [member chase_area] exists, then the
## slime will "chase" the player when they enter the [Area2D]. At intervals
## specified by [member unique_attack_timer], the slime will also perform a
## unique "jump" attack onto the player or towards the player.[br][br]
##
## NOTE: During the slime's jump, "horizontal" movement refers to movement
## across the x-axis and y-axis (2D) while "vertical" movement refers to
## movement along the z-axis (3D calculations).


## The slime's idle movement speed.
@export var idle_speed: float = 10.0

## The slime's chase speed.
@export var chase_speed: float = 32.0

## How much damage the slime will cause upon player collision.
@export var attack_damage: float = 30.0

## The suffix used for idle animations in the [AnimatedSprite2D].
@export var idle_animation_suffix: StringName = "_idle"

## The area to monitor for player chase interactions.
@onready var chase_area : Area2D = $ChaseArea


# Physics process variables

## The target position the slime will move towards.[br]
## Updated in [method _physics_process].
var target_position := position

## The angle that the target position is located at from the current position.[br]
## Set when the random position is regenerated in [method _generate_random_position]
var target_angle_vector: Vector2

## Whether the target position is to the left of the current position.
## Used to check when the slime has reached the [member target_position].[br]
## Updated in [method _physics_process].
var target_position_on_left := false


## The player node.[br]
## Set when the player enters the [member chase_area], but resets when
## the slime goes off screen.
var player_node: CharacterBody2D = null


# Controls the delay between idle movement cycles
@onready var _idle_movement_timer: Timer = $IdleMovementTimer

# Sprite
@onready var _animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


#region Jumping Slime Variables
@export_group("Jump Attack")

## The angle that the slime will jump at in degrees.
@export var jump_angle: float = 45.0

## The initial velocity of the slime's horizontal movement during its jump attack.[br][br]
## NOTE: "Horizontal" in this context refers to movement along the x-axis and y-axis.
@export var horizontal_magnitude: float = 96.0

## The initial velocity of the slime's vertical movement during its jump attack.[br][br]
## NOTE: "Vertical" in this context refers to movement along the z-axis. See
## [member position_z].
@export var vertical_magnitude: float = 64.0

## The maximum distance, in pixels, that the slime can jump.[br][br]
## NOTE: To disable this limit, set the maximum distance to be either 0.0
## or a negative value.
@export var max_jump_distance: float = 180.0


## The calculated vertical position of the slime along the z-axis.[br][br]
## This value is set and used during the slime's jump attack in [method _physics_process].
var position_z: float = 0.0

## How long a jump attack is calculated to take before finishing.[br][br]
## Updated in [method _physics_process] at the start of a jump attack.
var jump_time: float

## How much time has elapsed since the start of a jump attack.[br]
## Used to calculate the position of the slime during a jump.[br][br]
## Updated in [method _physics_process] during a jump attack.
var elapsed_time: float = 0.0

## The normalized vector for the slime's horizontal movement across the x-axis and y-axis.
var horizontal_vector: Vector2

## The magnitude of the force of gravity during the slime's jump attack.
var gravity_magnitude: float

## The starting position of the slime when the jump attack was started.
var original_pos: Vector2

## Indicates whether a unique jump attack is occurring.
var in_jump := false


## Controls the delay between jump attacks.
@onready var unique_attack_timer: Timer = $UniqueAttackTimer
#endregion


# Connect to the chase Area2D if it was set
func _ready() -> void:
	chase_area.body_entered.connect(_on_area_2d_body_entered)


# NOTE: When the slime moves too far off screen, movement calculations are
# automatically stopped by the VisibleOnScreenEnabler2D
# Move and animate the slime
func _physics_process(delta: float) -> void:
	# Check collisions
	for i in get_slide_collision_count():
		var obj := get_slide_collision(i).get_collider()
		
		# Player check
		if obj is CharacterBody2D:
			if obj.is_in_group("Player"):
				# TODO: Damage function
				#obj.damage(damage)
				pass
	
	# If the idle movement timer is running, skip movement calculations
	if not _idle_movement_timer.is_stopped():
		return
	
	
	if player_node != null:
		# Check if a unique attack can be started
		if unique_attack_timer.is_stopped():
			if not in_jump:
				# Set attack started flag
				in_jump = true
				
				# Set the original position
				original_pos = position
				
				# Get the position of the top of the player's sprite
				var player_sprite: Sprite2D = player_node.get_node("Sprite")
				var sprite_height := player_sprite.get_rect().size.y * player_sprite.scale.y
				var player_head := player_node.position - Vector2(0, sprite_height / 2)
				
				# Get the vector from the slime to the player
				var vector_to_player := (player_head - position)
				
				var travel_distance := vector_to_player.length()
				horizontal_vector = vector_to_player.normalized()
				
				# Limit the distance to be within the specified bounds
				if max_jump_distance > 0.0 and travel_distance > max_jump_distance:
					travel_distance = max_jump_distance
				
				# Rearranged from projectile motion formula
				
				# Calculate how long the jump will take
				jump_time = ( travel_distance ) / ( horizontal_magnitude * cos(deg_to_rad(jump_angle)) )
				
				# Calculate what gravity should be used to balance the jump magnitude and angle
				gravity_magnitude = ( vertical_magnitude * sin(deg_to_rad(jump_angle)) * jump_time ) \
						/ ( 0.5 * jump_time*jump_time )
			
			# Update the elapsed time
			elapsed_time += delta
			
			# Calculate the horizontal and vertical displacements (projectile motion)
			var horizontal := (horizontal_magnitude * cos(deg_to_rad(jump_angle)) * elapsed_time) \
					* horizontal_vector
			
			var vertical := (vertical_magnitude * sin(deg_to_rad(jump_angle)) * elapsed_time) \
					- (0.5 * gravity_magnitude * elapsed_time*elapsed_time)
			
			# Update the "horizontal" position
			position = original_pos + horizontal
			
			# Update the fake z-coordinate
			position_z = vertical
			
			# Add the z-coordinate to the y-coordinate to give the illusion of 3D
			position.y -= position_z
			
			# If the jump is completed, then start the cooldown timer
			if elapsed_time > jump_time:
				unique_attack_timer.start()
				in_jump = false
				elapsed_time = 0.0
		else:
			# Move towards the player (chase sequence)
			velocity = chase_speed * (player_node.position - position).normalized()
	else:
		# Move randomly (idle movement)
		
		# Calculate distance from the target position
		var offset_x := target_position.x - position.x
		
		# Check if the target position was passed
		if (
				# Moved from right to left
				target_position_on_left and offset_x >= 0.0
				
				# Moved from left to right
				or not target_position_on_left and offset_x <= 0.0
		):
			# Regenerate target position and use idle animation
			_idle_movement_timer.start()
			
			# Play an idle animation if one is not already playing
			if not _animated_sprite_2d.animation.ends_with(idle_animation_suffix):
				_animated_sprite_2d.play(_animated_sprite_2d.animation + idle_animation_suffix)
		
		# Update speed
		velocity = idle_speed * target_angle_vector
	
	# Finalize movement
	move_and_slide()


## Generates a [Vector2] in a random direction from the current position within
## the specified distance bounds (inclusive).
func _generate_random_position(dist_min: float, dist_max: float) -> Vector2:
	# Vector in random direction
	var rand_dir := Vector2.from_angle(randf_range(0, 2*PI))
	target_angle_vector = rand_dir
	
	# Random distance within bounds, multiply vector
	var rand_dist := randf_range(dist_min, dist_max)
	rand_dir *= rand_dist
	
	# Return vector offset by position
	return position + rand_dir


# Idle movement cycle
func _on_idle_movement_timer_timeout() -> void:
	target_position = _generate_random_position(15.0, 25.0)
	target_position_on_left = (target_position.x - position.x <= 0.0)
	
	# Set new animation
	if abs(target_angle_vector.x) >= abs(target_angle_vector.y):
		# More horizontal movement than vertical movement
		if target_angle_vector.x >= 0:
			# Moving right
			_animated_sprite_2d.play("right")
		else:
			# Moving left
			_animated_sprite_2d.play("left")
	else:
		# More vertical movement than horizontal movement
		if target_angle_vector.y >= 0:
			# Moving down (positive y)
			_animated_sprite_2d.play("down")
		else:
			# Moving up (negative y)
			_animated_sprite_2d.play("up")


# Reset player variable on screen exit
func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	player_node = null


# Set player variable on entering the Area2D
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Player in area
	if body is CharacterBody2D and body.is_in_group("Player"):
		player_node = body
		
		# Stop idle movement
		_idle_movement_timer.stop()

func damaged_sequence():
	#damage animation
	pass

func suicide():
	#death animation
	queue_free()
