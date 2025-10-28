extends CanvasLayer # Assuming your transition scene uses a CanvasLayer

@onready var animation_player = $AnimationPlayer # Ensure this path is correct

var _target_scene_path = "" 

func start_transition(target_scene_path: String):
	"""
	Starts the transition process.
	1. Stores the target path.
	2. Plays the fade_to_black animation.
	"""
	_target_scene_path = target_scene_path
	
	# Start the first animation (fades to full black)
	animation_player.play("fade_to_black")
	
	# Connect to the signal that tells us when this animation is done
	animation_player.animation_finished.connect(_on_fade_to_black_finished)
	
func _on_fade_to_black_finished(anim_name: String):
	"""
	Called when 'fade_to_black' finishes.
	The screen is now fully covered, so it's safe to change the scene.
	"""
	if anim_name == "fade_to_black":
		# IMPORTANT: Disconnect the signal to avoid errors when changing scene
		animation_player.animation_finished.disconnect(_on_fade_to_black_finished)
		
		if not _target_scene_path.is_empty():
			DebugLog.logv(["Fade complete. Changing scene to:", _target_scene_path])
			
			# --- SCENE CHANGE HAPPENS HERE! ---
			var error = get_tree().change_scene_to_file(_target_scene_path)
			if error != OK:
				DebugLog.logv(["ERROR changing scene:", error])
				# Optional: Handle error or just quit transition
				queue_free()
				return
			
			# After the scene changes, the transition scene INSTANCE will persist 
			# into the new scene (because it's on the root). 
			# We now need to fade back in.
			
			# Connect the signal for the second animation
			animation_player.animation_finished.connect(_on_fade_to_normal_finished)
			
			# Start the second animation (fades back to normal/transparent)
			animation_player.play("fade_to_normal")

func _on_fade_to_normal_finished(anim_name: String):
	"""
	Called when 'fade_to_normal' finishes.
	The transition is complete, and the scene is revealed.
	"""
	if anim_name == "fade_to_normal":
		DebugLog.logv(["Transition finished. Removing transition scene."])
		# Remove the transition scene from the tree, as its job is done
		queue_free()
