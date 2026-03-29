extends Area2D

@export var direction: Vector2 = Vector2.ZERO

@export var damage: int = 10

var spawnChance: float = 0.33

var speed = 0.5

func _physics_process(delta: float) -> void:
	position += speed * direction * delta

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("Player"):
		queue_free()
		pass # Make a way for player to take damage


func _on_bullet_time_timeout() -> void:
	if randf() < spawnChance:
		var temp = load("res://enemies/tumbleweed/tumbleweed_enemy.tscn").instantiate()
		temp.position = position
		get_parent().add_child(temp)
	queue_free()
