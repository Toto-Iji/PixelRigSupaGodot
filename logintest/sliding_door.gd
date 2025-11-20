extends Node2D

@onready var body = $StaticBody2D
@onready var door_anim = $StaticBody2D/AnimatedSprite2D
@onready var door_collider = $StaticBody2D/CollisionShape2D
@onready var area = $Area2D

# 🔒 New variable to keep it locked initially
var is_locked: bool = true 
var door_open = false

func _ready():
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)
	_set_door_closed()

func _on_area_body_entered(body):
	# Check if locked first!
	if is_locked:
		return 
		
	if body.is_in_group("player"):
		_open_door()

func _on_area_body_exited(body):
	if body.is_in_group("player"):
		_close_door()

# 🔓 New function called by the NPC
func unlock_door():
	print("Door unlocked!")
	is_locked = false
	
	# Check if the player is ALREADY standing in the zone waiting
	if area.has_overlapping_bodies():
		for body in area.get_overlapping_bodies():
			if body.is_in_group("player"):
				_open_door()

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
	door_collider.set_deferred("disabled", true)

func _set_door_closed():
	door_anim.frame = 0
	door_collider.set_deferred("disabled", false)
