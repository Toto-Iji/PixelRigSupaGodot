extends StaticBody2D

@onready var ui_layer = $TerminalUI

# 🔗 Drag the SlidingDoor here (The Terminal unlocks the door now)
@export var linked_door: Node2D 

var is_active: bool = false # NPC turns this true
var is_ui_open: bool = false
var has_unlocked_door: bool = false
var player_ref = null

func _ready():
	if ui_layer:
		ui_layer.visible = false
	
	# Optional: Start dark or "Off" color
	modulate = Color(0.5, 0.5, 0.5) 

# Called by the NPC when dialogue finishes
func activate_terminal():
	print("🔌 Terminal is now ONLINE")
	is_active = true
	modulate = Color(1, 1, 1) # Light up to show it's active

# Called by Player.gd
func interact():
	if not is_active:
		print("🚫 Terminal is Offline. Talk to the NPC first.")
		# Optional: Add a tiny popup saying "System Offline"
		return

	if is_ui_open:
		return

	_open_ui()

func _open_ui():
	print("🖥️ Opening Mission Interface")
	is_ui_open = true
	if ui_layer:
		ui_layer.visible = true
	
	# Freeze Player
	player_ref = get_tree().get_first_node_in_group("player")
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("Player")
		
	if player_ref:
		player_ref.can_move = false
		player_ref.can_shoot = false
		player_ref.velocity = Vector2.ZERO

func _close_ui():
	print("❌ Closing Mission Interface")
	is_ui_open = false
	if ui_layer:
		ui_layer.visible = false
	
	# Unfreeze Player
	if player_ref:
		player_ref.can_move = true
		player_ref.can_shoot = true
	
	# UNLOCK THE DOOR (Only do this once)
	if not has_unlocked_door:
		_unlock_door_sequence()

func _unlock_door_sequence():
	has_unlocked_door = true
	if linked_door and linked_door.has_method("unlock_door"):
		print("🔓 Terminal unlocking door...")
		linked_door.unlock_door()
		
		# Check if player is standing at the door
		if linked_door.has_method("_on_area_body_entered") and player_ref:
			var door_area = linked_door.get_node_or_null("Area2D")
			if door_area and door_area.overlaps_body(player_ref):
				linked_door._open_door()
	else:
		print("⚠️ Terminal not connected to door!")

func _input(event):
	if is_ui_open:
		# Close on Interact or Escape/Enter
		if event.is_action_pressed("Interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_close_ui()
