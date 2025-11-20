extends CharacterBody2D

@export var speed: float = 250.0

func _physics_process(delta):
	var input_vector = Input.get_vector("Left", "Right", "Up", "Down")
	velocity = input_vector * speed
	move_and_slide()
