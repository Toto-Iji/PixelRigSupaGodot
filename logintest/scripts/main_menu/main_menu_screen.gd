# main_menu_screen.gd
extends Control

# ============================================================================
# PRELOADS
# ============================================================================
const QUIZ_UI_SCENE = preload("res://scenes/game/quiz_ui.tscn")

var ComputerPanelScene = preload("res://scenes/main_menu/computer_panel.tscn")
var BuildPanelScene = preload("res://scenes/main_menu/build_panel.tscn")
var ExercisePanelScene = preload("res://scenes/main_menu/exercise_panel.tscn")
var ArchivePanelScene = preload("res://scenes/main_menu/archive_panel.tscn")
var CreateUsernamePopupScene = preload("res://scenes/main_menu/create_username_popup.tscn")

# ============================================================================
# NODE REFERENCES
# ============================================================================
@onready var welcome_label = $WelcomeLabel
@onready var content_hbox = $MarginContainer/MainVBox/ContentHBox

# Tab buttons
@onready var computer_button = $MarginContainer/MainVBox/TopNavHBox/ComputerButton
@onready var build_button = $MarginContainer/MainVBox/TopNavHBox/BuildButton
@onready var exercise_button = $MarginContainer/MainVBox/TopNavHBox/ExerciseButton
@onready var archive_button = $MarginContainer/MainVBox/TopNavHBox/ArchiveButton

# ============================================================================
# STATE VARIABLES
# ============================================================================
var _user: Dictionary
var _current_panel = null
var _quiz_ui_instance = null

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready():
	_user = Supabase.get_current_user()
	if _user.is_empty():
		get_tree().change_scene_to_file("res://scenes/login.tscn")
		return
	
	# Setup quiz UI for exercise panel
	_setup_quiz_ui()
	
	# Connect tab buttons
	computer_button.pressed.connect(_on_tab_switched.bind("computer"))
	build_button.pressed.connect(_on_tab_switched.bind("build"))
	exercise_button.pressed.connect(_on_tab_switched.bind("exercise"))
	archive_button.pressed.connect(_on_tab_switched.bind("archive"))
	
	if _user.has("username") and _user.username != null and not _user.username.is_empty():
		initialize_game_ui()
	else:
		prompt_for_username()

func _setup_quiz_ui():
	_quiz_ui_instance = QUIZ_UI_SCENE.instantiate()
	_quiz_ui_instance.name = "QuizUI"
	get_tree().root.add_child(_quiz_ui_instance)
	print("✅ QuizUI added to scene tree")

func initialize_game_ui():
	var display_name = _user.get("username", _user.get("email", "Player"))
	welcome_label.text = "Welcome, " + display_name + "!"
	
	if GameData.should_refetch():
		Supabase.get_player_levels(Callable(self, "_on_player_progress_loaded"))
	elif not GameData.has_cached_progress():
		Supabase.get_player_levels(Callable(self, "_on_player_progress_loaded"))
	
	_on_tab_switched("computer")

# ============================================================================
# TAB SWITCHING
# ============================================================================
func _on_tab_switched(tab_name: String):
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
	if GameData.has_cached_progress():
		if _current_panel and _current_panel.has_method("setup_levels"):
			_current_panel.setup_levels(GameData.get_cached_progress())

# ============================================================================
# DATA LOADING CALLBACKS
# ============================================================================
func _on_player_progress_loaded(data, code):
	if code != 200: 
		push_error("MainMenu: Could not load player progress. Code: %d" % code)
		return
	
	GameData.cache_progress(data)
	
	if _current_panel and _current_panel.has_method("setup_levels"):
		_current_panel.setup_levels(data)

# ============================================================================
# USERNAME SETUP
# ============================================================================
func prompt_for_username():
	var popup_instance = CreateUsernamePopupScene.instantiate()
	add_child(popup_instance)
	popup_instance.username_confirmed.connect(_on_username_confirmed)
	popup_instance.popup_centered()

func _on_username_confirmed(new_username):
	var profile_update = { "username": new_username }
	Supabase.update_profile(profile_update, Callable(self, "_on_username_saved").bind(new_username))

func _on_username_saved(_data, code, new_username):
	if code == 200 or code == 204:
		_user.username = new_username
		initialize_game_ui()
	else:
		push_error("MainMenu: Failed to save username. Code: %d" % code)
