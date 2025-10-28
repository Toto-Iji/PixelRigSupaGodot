extends PanelContainer

signal clicked

@onready var status_icon = $HBoxContainer/StatusIcon
@onready var component_name_label = $HBoxContainer/VBoxContainer/ComponentName
@onready var component_category_label = $HBoxContainer/VBoxContainer/ComponentCategory
@onready var action_icon = $HBoxContainer/ActionIcon

var component_data: Dictionary = {}

func _ready():
	gui_input.connect(_on_gui_input)

func setup(data: Dictionary):
	component_data = data
	
	component_name_label.text = data.name
	component_category_label.text = data.category
	
	# Visual feedback based on status
	if data.installed:
		# Already installed
		modulate = Color(0.7, 1.0, 0.7)  # Green tint
		status_icon.modulate = Color.GREEN
		action_icon.modulate = Color.GREEN
		component_category_label.text += " ✅ Installed"
	elif data.collected:
		# Collected, ready to install
		modulate = Color(1, 1, 1)
		status_icon.modulate = Color.YELLOW
		action_icon.modulate = Color.YELLOW
		component_category_label.text += " 🎮 Ready to Install"
	else:
		# Not collected yet
		modulate = Color(0.5, 0.5, 0.5)
		status_icon.modulate = Color.GRAY
		action_icon.modulate = Color.GRAY
		component_category_label.text += " 🔒 Locked"

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
