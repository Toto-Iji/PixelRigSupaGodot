extends SubViewport
 
@onready var camera = $PlayerCamera
 
func _physics_process(_delta):
	camera.position = owner.find_child("Player").position 
