extends Control

# --- Node References ---
@onready var welcome_label = $WelcomeLabel
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

	play_button.pressed.connect(_on_play_button_pressed)
	for button in level_list_vbox.get_children():
		if button is Button and button.has_signal("selected"):
			button.selected.connect(_on_level_selected)

	if _user.has("username") and _user.username != null and not _user.username.is_empty():
		initialize_game_ui()
	else:
		prompt_for_username()

func initialize_game_ui():
	DebugLog.logv(["Main Menu: Initializing Game UI..."])
	play_button.disabled = true
	
	var display_name = _user.get("username", _user.get("email", "Player"))
	welcome_label.text = "Welcome, " + display_name + "!"
	
	if _user.has("id"):
		Supabase.get_player_progress(str(_user["id"]), Callable(self, "_on_player_progress_loaded"))
	else:
		DebugLog.logv(["Error: No user ID found, cannot fetch player progress."])

func prompt_for_username():
	DebugLog.logv(["Main Menu: New user detected. Instantiating username popup."])
	var popup_instance = CreateUsernamePopupScene.instantiate()
	add_child(popup_instance)
	popup_instance.username_confirmed.connect(_on_username_confirmed)
	popup_instance.popup_centered()

func _on_username_confirmed(new_username):
	DebugLog.logv(["Username Status: Received username '%s' from popup. Saving..." % new_username])
	var profile_update = { "username": new_username }
	Supabase.update_profile(profile_update, Callable(self, "_on_username_saved").bind(new_username))

func _on_username_saved(_data, code, new_username):
	if code == 200 or code == 204:
		DebugLog.logv(["Username Status: Username saved successfully!"])
		_user.username = new_username
		initialize_game_ui()
	else:
		DebugLog.logv(["Username Status: Failed to save username."])

func _on_player_progress_loaded(data, code):
	if code != 200: 
		DebugLog.logv(["Error: Could not load player progress."])
		return
	
	DebugLog.logv(["Data from Supabase:", data])

	var unlocked_status = {}
	for level_data in data:
		unlocked_status[level_data.level_id] = level_data.is_unlocked

	for button in level_list_vbox.get_children():
		if button.has_method("unlock"):
			DebugLog.logv(["Checking Button with ID:", button.level_id])
			var is_unlocked = unlocked_status.get(button.level_id, false)
			if is_unlocked:
				button.unlock()
			else:
				button.lock()

func _on_level_selected(button_instance):
	DebugLog.logv(["Selected level:", button_instance.level_id])
	_current_selected_level = button_instance
	play_button.disabled = not _current_selected_level.is_unlocked

func _on_play_button_pressed():
	if _current_selected_level and _current_selected_level.is_unlocked:
		var scene_path = ""
		match _current_selected_level.level_id:
			"part_1":
				scene_path = "res://scenes/world.tscn"
			"part_2":
				scene_path = "res://levels/part_2_assembly.tscn"
		
		if not scene_path.is_empty():
			DebugLog.logv(["Loading level:", scene_path])
			get_tree().change_scene_to_file(scene_path)
		else:
			DebugLog.logv(["Error: No scene path defined for level:", _current_selected_level.level_id])
	else:
		DebugLog.logv(["Cannot play: No unlocked level selected."])
