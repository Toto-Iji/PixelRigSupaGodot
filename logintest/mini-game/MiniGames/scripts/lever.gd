#
# --- Updated Lever.gd ---
#
extends Area2D

# Signal to tell the minigame we were clicked
signal lever_clicked

@onready var animated_sprite = $AnimatedSprite2D

var is_locked = true

func _ready():
	# Connect our own input_event signal to ourself
	connect("input_event", _on_input_event)
	
	# Set the starting animation
	set_locked()

# This runs when we are clicked
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Tell the minigame we were clicked
		emit_signal("lever_clicked")

# The main game will call these functions
func set_locked():
	is_locked = true
	# Tell the AnimatedSprite2D to play the "lock" animation
	animated_sprite.play("lock")

func set_unlocked():
	is_locked = false
	# Tell the AnimatedSprite2D to play the "unlock" animation
	animated_sprite.play("unlock")
