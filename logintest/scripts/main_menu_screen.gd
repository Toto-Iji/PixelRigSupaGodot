extends Control

# --- Node References ---
# Double-check these paths with the drag-and-drop method.
@onready var welcome_label = $WelcomeLabel # Assuming this is at a higher level now
@onready var level_list_vbox = $MarginContainer/MainVBox/ContentHBox/LeftSideBar/MarginContainer/LevelListBox
@onready var play_button = $MarginContainer/MainVBox/ContentHBox/CenterDisplay/MarginContainer/PC_Image/PlayButtonHBox/PlayButton

# --- Scene Preload ---
var CreateUsernamePopupScene = preload("res://scenes/create_username_popup.tscn")

# --- State Variables ---
var _user: Dictionary
var _current_selected_level = null


func _ready():
	_user = Supabase.get_current_user()

	if _user.is_empty():
		get_tree().change_scene_to_file("res://scenes/login.tscn")
		return

	# --- Connect Signals ONCE for persistent nodes ---
	# This is the best practice. These connections will only be made once when the scene loads.
	play_button.pressed.connect(_on_play_button_pressed)
	for button in level_list_vbox.get_children():
		if button is Button and button.has_signal("selected"):
			button.selected.connect(_on_level_selected)
	# -----------------------------------------------

	# Decide the initial setup path based on whether the user is new.
	if _user.has("username") and _user.username != null and not _user.username.is_empty():
		# This is an existing user. Initialize the game UI immediately.
		initialize_game_ui()
	else:
		# This is a new user. Start the username creation process.
		prompt_for_username()


# --- Main Setup Functions ---

# This is the single entry point for setting up the entire game UI.
func initialize_game_ui():
	print("Main Menu: Initializing Game UI...")
	play_button.disabled = true # Start with the play button disabled.
	
	# Set the welcome message.
	var display_name = _user.get("username", _user.get("email", "Player"))
	welcome_label.text = "Welcome, " + display_name + "!"
	
	# Fetch the player's level progress from Supabase to update the button visuals.
	Supabase.get_player_progress(Callable(self, "_on_player_progress_loaded"))

# This function handles the creation of the username popup.
func prompt_for_username():
	print("Main Menu: New user detected. Instantiating username popup.")
	var popup_instance = CreateUsernamePopupScene.instantiate()
	add_child(popup_instance)
	popup_instance.username_confirmed.connect(_on_username_confirmed)
	popup_instance.popup_centered()


# --- Signal Callbacks ---

func _on_username_confirmed(new_username):
	print("Username Status: Received username '%s' from popup. Saving..." % new_username)
	var profile_update = { "username": new_username }
	Supabase.update_profile(profile_update, Callable(self, "_on_username_saved").bind(new_username))

func _on_username_saved(_data, code, new_username):
	if code == 200 or code == 204:
		print("Username Status: Username saved successfully!")
		_user.username = new_username
		# The new user flow is complete. Now, initialize the game UI.
		initialize_game_ui()
	else:
		print("Username Status: Failed to save username.")
		# Optionally, re-show the popup with an error message.

func _on_player_progress_loaded(data, code):
	if code != 200: 
		print("Error: Could not load player progress.")
		return
	
	print("Data from Supabase: ", data)

	var unlocked_status = {}
	for level_data in data:
		unlocked_status[level_data.level_id] = level_data.is_unlocked

	# This function now ONLY updates the visuals. It no longer connects signals.
	for button in level_list_vbox.get_children():
		if button.has_method("unlock"):
			print("Checking Button with ID: '", button.level_id, "'")
			var is_unlocked = unlocked_status.get(button.level_id, false)
			if is_unlocked:
				button.unlock()
			else:
				button.lock()

func _on_level_selected(button_instance):
	print("Selected level: ", button_instance.level_id)
	_current_selected_level = button_instance
	play_button.disabled = not _current_selected_level.is_unlocked

func _on_play_button_pressed():
	if _current_selected_level and _current_selected_level.is_unlocked:
		var scene_path = ""
		match _current_selected_level.level_id:
			"part_1":
				scene_path = "res://levels/part_1_assembly.tscn"
			"part_2":
				scene_path = "res://levels/part_2_assembly.tscn"
		
		if not scene_path.is_empty():
			print("Loading level: ", scene_path)
			get_tree().change_scene_to_file(scene_path)
		else:
			print("Error: No scene path defined for level: ", _current_selected_level.level_id)
	else:
		print("Cannot play: No unlocked level selected.")
