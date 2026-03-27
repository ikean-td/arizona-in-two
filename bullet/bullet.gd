extends Area2D

@export var damage = 1 #Bullet's damage
@export var effects = ["fire","ice"] #Bullet's effects

@export var direction = Vector2() # bullet direction of travel

@export var bulletBounce = false

var speed = 128 #The speed of the bullet

var bounceCount = 0
var maxBounceCount = 2

func _physics_process(delta):
	position += speed * direction * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	call_deferred("queue_free")

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player" and bulletBounce == true:
		var angle: int = int(rad_to_deg(body.get_angle_to(direction)))
		if angle == 135:
			if $CollisionShape2D/Left.is_colliding():
				direction = Vector2(-direction.x, direction.y)
			elif $CollisionShape2D/Down.is_colliding():
				direction = Vector2(direction.x, -direction.y)
		elif angle == -135:
			if $CollisionShape2D/Left.is_colliding():
				direction = Vector2(-direction.x, direction.y)
			elif $CollisionShape2D/Up.is_colliding():
				direction = Vector2(direction.x, -direction.y)
		elif angle == 45:
			if $CollisionShape2D/Right.is_colliding():
				direction = Vector2(-direction.x, direction.y)
			elif $CollisionShape2D/Down.is_colliding():
				direction = Vector2(direction.x, -direction.y)
		elif angle == -45:
			if $CollisionShape2D/Right.is_colliding():
				direction = Vector2(-direction.x, direction.y)
			elif $CollisionShape2D/Up.is_colliding():
				direction = Vector2(direction.x, -direction.y)
		elif abs(angle) == 90 or angle == 180 or angle == 0:
			var dirConversions = {0: Vector2(-1, 0), 180: Vector2(1, 0), -90: Vector2(0,1), 90: Vector2(0,-1)}
			direction = dirConversions[angle]
		if maxBounceCount < bounceCount:
			call_deferred("queue_free")
		await get_tree().create_timer(0.05).timeout
		
