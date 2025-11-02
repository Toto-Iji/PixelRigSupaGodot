# computer_panel.gd
extends Control

@onready var level_list_vbox = $LeftSideBar/MarginContainer/VBoxContainer
@onready var play_button = $CenterDisplay/MarginContainer/PC_Image/PlayButtonHBox/PlayButton
@onready var left_sidebar = $LeftSideBar/MarginContainer/VBoxContainer

# --- Preloads ---
var LevelButtonScene = preload("res://scenes/main_menu/level_button.tscn")

# --- State Variables ---
var _current_selected_level: Dictionary = {}
var _current_selected_button = null
var _levels_data: Array = []

func _ready():
	# Set max height to show 4 levels
	var button_height = 190
	var size_multiplier = 4
	left_sidebar.custom_minimum_size.y = button_height * size_multiplier
	
	play_button.pressed.connect(_on_play_button_pressed)
	play_button.disabled = true

func setup_levels(levels_data: Array):
	_levels_data = levels_data
	
	# Clear existing buttons
	for child in level_list_vbox.get_children():
		child.queue_free()
	
	# Create button for each level
	for level in levels_data:
		var button = LevelButtonScene.instantiate()
		level_list_vbox.add_child(button)
		
		# Configure button
		button.setup(level)
		button.selected.connect(_on_level_selected.bind(level, button))
		button.deselected.connect(_on_level_deselected.bind(button))

func _on_level_selected(level_data: Dictionary, button):
	# Deselect previous button if different
	if _current_selected_button and _current_selected_button != button:
		_current_selected_button.set_selected(false)
	
	# Select new button
	_current_selected_button = button
	button.set_selected(true)
	
	_current_selected_level = level_data
	play_button.disabled = false

func _on_level_deselected(button):
	button.set_selected(false)
	_current_selected_button = null
	_current_selected_level = {}
	play_button.disabled = true

func _on_play_button_pressed():
	if _current_selected_level.is_empty():
		return
		
	if _current_selected_level.is_unlocked:
		var scene_path = _current_selected_level.scene_path
		
		if not scene_path.is_empty():
			# Start transition
			var transition = preload("res://scenes/transition_scene.tscn").instantiate()
			get_tree().root.add_child(transition)
			transition.start_transition(scene_path)
		else:
			push_error("LevelSelect: No scene path for level: %s" % _current_selected_level.id)
