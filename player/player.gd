extends CharacterBody2D

@export var shot_speed_multiplier = 1

var speed: int = 70
const deceleration: int = 10
const acceleration: int = 50

const BULLET = preload("uid://c7uqco4biuu2g")
var shot_cooldown_seconds = 0.35
var time_since_last_shot = 0

func _physics_process(delta: float) -> void:
	movement(delta) # Movement function (Others can be added below)
	
	shoot(delta)
	
	move_and_slide()

func movement(delta):
	# Maps input to correct vector for velocity
	var inputDir: Vector2 = Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown")
	
	if inputDir:
		# Slowly increases the speed
		velocity = lerp(velocity, speed * inputDir, delta * acceleration)
		
		# Finds which direction in the X Axis
		var horizontal := "" 
		if inputDir.x < 0: horizontal = "l"
		if inputDir.x > 0: horizontal = "r"
		
		# Finds which direction in the Y Axis
		var vertical := ""
		if inputDir.y < 0: vertical = "u"
		if inputDir.y > 0: vertical = "d"
		
		# Logic for Animated Sprites
		if horizontal == "l":
			match vertical:
				"u":
					pass # Animated sprite for Left + Up
				"d":
					pass # Animated sprite for Left + Down
				"":
					pass # Animated sprite for Left ONLY
		elif horizontal == "r":
			match vertical:
				"u":
					pass # Animated sprite for Right + Up
				"d":
					pass # Animated sprite for Right + Down
				"":
					pass # Animated sprite for Right ONLY
		else:
			match vertical:
				"u":
					pass # Animated sprite for Up ONLY
				"d":
					pass # Animated sprite for Down ONLY
		
	else:
		# Slowly decreases the speed of the player
		velocity = lerp(velocity, Vector2(0, 0), delta * deceleration)

func shoot(delta):
	# Check if can shoot
	if time_since_last_shot < shot_cooldown_seconds * (1.0/shot_speed_multiplier):
		time_since_last_shot += delta
		return
	# Maps input to correct vector for velocity
	var inputDir: Vector2 = Input.get_vector("ShootLeft", "ShootRight", "ShootUp", "ShootDown")
	
	if inputDir:
		
		time_since_last_shot = 0
		
		var instance = BULLET.instantiate()
		get_parent().add_child(instance)
		
		# sets bullet direction
		instance.direction = inputDir
		
		instance.position = position
		
		time_since_last_shot += delta
