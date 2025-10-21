# pause_menu.gd
extends CanvasLayer

# Define signals for when the buttons are pressed.
# These signals are used by world.gd to execute the correct action.
signal continue_pressed
signal restart_pressed
signal main_menu_pressed

@onready var continue_button = $MenuContainer/ButtonsVBox/ContinueButton
@onready var restart_button = $MenuContainer/ButtonsVBox/RestartButton
@onready var main_menu_button = $MenuContainer/ButtonsVBox/MainMenuButton

func _ready():
	# Connect button signals to local methods
	continue_button.pressed.connect(_on_continue_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)

	# Give the Continue button initial focus for controller/keyboard navigation
	continue_button.grab_focus()

func _on_continue_button_pressed():
	# 🟢 CONTINUE: This is the only button that handles the pause and deletion itself.
	# 1. Unpause the game
	get_tree().paused = false
	# 2. Emit signal (for world.gd cleanup)
	continue_pressed.emit()
	# 3. Remove this menu instance from the scene tree
	queue_free()

func _on_restart_button_pressed():
	# 🔄 RESTART: Signal the parent (world.gd) to handle the scene reload logic
	restart_pressed.emit()
	# The world.gd script handles unpausing and scene changing after this signal.

func _on_main_menu_button_pressed():
	# 🏠 MAIN MENU: Signal the parent (world.gd) to handle the scene change logic
	main_menu_pressed.emit()
	# The world.gd script handles unpausing and scene changing after this signal.

# Optional: Allow the player to unpause by pressing Escape again while the menu is open
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"): # "ui_cancel" is usually mapped to Escape
		_on_continue_button_pressed()
		get_viewport().set_input_as_handled()
