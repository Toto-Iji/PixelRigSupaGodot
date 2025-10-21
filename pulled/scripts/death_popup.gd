# DeathPopup.gd
extends Control

signal respawn_requested
signal main_menu_requested

func _ready():
	hide()
	# Pause the game when popup appears
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_popup():
	show()
	get_tree().paused = true

func hide_popup():
	hide()
	get_tree().paused = false

func _on_respawn_button_pressed():
	hide_popup()

	# Add transition effect (same as restart logic in world.gd)
	var transition = preload("res://scenes/transition_scene.tscn").instantiate()
	get_tree().root.add_child(transition)

	# Restart the current level smoothly
	var current_scene_path = get_tree().current_scene.scene_file_path
	transition.start_transition(current_scene_path)


func _on_main_menu_button_pressed():
	hide_popup()

	# Add transition to main menu
	var transition = preload("res://scenes/transition_scene.tscn").instantiate()
	get_tree().root.add_child(transition)
	transition.start_transition("res://scenes/main_menu_screen.tscn")
