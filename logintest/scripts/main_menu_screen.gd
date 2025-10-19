extends Control

# --- Node References ---
@onready var welcome_label = $WelcomeLabel
@onready var content_hbox = $MarginContainer/MainVBox/ContentHBox

# Tab buttons
@onready var computer_button = $MarginContainer/MainVBox/TopNavHBox/ComputerButton
@onready var build_button = $MarginContainer/MainVBox/TopNavHBox/BuildButton
@onready var exercise_button = $MarginContainer/MainVBox/TopNavHBox/ExerciseButton
@onready var archive_button = $MarginContainer/MainVBox/TopNavHBox/ArchiveButton

# --- Panel Preloads ---
var ComputerPanelScene = preload("res://scenes/computer_panel.tscn")
var BuildPanelScene = preload("res://scenes/build_panel.tscn")
var ExercisePanelScene = preload("res://scenes/exercise_panel.tscn")
var ArchivePanelScene = preload("res://scenes/archive_panel.tscn")
var CreateUsernamePopupScene = preload("res://scenes/create_username_popup.tscn")

# --- State Variables ---
var _user: Dictionary
var _current_panel = null

func _ready():
	_user = Supabase.get_current_user()
	if _user.is_empty():
		get_tree().change_scene_to_file("res://scenes/login.tscn")
		return
	
	# Connect tab buttons
	computer_button.pressed.connect(_on_tab_switched.bind("computer"))
	build_button.pressed.connect(_on_tab_switched.bind("build"))
	exercise_button.pressed.connect(_on_tab_switched.bind("exercise"))
	archive_button.pressed.connect(_on_tab_switched.bind("archive"))
	
	if _user.has("username") and _user.username != null and not _user.username.is_empty():
		initialize_game_ui()
	else:
		prompt_for_username()

func initialize_game_ui():
	DebugLog.logv(["Main Menu: Initializing Game UI..."])
	
	var display_name = _user.get("username", _user.get("email", "Player"))
	welcome_label.text = "Welcome, " + display_name + "!"
	
	# Change these function calls:
	if GameData.should_refetch():
		DebugLog.logv(["Level completed, refetching progress..."])
		Supabase.get_player_levels(Callable(self, "_on_player_progress_loaded"))  # CHANGED
	elif not GameData.has_cached_progress():
		DebugLog.logv(["No cached data, fetching for first time..."])
		Supabase.get_player_levels(Callable(self, "_on_player_progress_loaded"))  # CHANGED
	else:
		DebugLog.logv(["Using cached progress data"])
	
	_on_tab_switched("computer")

func _on_tab_switched(tab_name: String):
	DebugLog.logv(["Switching to tab:", tab_name])
	
	# Clear current panel
	if _current_panel:
		_current_panel.queue_free()
		_current_panel = null
	
	# Load new panel based on tab
	match tab_name:
		"computer":
			_current_panel = ComputerPanelScene.instantiate()
			content_hbox.add_child(_current_panel)
			_setup_computer_panel()
		"build":
			_current_panel = BuildPanelScene.instantiate()
			content_hbox.add_child(_current_panel)
		"exercise":
			_current_panel = ExercisePanelScene.instantiate()
			content_hbox.add_child(_current_panel)
		"archive":
			_current_panel = ArchivePanelScene.instantiate()
			content_hbox.add_child(_current_panel)

func _setup_computer_panel():
	# Use cached data if available
	if GameData.has_cached_progress():
		DebugLog.logv(["Using cached progress data"])
		if _current_panel and _current_panel.has_method("setup_levels"):
			_current_panel.setup_levels(GameData.get_cached_progress())
	else:
		DebugLog.logv(["Progress not loaded yet, waiting..."])

func _on_player_progress_loaded(data, code):
	if code != 200: 
		DebugLog.logv(["Error: Could not load player progress."])
		return
	
	DebugLog.logv(["Player progress loaded:", data])
	
	# Cache the data in singleton
	GameData.cache_progress(data)
	
	# Setup levels if computer panel is visible
	if _current_panel and _current_panel.has_method("setup_levels"):
		_current_panel.setup_levels(data)

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
