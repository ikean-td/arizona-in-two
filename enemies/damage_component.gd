extends Node
@export var health: float = 100.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _accept_bullet_(bullet: Node):
	var damage = bullet.damage #exported damage
	var effects = bullet.effects #exported effects (string array)

func _take_damage(damage: float):
	health = health - damage #take damage
	if(health <= 0):
		_die()
	var parent = get_parent() # call parent _damaged_sequence()
	parent._damaged_sequence()

func _die():
	pass
	var parent = get_parent() # call parent _suicide() method
	parent.suicide()
