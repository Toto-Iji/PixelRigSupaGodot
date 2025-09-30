extends Button

# This signal is emitted when this specific button is clicked.
# It sends a reference to itself, so the main menu knows everything about it.
signal selected(button_instance)

# These variables can be set in the Inspector for each instance of the button.
@export var level_id: String = "part_1"
@export var level_name: String = "Part 1"

var is_unlocked: bool = false

@onready var label = $Label
@onready var lock_icon = $LockIcon # Make sure you have this node

func _ready():
	label.text = level_name
	# Connect our own 'pressed' signal to a function in this script.
	self.pressed.connect(_on_pressed)

func lock():
	is_unlocked = false
	lock_icon.show()
	label.hide() # Or make it look disabled

func unlock():
	is_unlocked = true
	lock_icon.hide()
	label.show()

func _on_pressed():
	# When pressed, tell the main menu that *we* were the one selected.
	selected.emit(self)
