# DeathPopup.gd
extends Control

signal respawn_requested
signal main_menu_requested

func _ready():
	hide()
	# This node needs to process input even when the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_popup():
	show()
	get_tree().paused = true

# --- KEY CHANGE IS HERE ---
# We ONLY hide the popup. We do NOT unpause the game.
# The world script will handle unpausing.
func hide_popup():
	hide()
	# get_tree().paused = false  <-- REMOVED THIS LINE

func _on_respawn_button_pressed():
	hide_popup()
	respawn_requested.emit()

func _on_main_menu_button_pressed():
	hide_popup()
	main_menu_requested.emit()
