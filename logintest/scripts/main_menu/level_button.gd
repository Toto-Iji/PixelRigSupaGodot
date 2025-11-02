extends Button

signal selected
signal deselected

@onready var level_name_label = $MarginContainer/HBoxContainer/VBoxContainer/LevelName
@onready var level_theme_label = $MarginContainer/HBoxContainer/VBoxContainer/LevelTheme

var level_data: Dictionary = {}
var _is_selected = false

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

func set_selected(is_selected: bool):
	_is_selected = is_selected
	if is_selected and not disabled:
		modulate = Color(1.3, 1.3, 1.0, 1.0)  # Highlighted
	elif not disabled:
		modulate = Color(1, 1, 1, 1)  # Normal

func _on_pressed():
	if _is_selected:
		deselected.emit()
	else:
		selected.emit()
