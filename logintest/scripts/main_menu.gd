extends Control

# --- Node References ---
# These paths are derived directly from your screenshot.
# Use the drag-and-drop method to verify them if you get a 'null instance' error.
@onready var welcome_label = $MarginContainer/mainLayoutBox/WelcomeLabel
@onready var input_field = $MarginContainer/mainLayoutBox/middleRowBox/UserInputField
@onready var save_button = $MarginContainer/mainLayoutBox/ButtonCenterContainer/SaveInputButton
@onready var display_label = $MarginContainer/mainLayoutBox/middleRowBox/DisplayLabel

# Preload the popup scene file. Think of this as loading the blueprint.
var CreateUsernamePopupScene = preload("res://scenes/create_username_popup.tscn")

var _user: Dictionary


func _ready():
	_user = Supabase.get_current_user()

	if _user.is_empty():
		get_tree().change_scene_to_file("res://scenes/login.tscn")
		return

	# The core logic: check if a username is needed.
	if not (_user.has("username") and _user.username != null and not _user.username.is_empty()):
		# User is new, so we create the popup from our blueprint.
		print("Main Menu: New user detected. Instantiating username popup.")
		
		# 1. Create an actual instance of the popup scene.
		var popup_instance = CreateUsernamePopupScene.instantiate()
		
		# 2. Add it to our main menu scene.
		add_child(popup_instance)
		
		# 3. Connect to its 'username_confirmed' signal. This is the crucial communication step.
		popup_instance.username_confirmed.connect(_on_username_confirmed)
		
		# 4. Show the popup.
		popup_instance.popup_centered()
	else:
		# User already has a username, set up the main menu immediately.
		setup_main_menu()


func setup_main_menu():
	var display_name = _user.get("username", _user.get("email", "Player"))
	var quote = _user.get("favorite_quote", "")

	welcome_label.text = "Welcome, " + display_name + "!"
	display_label.text = "Your saved input:\n" + (quote if quote else "(none yet)")

# --- Signal Callbacks ---

# This function is called when the popup instance emits its 'username_confirmed' signal.
func _on_username_confirmed(new_username):
	print("Username Status: Received username '%s' from popup. Saving..." % new_username)
	
	# We can disable the whole main menu here if we want to show a saving indicator.
	# For now, we just ask the controller to save the data.
	var profile_update = { "username": new_username }
	Supabase.update_profile(profile_update, Callable(self, "_on_username_saved").bind(new_username))

# Response from the controller after trying to save the username.
func _on_username_saved(_data, code, new_username):
	if code == 200 or code == 204:
		print("Username Status: Username saved successfully!")
		
		# Manually update our local _user object for immediate use.
		_user.username = new_username
		
		# Now that the profile is complete, set up the main menu view for the first time.
		setup_main_menu()
	else:
		print("Username Status: Failed to save username.")
		# Here you might want to re-show the popup with an error message.

# --- Signal Callbacks ---

# Called when the user clicks the "Save Input" button.
func _on_save_input_button_pressed():
	var user_text = input_field.text.strip_edges()
	if user_text.is_empty():
		print("Save Status: Input is empty.")
		return
	
	# Disable the button to prevent the user from clicking it multiple times.
	save_button.disabled = true
	
	var profile_update = { "favorite_quote": user_text }
	
	# Ask the controller to save the data to Supabase.
	Supabase.update_profile(profile_update, Callable(self, "_on_quote_saved"))


# This function handles the response from the Supabase controller.
func _on_quote_saved(data, code):
	# Re-enable the button, whether the save succeeded or failed.
	save_button.disabled = false
	
	if code == 200 or code == 204: # 200 (OK) or 204 (No Content) are success codes for this.
		print("Save Status: Quote saved successfully!")
		# Update the display label and clear the input field for good user experience.
		display_label.text = "Your saved input:\n" + input_field.text
		input_field.text = ""
	else:
		print("Save Status: Failed to save quote.")
		print("Supabase Error: Code ", code, ", Data: ", data)
