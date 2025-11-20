# minimap.gd (Script attached to the top-level 'minimap' node)

extends Node2D  # or Control, depending on your setup

# Variable to hold a reference to the main Player node
var target_player = null

func _ready():
	# Find the Player node in the scene tree.
	# Since the Player is a sibling to the minimap node, 
	# and the parent is 'World', this should work.
	target_player = get_parent().get_node("Player") 
	
	if target_player:
		print("Minimap successfully referenced the main Player.")
	else:
		# Handle case where Player isn't found
		print("ERROR: Could not find the Player node for the minimap.")


func _process(delta):
	if target_player:
		# Move the minimap's Camera2D (or the minimap itself) to follow the player
		# Assuming the minimap has a Camera2D named 'Camera2D' as a child
		var minimap_camera = $Camera2D 
		
		# Center the camera on the player's position
		minimap_camera.global_position = target_player.global_position
		
		# NOTE: You'll also need code to position the minimap_ui elements relative 
		# to the player's global position.
