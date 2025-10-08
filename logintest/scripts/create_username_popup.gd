extends PopupPanel

signal username_confirmed(username)

@onready var username_field = $MarginContainer/VBoxContainer/UsernameLineEdit
@onready var confirm_button = $MarginContainer/VBoxContainer/CenterContainer/ConfirmUsernameButton


func _ready():

	confirm_button.pressed.connect(_on_confirm_pressed)



func _on_confirm_pressed():
	var new_username = username_field.text.strip_edges()
	if new_username.is_empty():
		print("Username cannot be empty.")
		return
	username_confirmed.emit(new_username)
	hide()

func _unhandled_input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
