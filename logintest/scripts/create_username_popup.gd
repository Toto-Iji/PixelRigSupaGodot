extends PopupPanel

signal username_confirmed(username)

@onready var username_field = $MarginContainer/VBoxContainer/UsernameLineEdit
@onready var confirm_button = $MarginContainer/VBoxContainer/CenterContainer/ConfirmUsernameButton


func _ready():
	# Connect the button's press signal to a function *within this script*.
	confirm_button.pressed.connect(_on_confirm_pressed)


# When the confirm button is pressed...
func _on_confirm_pressed():
	var new_username = username_field.text.strip_edges()
	if new_username.is_empty():
		# Optionally, show an error label here.
		print("Username cannot be empty.")
		return
	
	# Emit the signal, sending the new username along with it.
	username_confirmed.emit(new_username)
	
	# Hide the popup.
	hide()


# This function intercepts the Escape key.
func _unhandled_input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
