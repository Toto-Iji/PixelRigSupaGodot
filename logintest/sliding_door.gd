extends Node2D

@onready var body = $StaticBody2D
@onready var door_anim = $StaticBody2D/AnimatedSprite2D
@onready var door_collider = $StaticBody2D/CollisionShape2D
@onready var area = $Area2D

var door_open = false

func _ready():
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)
	# Start closed, show closed animation
	_set_door_closed()

func _on_area_body_entered(body):
	if body.is_in_group("player"):
		_open_door()

func _on_area_body_exited(body):
	if body.is_in_group("player"):
		_close_door()

func _open_door():
	if door_open:
		return
	door_open = true
	_set_door_open()

func _close_door():
	if not door_open:
		return
	door_open = false
	_set_door_closed()

func _set_door_open():
	door_anim.frame = 1
	door_collider.set_deferred("disabled", true)  # Disable collision safely

func _set_door_closed():
	door_anim.frame = 0
	door_collider.set_deferred("disabled", false)  # Re-enable collision safely
