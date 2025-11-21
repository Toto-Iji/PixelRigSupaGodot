extends StaticBody2D

@onready var dialogue_ui = $DialogueLayer
@onready var controls_layer = $ControlsLayer

# 🔗 Drag the MISSION TERMINAL here (Not the door!)
@export var linked_terminal: Node2D 

var story_lines: Array[String] = [
	"*You noticed a PC on top of the desk... powering on.*",
	"Welcome back, Professor Ad— wait. You’re... not him.",
	"If you found this device, then he wanted someone like you to discover it.",
	"The system you’ve synced with contains everything about computers.", 
	"If you're ready... check out the TERMINAL to receive your first mission."
]

# Dialogue if you talk to NPC again
var post_activation_lines: Array[String] = [
	"The terminal is active. Access your mission objectives there."
]

var is_terminal_active: bool = false
var player_ref = null
var is_showing_controls: bool = false

func _ready():
	if has_node("DialogueLayer"):
		dialogue_ui.dialogue_finished.connect(_on_dialogue_finished)
	
	if controls_layer:
		controls_layer.visible = false

	if linked_terminal == null:
		print("⚠️ WARNING: NPC 'Linked Terminal' is empty in Inspector!")

func interact():
	if is_showing_controls: return

	player_ref = get_tree().get_first_node_in_group("player")
	if not player_ref: player_ref = get_tree().get_first_node_in_group("Player")
	
	if player_ref:
		player_ref.can_move = false
		player_ref.can_shoot = false
		player_ref.velocity = Vector2.ZERO
	
	# Choose dialogue based on progress
	if is_terminal_active:
		dialogue_ui.start_dialogue(post_activation_lines)
	else:
		dialogue_ui.start_dialogue(story_lines)

func _on_dialogue_finished():
	if not is_terminal_active:
		# First time: Show controls image
		_show_controls_popup()
	else:
		# Just unfreeze
		_unfreeze_player()

func _show_controls_popup():
	is_showing_controls = true
	if controls_layer:
		controls_layer.visible = true

func _close_controls_popup():
	is_showing_controls = false
	if controls_layer:
		controls_layer.visible = false
	
	# ACTIVATE TERMINAL
	if not is_terminal_active:
		is_terminal_active = true
		if linked_terminal and linked_terminal.has_method("activate_terminal"):
			linked_terminal.activate_terminal()
		else:
			print("❌ Error: Linked Terminal is missing or script is wrong.")
	
	_unfreeze_player()

func _unfreeze_player():
	if player_ref:
		player_ref.can_move = true
		player_ref.can_shoot = true

func _input(event):
	if is_showing_controls:
		if event.is_action_pressed("Interact") or event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_close_controls_popup()
