extends PopupPanel

signal username_confirmed(username)

@onready var username_field = $MarginContainer/VBoxContainer/UsernameLineEdit
@onready var confirm_button = $MarginContainer/VBoxContainer/CenterContainer/ConfirmUsernameButton

func _ready():
	# Prevent popup from closing when clicking outside
	set_flag(Window.FLAG_POPUP, false)  # Disable popup behavior
	
	# Or use this alternative:
	# exclusive = false
	# popup_window = false
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	# Make username required - don't allow closing without input
	close_requested.connect(_on_close_requested)

func _on_confirm_pressed():
	var new_username = username_field.text.strip_edges()
	
	if new_username.is_empty():
		print("Username cannot be empty.")
		return
	
	username_confirmed.emit(new_username)
	hide()

func _on_close_requested():
	# Prevent closing if username is empty
	var new_username = username_field.text.strip_edges()
	if new_username.is_empty():
		print("Please enter a username before closing.")
		# Don't allow closing
		return

func _unhandled_input(event):
	# Also prevent ESC key from closing
	if visible and event.is_action_pressed("ui_cancel"):
		var new_username = username_field.text.strip_edges()
		if new_username.is_empty():
			get_viewport().set_input_as_handled()
