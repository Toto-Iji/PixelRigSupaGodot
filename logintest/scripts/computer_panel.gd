extends Control

@onready var level_list_vbox = $LeftSideBar/MarginContainer/VBoxContainer
@onready var play_button = $CenterDisplay/MarginContainer/PC_Image/PlayButtonHBox/PlayButton
@onready var left_sidebar = $LeftSideBar/MarginContainer/VBoxContainer

# --- Preloads ---
var LevelButtonScene = preload("res://scenes/level_button.tscn")
# Preload the Transition Scene
var TransitionScene = preload("res://scenes/transition_scene.tscn") 

# (Other state variables and setup functions remain the same)
var _current_selected_level: Dictionary = {}
var _levels_data: Array = []

func _ready():
	# ... (rest of _ready() is unchanged) ...
	var button_height = 190 
	var size_multiplier = 4
	left_sidebar.custom_minimum_size.y = button_height * size_multiplier
	
	play_button.pressed.connect(_on_play_button_pressed)
	play_button.disabled = true

func setup_levels(levels_data: Array):
	# (rest of setup_levels() is unchanged) ...
	DebugLog.logv(["Setting up", levels_data.size(), "levels"])
	
	_levels_data = levels_data
	
	# Clear existing buttons (if any)
	for child in level_list_vbox.get_children():
		child.queue_free()
	
	# Create button for each level
	for level in levels_data:
		var button = LevelButtonScene.instantiate()
		level_list_vbox.add_child(button)
		
		# Configure button
		button.setup(level)
		button.selected.connect(_on_level_selected.bind(level))

func _on_level_selected(level_data: Dictionary):
	DebugLog.logv(["Selected level:", level_data.id])
	_current_selected_level = level_data
	play_button.disabled = not level_data.is_unlocked

func _on_play_button_pressed():
	if _current_selected_level.is_empty():
		DebugLog.logv(["No level selected"])
		return
		
	if _current_selected_level.is_unlocked:
		var scene_path = _current_selected_level.scene_path
		
		if not scene_path.is_empty():
			DebugLog.logv(["Starting transition to level:", scene_path])
			
			# Instantiate the Transition Scene
			var transition_instance = TransitionScene.instantiate()
			# Add the transition scene to the root of the tree (it should be on a CanvasLayer)
			get_tree().root.add_child(transition_instance)
			
			# Call the new start method on the transition scene
			transition_instance.start_transition(scene_path)
			
		else:
			DebugLog.logv(["Error: No scene path for level:", _current_selected_level.id])
	else:
		DebugLog.logv(["Cannot play: Level is locked"])
