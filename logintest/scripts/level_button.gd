extends Button


signal selected(button_instance)


@export var level_id: String = "part_1"
@export var level_name: String = "Part 1"

var is_unlocked: bool = false

@onready var label = $Label
@onready var lock_icon = $LockIcon

func _ready():
	label.text = level_name
	self.pressed.connect(_on_pressed)

func lock():
	is_unlocked = false
	lock_icon.show()
	label.hide()

func unlock():
	is_unlocked = true
	lock_icon.hide()
	label.show()

func _on_pressed():
	selected.emit(self)
