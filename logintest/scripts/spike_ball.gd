extends AnimatableBody2D

@export var fullswing = false

func _ready():
	if fullswing: $AnimationPlayer.play("fullswing")
