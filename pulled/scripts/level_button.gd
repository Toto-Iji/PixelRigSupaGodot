extends Button

signal selected

@onready var level_name_label = $MarginContainer/HBoxContainer/VBoxContainer/LevelName
@onready var level_theme_label = $MarginContainer/HBoxContainer/VBoxContainer/LevelTheme

var level_data: Dictionary = {}

func setup(data: Dictionary):
	level_data = data
	
	level_name_label.text = data.display_name
	level_theme_label.text = data.theme
	
	if data.is_unlocked:
		unlock()
	else:
		lock()
	
	pressed.connect(_on_pressed)

func lock():
	disabled = true
	modulate = Color(0.5, 0.5, 0.5, 1.0)  # Greyed out

func unlock():
	disabled = false
	modulate = Color(1, 1, 1, 1)

func _on_pressed():
	selected.emit()
